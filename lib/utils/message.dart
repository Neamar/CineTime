import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:cinetime/utils/_utils.dart';

// Store last controller to be able to dismiss it
FlashController? _messageController;

/// Display a message to the user, like a SnackBar
Future<void> showMessage(BuildContext context, String message, {bool isError = false, String? details, int? durationInSeconds, Color? backgroundColor}) async {
  // Try to get higher level context, so the Flash message's position is relative to the phone screen (and not a child widget)
  final scaffoldContext = Scaffold.maybeOf(context)?.context;
  if (scaffoldContext != null) context = scaffoldContext;

  // Dismiss previous message
  _messageController?.dismiss();

  // Display new message
  backgroundColor ??= (isError ? Colors.orange : Colors.white);
  await showFlash(
    context: context,
    duration: Duration(seconds: durationInSeconds ?? (details == null ? 4 : 8)),
    builder: (context, controller) {
      _messageController = controller;

      return FlashBar(
        controller: controller,
        position: FlashPosition.top,
        behavior: FlashBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 2,
        primaryAction: details == null ? null : TextButton(
          child: const Text(
            'Détails',
          ),
          onPressed: () {
            controller.dismiss();
            showDialog(
              context: context,     // context and NOT parent context must be used, otherwise it may throw error
              builder: (context) => AlertDialog(
                title: SelectableText(message),
                content: SelectableText(details),
              ),
            );
          },
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(color: backgroundColor?.foregroundTextColor),
        ),
      );
    },
  );

  _messageController = null;
}
