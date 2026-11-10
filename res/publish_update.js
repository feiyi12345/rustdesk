#!/usr/bin/env node
// Publishes a signed client update to this fork's update feed.
//
//   node res/publish_update.js keygen
//   node res/publish_update.js publish --version 1.5.2 --exe <setup.exe> --msi <installer.msi> [--dry-run]
//
// Bump `version` in Cargo.toml before building: clients only install a version
// higher than the one compiled into them. Uses only Node built-ins plus the
// ssh/scp on PATH. The private key must stay out of the repository.

'use strict';

const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const FEED_BASE = 'https://193-134-210-76.sslip.io:8443/updates/wuxian';
const SSH_HOST = 'root@193.134.210.76';
const SSH_PORT = '10303';
const REMOTE_DIR = '/opt/proxyguard-license/data/updates/wuxian';
const KEY_ID = 'wuxian-2026-ed25519';
// Must match UPDATE_METADATA_SIGNATURE_CONTEXT in src/update_metadata.rs.
const SIGNATURE_CONTEXT = 'RustDesk update metadata v1\n';
const DEFAULT_KEY = path.join(os.homedir(), '.wuxian-update', 'update_ed25519.pem');

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) fail(`unexpected argument: ${argv[i]}`);
    const name = argv[i].slice(2);
    if (name === 'dry-run') args.dryRun = true;
    else if (i + 1 < argv.length) args[name] = argv[++i];
    else fail(`missing value for --${name}`);
  }
  return args;
}

function rawPublicKey(publicKey) {
  // An Ed25519 SPKI DER ends with the 32 raw key bytes.
  return publicKey.export({ type: 'spki', format: 'der' }).subarray(-32);
}

function keygen(keyPath) {
  if (fs.existsSync(keyPath)) fail(`refusing to overwrite existing key: ${keyPath}`);
  fs.mkdirSync(path.dirname(keyPath), { recursive: true });
  const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
  fs.writeFileSync(keyPath, privateKey.export({ type: 'pkcs8', format: 'pem' }), { mode: 0o600 });
  console.log(`private key written to ${keyPath} (back it up; never commit it)`);
  console.log(`public_key for src/update_metadata.rs: [${[...rawPublicKey(publicKey)].join(', ')}]`);
}

function sha256File(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function artifact(version, format, fileName, source) {
  if (!fs.existsSync(source)) fail(`file not found: ${source}`);
  return {
    source,
    entry: {
      platform: 'windows',
      arch: 'x86_64',
      format,
      url: `${FEED_BASE}/${version}/${fileName}`,
      file_name: fileName,
      size: fs.statSync(source).size,
      sha256: sha256File(source),
    },
  };
}

function run(command, args) {
  execFileSync(command, args, { stdio: 'inherit' });
}

function publish(args) {
  const version = args.version;
  if (!/^\d+\.\d+\.\d+$/.test(version || '')) fail('--version must look like 1.5.2');
  if (!args.exe || !args.msi) fail('--exe and --msi are required');
  const keyPath = args.key || DEFAULT_KEY;
  if (!fs.existsSync(keyPath)) fail(`signing key not found: ${keyPath}`);

  const privateKey = crypto.createPrivateKey(fs.readFileSync(keyPath));
  const artifacts = [
    artifact(version, 'exe', `WuxianRemote-${version}-x64-setup.exe`, args.exe),
    artifact(version, 'msi', `WuxianRemote-${version}-x64.msi`, args.msi),
  ];
  const metadata = Buffer.from(JSON.stringify({
    schema_version: 1,
    app: 'rustdesk',
    package_id: 'rustdesk',
    version,
    release_id: version,
    published_at: new Date().toISOString(),
    signature_key_id: KEY_ID,
    artifacts: artifacts.map((a) => a.entry),
  }, null, 2));
  const signedBytes = Buffer.concat([Buffer.from(SIGNATURE_CONTEXT), metadata]);
  const signature = crypto.sign(null, signedBytes, privateKey);
  if (!crypto.verify(null, signedBytes, crypto.createPublicKey(privateKey), signature)) {
    fail('signature self-check failed');
  }

  const staging = fs.mkdtempSync(path.join(os.tmpdir(), 'wuxian-update-'));
  try {
    const metadataFile = path.join(staging, 'rustdesk-update.json');
    const signatureFile = `${metadataFile}.sig`;
    const latestFile = path.join(staging, 'latest.json');
    fs.writeFileSync(metadataFile, metadata);
    fs.writeFileSync(signatureFile, JSON.stringify({
      schema_version: 1,
      algorithm: 'ed25519',
      key_id: KEY_ID,
      signature: signature.toString('base64'),
    }));
    fs.writeFileSync(latestFile, JSON.stringify({ url: `${FEED_BASE}/${version}` }));

    console.log(metadata.toString());
    if (args.dryRun) {
      console.log('dry run: signature ok, nothing uploaded');
      return;
    }

    const remote = `${REMOTE_DIR}/${version}`;
    const scp = (from, to) => run('scp', ['-P', SSH_PORT, from, `${SSH_HOST}:${to}`]);
    run('ssh', ['-p', SSH_PORT, SSH_HOST, `mkdir -p '${remote}'`]);
    for (const a of artifacts) scp(a.source, `${remote}/${a.entry.file_name}`);
    scp(metadataFile, `${remote}/rustdesk-update.json`);
    scp(signatureFile, `${remote}/rustdesk-update.json.sig`);
    // latest.json goes last and atomically, so clients never see a partial release.
    scp(latestFile, `${REMOTE_DIR}/.latest.json.tmp`);
    run('ssh', ['-p', SSH_PORT, SSH_HOST, `mv '${REMOTE_DIR}/.latest.json.tmp' '${REMOTE_DIR}/latest.json'`]);
    console.log(`published ${version}: ${FEED_BASE}/latest.json`);
  } finally {
    fs.rmSync(staging, { recursive: true, force: true });
  }
}

const [command, ...rest] = process.argv.slice(2);
const args = parseArgs(rest);
if (command === 'keygen') keygen(args.key || DEFAULT_KEY);
else if (command === 'publish') publish(args);
else fail('usage: publish_update.js keygen | publish --version X.Y.Z --exe FILE --msi FILE [--dry-run]');
