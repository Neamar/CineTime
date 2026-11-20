import 'package:cinetime/resources/_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData appTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppResources.colorDarkBlue,      // Seed tints surfaces: a dark blue gives near-neutral greys (a red seed gives pink)
    brightness: brightness,
    primary: AppResources.colorRed,
    onPrimary: Colors.white,
    primaryContainer: AppResources.colorLightRed,
    onPrimaryContainer: AppResources.colorDarkRed,
    surface: isDark ? Colors.black : null,      // True black on dark mode (OLED)
  );

  final theme = ThemeData(
    colorScheme: scheme,
    typography: Typography.material2014(),      // Denser than the M3 default (material2021): app layouts are tuned for it
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppResources.borderRadiusCard),
      elevation: 0,
      color: scheme.surfaceContainer,
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: AppResources.colorLightRed,
      selectionHandleColor: Colors.white,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),     // Default transition on Android introduce an annoying white flash
      },
    ),
  );
  final inputDecorationIconColor = WidgetStateColor.resolveWith((states) => states.contains(WidgetState.focused) ? Colors.white : AppResources.colorDarkRed);
  return theme.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppResources.colorDarkRed),
      prefixIconColor: inputDecorationIconColor,
      suffixIconColor: inputDecorationIconColor,
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
