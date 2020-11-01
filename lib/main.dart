import 'package:cinetime/pages/_pages.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'services/storage_service.dart';

void main() async {
  // Init Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Init shared pref
  await StorageService.init();
  FavoriteTheatersHandler.init();

  // Init local
  initializeDateFormatting(AppResources.locale);
  timeAgo.setLocaleMessages('en', timeAgo.FrMessages());      //Set default timeAgo local to fr. Would probably be much cleaner to use flutter_localizations package (to set default local to fr), but it's not needed :  https://stackoverflow.com/questions/57813559/what-is-the-point-of-globalmateriallocalizations-and-flutter-localizations

  // Start App
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéTime',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: FavoriteTheatersHandler.instance.theaters.isEmpty
        ? TheatersPage()
        : MoviesPage(),
    );
  }
}
