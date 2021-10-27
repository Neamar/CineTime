import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'resources/app_theme.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // Init Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Disable logging in release mode
  if (kReleaseMode) {
    debugPrint = (message, {wrapWidth}) {};
  }

  // Get android version info
  try {
    App.androidSdkVersion = (await DeviceInfoPlugin().androidInfo).version.sdkInt ?? App.androidSdkVersion;
  } catch(e) {
    // Ignore
  }

  // Init intl package
  Intl.defaultLocale = App.defaultLocale.toString();
  initializeDateFormatting(App.defaultLocale.toString());

  // Set default TimeAgo package locale
  timeAgo.setLocaleMessages('en', timeAgo.FrShortMessages()); // Set default timeAgo local to fr

  // Init shared pref
  await StorageService.init();

  // Init analytics
  await AnalyticsService.init();

  // Start App inside Sentry's scope
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://f0a7dfef9b5249c7a57c355ac9d30856@o1038499.ingest.sentry.io/6006844';
      options.debug = !kReleaseMode;
      options.environment = kReleaseMode ? 'release' : 'debug';
    },
    appRunner: () => runApp(App()),
  );
}

class App extends StatelessWidget {
  // Default locale
  static const defaultLocale = Locale('fr');

  /// Global key for the App's main navigator
  static GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// The [BuildContext] of the main navigator.
  /// We may use this on showMessage, showError, openDialog, etc.
  static BuildContext get navigatorContext => _navigatorKey.currentContext!;

  /// Current android API version
  static int androidSdkVersion = 0;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéTime',
      theme: appTheme(),
      navigatorKey: _navigatorKey,
      home: AppService.instance.selectedTheaters.isEmpty
        ? TheaterSearchPage()
        : MoviesPage(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Set system status & navigation bars colors.
          // Using [AnnotatedRegion] is better than calling [SystemChrome.setSystemUIOverlayStyle] because it allows some pages to override colors and automatically restore default theme when page is disposed.
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },
    );
  }
}
