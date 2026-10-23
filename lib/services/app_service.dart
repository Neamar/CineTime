import 'dart:ui';

import 'package:cinetime/main.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:value_stream/value_stream.dart';

import 'api_client_be.dart';
import 'api_client_fr.dart';

class AppService {
  //#region Init
  static final AppService instance = AppService();

  Country _country = StorageService.readCountry() ?? _initCountry();
  Country get country => _country;

  /// Country to use when none has been saved yet, saved right away so it doesn't change on next launch.
  /// Existing data means an update from v2 (France only, country wasn't saved): keep France, so this data stays valid.
  /// Otherwise (fresh install), based on device locale.
  static Country _initCountry() {
    final country = StorageService.hasProviderData || PlatformDispatcher.instance.locale.countryCode != 'BE' ? Country.france : Country.belgium;
    StorageService.saveCountry(country);    // No need to await
    return country;
  }

  static ApiClient _apiClientFor(Country country) => switch (country) {
    Country.france => FranceApiClient(),
    Country.belgium => BelgiumApiClient(),
  };

  late ApiClient apiClient = _apiClientFor(_country);
  static ApiClient get api => instance.apiClient;

  /// Mockable [DateTime.now()]
  static DateTime get now => false ? DateTime(2021, 9, 13, 11, 55) : DateTime.now();
  //#endregion

  //#region Country
  /// Whether there is local data (selected/favorite theaters, hidden movies) that would be lost by switching country.
  bool get hasLocalData => selectedTheaters.value.isNotEmpty || favoriteTheaters.value.isNotEmpty || hiddenMoviesIds.value.isNotEmpty;

  /// Switch to another country's API provider.
  /// Wipes all local storage, since it's tied to the previous provider's data (theater/movie ids, etc).
  void switchCountry(Country country) async {
    if (country == _country) return;

    // Clear in-memory state
    selectedTheaters.add(UnmodifiableSetView(const {}));
    favoriteTheaters.add(UnmodifiableSetView(const {}));
    hiddenMoviesIds.add(UnmodifiableSetView(const {}));

    // Swap provider
    _country = country;
    apiClient = _apiClientFor(country);

    // Update local storage
    () async {
      await StorageService.clear();
      await StorageService.saveCountry(country);
    } ();
  }
  //#endregion

  //#region Selected theaters

  // Selected/favorite theaters and hidden movies all follow the same pattern:
  // - In-memory state is a stream, updated synchronously: the UI can rely on it right away, and listen to it.
  // - Every change is persisted by a listener, in emission order: callers don't need to await anything.
  // - UnmodifiableSetView ensures that every change uses a new Set instance, so the UI is properly refreshed.

  static const _maxSelected = 5;
  late final selectedTheaters = DataStream<UnmodifiableSetView<Theater>>(UnmodifiableSetView(StorageService.readSelectedTheaters().toSet()))
    ..listen(StorageService.saveSelectedTheaters);    // Must be "late" to ensure proper class instanciation flow

  bool isSelected(Theater theater) => selectedTheaters.value.contains(theater);

  bool selectTheater(Theater theater, {bool clearFirst = false}) {
    if (!clearFirst && selectedTheaters.value.length >= _maxSelected) {
      showMessage(App.navigatorContext, 'Maximum $_maxSelected cinémas 😢', isError: true); // Do not await
      return false;
    }

    selectedTheaters.add(UnmodifiableSetView(clearFirst ? {theater} : {...selectedTheaters.value, theater}));
    return true;
  }

  bool unselectTheater(Theater theater) {
    if (selectedTheaters.value.length <= 1) {
      showMessage(App.navigatorContext, 'Minium 1 cinéma', isError: true); // Do not await
      return false;
    }

    selectedTheaters.add(UnmodifiableSetView({...selectedTheaters.value}..remove(theater)));
    return true;
  }
  //#endregion

  //#region Favorite theaters
  late final favoriteTheaters = DataStream<UnmodifiableSetView<Theater>>(UnmodifiableSetView(StorageService.readFavoriteTheaters().toSet()))
    ..listen(StorageService.saveFavoriteTheaters);    // Must be "late" to ensure proper class instanciation flow

  bool isFavorite(Theater theater) => favoriteTheaters.value.contains(theater);

  void addToFavorites(Theater theater) {
    favoriteTheaters.add(UnmodifiableSetView({...favoriteTheaters.value, theater}));
    AnalyticsService.trackEvent('Theater favorited', {
      'theaterId': theater.id.id,
      'favoriteCount': favoriteTheaters.value.length,
    });   // Do not await
  }

  void removeFromFavorites(Theater theater) => favoriteTheaters.add(UnmodifiableSetView({...favoriteTheaters.value}..remove(theater)));
  //#endregion

  //#region Hidden movies
  final hiddenMoviesIds = DataStream<UnmodifiableSetView<String>>(UnmodifiableSetView(StorageService.readHiddenMoviesIds().toSet()))
    ..listen(StorageService.saveHiddenMoviesIds);

  bool isMovieHidden(Movie movie) => hiddenMoviesIds.value.contains(movie.id.id);

  void hideMovie(Movie movie) => hiddenMoviesIds.add(UnmodifiableSetView({...hiddenMoviesIds.value, movie.id.id}));
  void unHideMovie(Movie movie) => hiddenMoviesIds.add(UnmodifiableSetView({...hiddenMoviesIds.value}..remove(movie.id.id)));
  //#endregion
}
