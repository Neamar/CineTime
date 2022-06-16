import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';

class NoResultMessage extends StatelessWidget {
  const NoResultMessage({Key? key,
    required this.icon,
    required this.message,
    required this.backgroundColor,
    required this.imageAssetPath,
  }) : super(key: key);

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: AppResources.colorLightGrey,
                  size: 50,
                ),
                AppResources.spacerLarge,
                for(int i = 0; i < lines.length; i++)
                  Text(
                    lines[i],
                    textAlign: TextAlign.center,
                    style: (i.isOdd ? textTheme.headline5 : textTheme.headline6)?.copyWith(color: AppResources.colorLightGrey),
                  ),
              ],
            ),
          ),

          // Image
          Image.asset(imageAssetPath),
        ],
      ),
    );
  }
}
