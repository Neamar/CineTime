import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/widgets/update_app_widget.dart';
import 'package:flutter/material.dart';

class CtErrorWidget extends StatelessWidget {
  const CtErrorWidget({required this.error, this.onRetry, this.isDense = false});

  final Object error;
  final bool isDense;

  /// Ignored when [isDense] (no retry in dense mode)
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Flex(
          mainAxisSize: MainAxisSize.min,
          direction: isDense ? Axis.horizontal : Axis.vertical,
          children: [
            // Icon
            Tooltip(
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              message: error.toString().replaceAll('all' + 'ocine', '***').replaceAll('dh' + 'net', '***'),
              child: Icon(
                Icons.error_outline,
                color: AppResources.colorRed,
                size: isDense ? null : 40,
              ),
            ),

            // Caption
            AppResources.spacerTiny,
            const Text('Impossible de récupérer les données'),

            // Retry & update app
            if (!isDense)...[
              TextButton(
                onPressed: onRetry,
                child: const Text('Re-essayer'),
              ),
              AppResources.spacerMedium,
              const UpdateAppWidget(),
            ],
          ],
        ),
      ),
    );
  }
}
