import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/permission_exception.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'theaters_page.dart';

class TheaterSearchPage extends StatefulWidget {
  const TheaterSearchPage();

  @override
  _TheaterSearchPageState createState() => _TheaterSearchPageState();
}

class _TheaterSearchPageState extends State<TheaterSearchPage> with BlocProvider<TheaterSearchPage, TheaterSearchPageBloc>, MultiSelectionMode<TheaterSearchPage> {
  @override
  initBloc() => TheaterSearchPageBloc();

  @override
  Widget build(BuildContext context) {
    return ClearFocusBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: TextField(
            decoration: InputDecoration(
              hintText: 'Nom ou adresse',
            ),
            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: bloc.startQuerySearch,
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(CineTimeIcons.location),
              onPressed: bloc.startGeoSearch,
            ),
            if (context.canPop)   // Hide when page is shown at app start
              MultiSelectionModeButton(
                onPressed: toggleSelectionMode,
              ),
          ],
        ),
        body: FetchBuilder<_SearchResult>(
          controller: bloc.fetchBuilderController,
          task: bloc.fetchTheaters,
          builder: (context, searchResult) {
            // No data
            if (searchResult.theaters == null)
              return _NoResultMessage(
                icon: CineTimeIcons.search,
                message: 'Cherchez\nUN CINÉMA\npar nom ou localisation',
                backgroundColor: AppResources.colorDarkRed,
                imageAssetPath: 'assets/welcome.png',
              );

            // Empty list
            if (searchResult.theaters!.isEmpty)
              return _NoResultMessage(
                icon: IconMessage.iconSad,
                message: 'Aucun\nRÉSULTAT',
                backgroundColor: AppResources.colorDarkBlue,
                imageAssetPath: 'assets/empty.png',
              );

            return Scaffold(
              resizeToAvoidBottomInset: true,
              body: ListView.builder(
                itemExtent: TheaterCard.height,
                itemCount: searchResult.theaters!.length,
                itemBuilder: (context, index) {
                  final theater = searchResult.theaters![index];
                  return TheaterCard(
                    key: ObjectKey(theater),
                    theater: theater,
                    multiSelectionMode: multiSelectionMode,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoResultMessage extends StatelessWidget {
  const _NoResultMessage({Key? key,
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
                  color: AppResources.colorGrey,
                  size: 50,
                ),
                AppResources.spacerLarge,
                for(int i = 0; i < lines.length; i++)
                  Text(
                    lines[i],
                    textAlign: TextAlign.center,
                    style: (i.isOdd ? textTheme.headline5 : textTheme.headline6)?.copyWith(color: AppResources.colorGrey),
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