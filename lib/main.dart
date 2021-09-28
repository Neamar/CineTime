import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Init intl package
  Intl.defaultLocale = App.defaultLocale.toString();
  initializeDateFormatting(App.defaultLocale.toString());

  // Set default TimeAgo package locale
  timeAgo.setLocaleMessages('en', timeAgo.FrShortMessages()); // Set default timeAgo local to fr

  // Init shared pref
  await StorageService.init();

  // TEMP to be removed once https://github.com/ja2375/add_2_calendar/issues/83 is closed
  DeviceInfoPlugin().androidInfo.then((info) => App.androidSdkVersion = info.version.sdkInt);

  // Start App inside Sentry's scope
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://bdfc16e5af644dcdb5dd9c684e584334@o1004143.ingest.sentry.io/5965118';
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

  /// TEMP to be removed once https://github.com/ja2375/add_2_calendar/issues/83 is closed
  static int? androidSdkVersion;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéTime',
      theme: appTheme(),
      navigatorKey: _navigatorKey,
      home: AppService.instance.selectedTheaters.isEmpty
        ? TheatersPage()
        : MoviesPage(),
    );
  }
}
