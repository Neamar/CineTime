import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';

ThemeData appTheme() {
  final theme = ThemeData(
    primarySwatch: _createMaterialColor(AppResources.colorRed),
    scaffoldBackgroundColor: AppResources.colorGrey,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: AppResources.colorLightRed,
      selectionHandleColor: Colors.white,
    ),
    cardTheme: const CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: AppResources.borderRadiusTiny,
      ),
    ),
  );
  return theme.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: theme.textTheme.bodyText2?.copyWith(color: AppResources.colorDarkRed),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppResources.borderRadiusMedium,
        borderSide: BorderSide(
          color: AppResources.colorDarkRed,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppResources.borderRadiusMedium,
        borderSide: BorderSide(
          color: Colors.white,
        ),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.all(10),
    ),
  );
}

/// Copied from https://medium.com/@filipvk/creating-a-custom-color-swatch-in-flutter-554bcdcb27f3
MaterialColor _createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}