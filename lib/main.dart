import 'package:cinetime/pages/_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'services/storage_service.dart';

void main() async {
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

  // Start App
  runApp(App());
}

class App extends StatelessWidget {
  // Default locale
  static const defaultLocale = Locale('fr');

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéTime',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: FavoriteTheatersHandler.instance!.theaters.isEmpty
        ? TheatersPage()
        : MoviesPage(),
    );
  }
}
