import 'package:cinetime/main.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:value_stream/value_stream.dart';

import 'api_client.dart';

class AppService {
  //#region Init
  static final AppService instance = AppService();

  final ApiClient apiClient = ApiClient();
  static ApiClient get api => instance.apiClient;

  /// Mockable [DateTime.now()], to be consistent with mocked data
  static DateTime get now => ApiClient.useMocks ? DateTime(2021, 9, 13, 11, 55) : DateTime.now();
  //#endregion

  //#region Selected theaters
  static const _maxSelected = 5;
  final Set<Theater> _selectedTheaters = StorageService.readSelectedTheaters().toSet();
  UnmodifiableSetView<Theater> get selectedTheaters => UnmodifiableSetView(_selectedTheaters);

  bool isSelected(Theater theater) => _selectedTheaters.contains(theater);

  Future<bool> selectTheater(Theater theater, {bool clearFirst = false}) async {
    if (clearFirst) {
      await StorageService.saveSelectedTheaters(_selectedTheaters
        ..clear()
        ..add(theater));
      return true;
    } else {
      if (_selectedTheaters.length >= _maxSelected) {
        showMessage(App.navigatorContext, 'Maximum $_maxSelected cinémas 😢', isError: true); // Do not await
        return false;
      } else {
        await StorageService.saveSelectedTheaters(_selectedTheaters..add(theater));
        return true;
      }
    }
  }

  Future<bool> unselectTheater(Theater theater) async {
    if (_selectedTheaters.length <= 1) {
      showMessage(App.navigatorContext, 'Minium 1 cinéma', isError: true); // Do not await
      return false;
    } else {
      await StorageService.saveSelectedTheaters(_selectedTheaters..remove(theater));
      return true;
    }
  }
  //#endregion

  //#region Favorite theaters
  final Set<Theater> _favoriteTheaters = StorageService.readFavoriteTheaters().toSet();
  UnmodifiableSetView<Theater> get favoriteTheaters => UnmodifiableSetView(_favoriteTheaters);

  bool isFavorite(Theater theater) => _favoriteTheaters.contains(theater);

  Future<void> addToFavorites(Theater theater) async {
    await StorageService.saveFavoriteTheaters(_favoriteTheaters..add(theater));
    AnalyticsService.trackEvent('Theater favorited', {
      'theaterId': theater.id.id,
      'favoriteCount': _favoriteTheaters.length,
    });   // Do not await
  }
  Future<void> removeFromFavorites(Theater theater) => StorageService.saveFavoriteTheaters(_favoriteTheaters..remove(theater));
  //#endregion

  //#region Hidden movies
  /// Stream of hidden movies ids.
  /// We use UnmodifiableSetView to ensure that every change to the set uses a new Set instance, to ensure that the UI is properly refreshed.
  final hiddenMoviesIds = DataStream<UnmodifiableSetView<String>>(UnmodifiableSetView(StorageService.readHiddenMoviesIds().toSet()));

  bool isMovieHidden(Movie movie) => hiddenMoviesIds.value.contains(movie.id.id);

  Future<void> hideMovie(Movie movie) async {
    hiddenMoviesIds.add(UnmodifiableSetView({...hiddenMoviesIds.value, movie.id.id}));
    await StorageService.saveHiddenMoviesIds(hiddenMoviesIds.value);
  }
  Future<void> unHideMovie(Movie movie) async {
    hiddenMoviesIds.add(UnmodifiableSetView({...hiddenMoviesIds.value}..remove(movie.id.id)));
    await StorageService.saveHiddenMoviesIds(hiddenMoviesIds.value);
  }
  //#endregion
}
