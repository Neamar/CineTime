import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';

import 'icon_message.dart';

class EmptySearchResultMessage extends StatelessWidget {
  static const noResult = EmptySearchResultMessage(
    icon: IconMessage.iconSad,
    message: 'Aucun\nRÉSULTAT',
    backgroundColor: AppResources.colorDarkBlue,
    imageAssetPath: 'assets/empty.png',
  );

  const EmptySearchResultMessage({super.key,
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.imageAssetPath,
  });

  final IconData icon;
  final String message;
  final Color backgroundColor;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lines = message.split('\n');
    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (constraints.maxHeight > 140)...[
                        Icon(
                          icon,
                          color: AppResources.colorLightGrey,
                          size: 50,
                        ),
                        AppResources.spacerLarge,
                      ],
                      for(int i = 0; i < lines.length; i++)
                        Text(
                          lines[i],
                          textAlign: TextAlign.center,
                          style: (i.isOdd ? textTheme.headlineSmall : textTheme.titleLarge)?.copyWith(color: AppResources.colorLightGrey),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Image
          Image.asset(imageAssetPath),
        ],
      ),
    );
  }
}
