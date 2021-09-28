import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/permission_exception.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class TheaterSearchPage extends StatefulWidget {
  const TheaterSearchPage();

  @override
  _TheaterSearchPageState createState() => _TheaterSearchPageState();
}

class _TheaterSearchPageState extends State<TheaterSearchPage> with BlocProvider<TheaterSearchPage, TheaterSearchPageBloc> {
  @override
  initBloc() => TheaterSearchPageBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Nom ou adresse de cinéma',
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: bloc.startQuerySearch,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: bloc.startGeoSearch,
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {},   // TODO
          ),
        ],
      ),
      body: Center(   // Needed for child that are not a ListView
        child: FetchBuilder<_SearchResult>(
          controller: bloc.fetchBuilderController,
          task: bloc.fetchTheaters,
          builder: (context, searchResult) {
            // No data
            if (searchResult.theaters == null)
              return IconMessage(
                icon: FontAwesomeIcons.search,
                message: 'Cherchez un cinéma par nom ou localisation',
              );

            // Empty list
            if (searchResult.theaters!.isEmpty)
              return IconMessage(
                icon: IconMessage.iconSad,
                message: 'Aucun résultat',
              );

            return ListView.builder(
              itemExtent: 100,
              itemCount: searchResult.theaters!.length,
              itemBuilder: (context, index) {
                final theater = searchResult.theaters![index];
                return TheaterCard(
                  key: ObjectKey(theater),
                  theater: theater,
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class TheaterSearchPageBloc with Disposable {
  final fetchBuilderController = FetchBuilderController();

  _SearchParams? _searchParams;

  void startGeoSearch() {
    _searchParams = const _SearchParams(isGeo: true);
    fetchBuilderController.refresh();
  }

  void startQuerySearch(String query) {
    _searchParams = _SearchParams(query: query);
    fetchBuilderController.refresh();
  }

  Future<_SearchResult> fetchTheaters() async {
    // If search hasn't started yet
    if (_searchParams == null) return _SearchResult.none();

    // Search
    final theaters = await (_searchParams!.isGeo ? _geoSearch() : _querySearch(_searchParams!.query!));

    // Return result
    return _SearchResult(theaters);
  }

  Future<List<Theater>> _geoSearch() async {
    // Get geo-position
    geo.Position? position;
    try {
      position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch(e) {
      if (e is geo.PermissionDeniedException || e is geo.LocationServiceDisabledException)
        throw PermissionDeniedException();
      rethrow;
    }

    // Get local theaters
    return await AppService.api.searchTheatersGeo(position.latitude, position.longitude);
  }

  Future<List<Theater>> _querySearch(String query) async {
    if (isStringNullOrEmpty(query)) return [];

    // Get Theater list from server
    return await AppService.api.searchTheaters(query);
  }
}

class _SearchParams {
  const _SearchParams({this.query, this.isGeo = false}) : assert(isGeo && query == null || !isGeo && query != null);

  final String? query;
  final bool isGeo;
}

class _SearchResult {
  const _SearchResult(this.theaters);
  const _SearchResult.none() : theaters = null;

  final List<Theater>? theaters;
}