import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

/// The keyboard grab sends raw keys, so the local IME never composes text.
/// This box releases the grab and types the committed text on the peer.
void remoteTextInputDialog(FFI ffi) {
  final wasInside = ffi.inputModel.pointerInsideImage;
  ffi.inputModel.enterOrLeave(false);
  final controller = TextEditingController();
  final focusNode = FocusNode();
  ffi.dialogManager.show((setState, close, context) {
    void send() {
      final text = controller.text;
      if (text.isEmpty) return;
      bind.sessionInputString(sessionId: ffi.sessionId, value: text);
      controller.clear();
      focusNode.requestFocus();
    }

    void cancel() {
      close();
      if (wasInside) ffi.inputModel.enterOrLeave(true);
    }

    return CustomAlertDialog(
      title: Text(translate('Type text')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(translate('type-text-tip'),
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            minLines: 1,
            maxLines: 1,
            onSubmitted: (_) => send(),
          ),
        ],
      ),
      actions: [
        dialogButton('Close', onPressed: cancel, isOutline: true),
        dialogButton('Send', onPressed: send),
      ],
      onCancel: cancel,
    );
  });
}
