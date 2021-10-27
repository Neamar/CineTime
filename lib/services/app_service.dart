import 'dart:collection';

import 'package:cinetime/main.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';

import 'api_client.dart';

class AppService {
  //#region Init
  static final AppService instance = AppService();

  final ApiClient apiClient = ApiClient();
  static ApiClient get api => instance.apiClient;

  AppService()
      : _selectedTheaters = StorageService.readSelectedTheaters().toSet(),
        _favoriteTheaters = StorageService.readFavoriteTheaters().toSet();
  //#endregion

  //#region Selected theaters
  static const _maxSelected = 5;
  final Set<Theater> _selectedTheaters;
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
  final Set<Theater> _favoriteTheaters;
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
}
