import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/widgets/update_app_widget.dart';
import 'package:flutter/material.dart';

class CtErrorWidget extends StatelessWidget {
  const CtErrorWidget({required this.error, this.onRetry, this.isDense = false});

  final Object error;
  final bool isDense;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: isDense ? onRetry : null,
        child: Flex(
          mainAxisSize: MainAxisSize.min,
          direction: isDense ? Axis.horizontal : Axis.vertical,
          children: [
            // Icon
            Tooltip(
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              message: error.toString().replaceAll('all' + 'ocine', '***'),
              child: Icon(
                Icons.error_outline,
                color: AppResources.colorRed,
                size: isDense ? null : 40,
              ),
            ),

            // Caption
            AppResources.spacerTiny,
            const Text('Impossible de récupérer les données'),

            // Retry
            if (isDense)...[
              AppResources.spacerTiny,
              const Icon(Icons.refresh),
            ]
            else
              TextButton(
                onPressed: onRetry,
                child: const Text('Re-essayer'),
              ),

            // Update app
            if (!isDense)...[
              AppResources.spacerMedium,
              const UpdateAppWidget(),
            ],
          ],
        ),
      ),
    );
  }
}
