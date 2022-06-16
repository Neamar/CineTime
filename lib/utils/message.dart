import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:cinetime/utils/_utils.dart';

// Store last controller to be able to dismiss it
FlashController? _messageController;

/// Display a message to the user, like a SnackBar
Future<void> showMessage(BuildContext context, String message, {bool? isError, Object? exception, int durationInSeconds = 4}) async {
  isError ??= exception == null ? false : true;

  //Try to get higher level context, so the Flash message's position is relative to the phone screen (and not a child widget)
  final scaffoldContext = Scaffold.maybeOf(context)?.context;
  if (scaffoldContext != null)
    context = scaffoldContext;

  //Dismiss previous message
  _messageController?.dismiss();

  //Display new message
  await showFlash(
    context: context,
    duration: Duration(seconds: durationInSeconds),
    builder: (context, controller) {
      _messageController = controller;

      return Flash(
        controller: controller,
        backgroundColor: isError! ? Colors.orange : Theme.of(context).canvasColor,
        margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        position: FlashPosition.top,
        behavior: FlashBehavior.floating,
        horizontalDismissDirection: HorizontalDismissDirection.horizontal,
        borderRadius: BorderRadius.circular(8.0),
        boxShadows: kElevationToShadow[8],
        onTap: exception == null ? controller.dismiss : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: FlashBar(
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyText1?.copyWith(color: isError ? Colors.white : null),
            ),
            primaryAction: exception == null
                ? null
                : TextButton(
              child: Text(
                'Détails',
                style: context.textTheme.caption?.copyWith(color: Colors.white),
              ),
              onPressed: () {
                controller.dismiss();
                showDialog(
                  context: context,     // context and NOT parent context must be used, otherwise it may throw error
                  builder: (context) => AlertDialog(
                    title: Text(message),
                    content: Text(exception.toString()),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );

  _messageController = null;
}
