import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:fetcher/fetcher_bloc.dart';

import 'theaters_page.dart';

class TheaterSearchPage extends StatefulWidget {
  const TheaterSearchPage();

  @override
  State<TheaterSearchPage> createState() => _TheaterSearchPageState();
}

class _TheaterSearchPageState extends State<TheaterSearchPage> with BlocProvider<TheaterSearchPage, _TheaterSearchPageBloc>, MultiSelectionMode<TheaterSearchPage> {
  final _searchController = TextEditingController();

  @override
  initBloc() => _TheaterSearchPageBloc();

  Future<void> _switchCountry(Country country) async {
    if (country == AppService.instance.country) return;

    // Warn before deleting local data, if any
    if (AppService.instance.hasLocalData) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Changer de pays'),
          content: const Text('Vos cinémas sélectionnés, favoris et films masqués seront supprimés. Continuer ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Switch API provider
    AppService.instance.switchCountry(country);

    // Refresh UI: rebuild for the toggle's new selected state,
    if (!mounted) return
    setState(() {});

    // and either re-run the current search on the new country or go back to the onboarding message
    final query = _searchController.text;
    if (query.isNotEmpty) {
      bloc.startQuerySearch(query);
    } else {
      bloc.fetchBuilderController.refresh(clearDataFirst: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryToggle = _CountryToggle(
      country: AppService.instance.country,
      onChanged: _switchCountry,
    );

    return ClearFocusBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
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
        body: FetchBuilderWithParameter<_SearchParams, _SearchResult>(
          controller: bloc.fetchBuilderController,
          task: bloc.fetchTheaters,
          builder: (context, searchResult) {
            // No data
            if (searchResult.theaters == null)
              return EmptySearchResultMessage(
                icon: Icons.search,
                message: 'Cherchez\nUN CINÉMA\npar nom ou localisation',
                backgroundColor: AppResources.colorDarkRed,
                imageAssetPath: 'assets/welcome.png',
                footer: countryToggle,
              );

            // Empty list
            if (searchResult.theaters!.isEmpty)
              return EmptySearchResultMessage(
                icon: IconMessage.iconSad,
                message: 'Aucun\nRÉSULTAT',
                backgroundColor: AppResources.colorDarkBlue,
                imageAssetPath: 'assets/empty.png',
                footer: countryToggle,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}


class _TheaterSearchPageBloc with Disposable {
  final fetchBuilderController = FetchBuilderWithParameterController<_SearchParams, _SearchResult>();

  void startGeoSearch() => fetchBuilderController.refresh(param: const _SearchParams(isGeo: true), clearDataFirst: true);

  void startQuerySearch(String query) => fetchBuilderController.refresh(param: _SearchParams(query: query), clearDataFirst: true);

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

/// Toggle button to switch the API provider's country.
class _CountryToggle extends StatelessWidget {
  const _CountryToggle({required this.country, required this.onChanged});

  final Country country;
  final ValueChanged<Country> onChanged;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [country == Country.france, country == Country.belgium],
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
      borderRadius: BorderRadius.circular(5),
      color: AppResources.colorLightGrey,
      selectedColor: Colors.white,
      borderColor: AppResources.colorLightGrey,
      selectedBorderColor: Colors.white,
      fillColor: Colors.white24,
      onPressed: (index) => onChanged(Country.values[index]),
      children: const [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('🇫🇷 FR'),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('🇧🇪 BE'),
        ),
      ],
    );
  }
}

class _SearchResult {
  const _SearchResult(this.theaters);
  const _SearchResult.none() : theaters = null;

  final List<Theater>? theaters;
}