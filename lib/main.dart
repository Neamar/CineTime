import 'package:cinetime/pages/_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'services/storage_service.dart';

Future<void> main() async {
  // Init Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Disable logging in release mode
  if (kReleaseMode) {
    debugPrint = (message, {wrapWidth}) {};
  }

  // Init date formatting
  initializeDateFormatting(App.defaultLocale.toString());

  // Set default TimeAgo package locale
  timeAgo.setLocaleMessages('en', timeAgo.FrShortMessages()); // Set default timeAgo local to fr

  // Init shared pref
  await StorageService.init();
  FavoriteTheatersHandler.init();

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéTime',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      navigatorKey: _navigatorKey,
      home: FavoriteTheatersHandler.instance!.theaters.isEmpty
        ? TheatersPage()
        : MoviesPage(),
    );
  }
}
