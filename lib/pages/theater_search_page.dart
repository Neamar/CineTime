import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';

import 'theaters_page.dart';

class TheaterSearchPage extends StatefulWidget {
  const TheaterSearchPage();

  @override
  State<TheaterSearchPage> createState() => _TheaterSearchPageState();
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
            decoration: const InputDecoration(
              hintText: 'Nom ou adresse',
            ),
            style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: bloc.startQuerySearch,
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              onPressed: bloc.startGeoSearch,
            ),
            if (context.canPop)   // Hide when page is shown at app start
              MultiSelectionModeButton(
                onPressed: toggleSelectionMode,
              ),
          ],
        ),
        body: FetchBuilder<_SearchParams, _SearchResult>.withParam(
          controller: bloc.fetchBuilderController,
          task: bloc.fetchTheaters,
          builder: (context, searchResult) {
            // No data
            if (searchResult.theaters == null)
              return const EmptySearchResultMessage(
                icon: Icons.search,
                message: 'Cherchez\nUN CINÉMA\npar nom ou localisation',
                backgroundColor: AppResources.colorDarkRed,
                imageAssetPath: 'assets/welcome.png',
              );

            // Empty list
            if (searchResult.theaters!.isEmpty)
              return EmptySearchResultMessage.noResult;

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
                    onLongPress: context.canPop ? toggleSelectionMode : null,  // Disable when page is shown at app start
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


class TheaterSearchPageBloc with Disposable {
  final fetchBuilderController = FetchBuilderController<_SearchParams, _SearchResult>();

  void startGeoSearch() => fetchBuilderController.refresh(const _SearchParams(isGeo: true));

  void startQuerySearch(String query) => fetchBuilderController.refresh(_SearchParams(query: query));

  Future<_SearchResult> fetchTheaters(_SearchParams? searchParams) async {
    // If search hasn't started yet
    if (searchParams == null) return const _SearchResult.none();

    // Search
    final theaters = await (searchParams.isGeo ? _geoSearch() : _querySearch(searchParams.query!));

    // Analytics
    if (searchParams.isGeo)
      AnalyticsService.trackEvent('Theater geolocation search', {
        'resultCount': theaters.length,
      });
    else
      AnalyticsService.trackEvent('Theater search', {
        'query': searchParams.query!,
        'resultCount': theaters.length,
      });

    // Return result
    return _SearchResult(theaters);
  }

  Future<List<Theater>> _geoSearch() async {
    // Get geo-position
    final position = await getCurrentLocation();

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