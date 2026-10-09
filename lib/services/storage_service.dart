import 'dart:convert';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  //#region Init
  static late SharedPreferences _storage;

  static Future<void> init() async => _storage = await SharedPreferences.getInstance();
  //#endregion

  //#region Country
  static const _countryKey = 'country';
  static Future<void> saveCountry(Country country) => _storage.setString(_countryKey, country.name);
  static Country? readCountry() => Country.values.firstWhereOrNull((c) => c.name == _storage.getString(_countryKey));

  /// Whether there is data tied to an API provider (selected/favorite theaters, hidden movies).
  static bool get hasProviderData => [_selectedTheatersKey, _favoriteTheatersKey, _hiddenMoviesIdsKey].any(_storage.containsKey);
  //#endregion

  //#region Sorting
  static const _movieSortingKey = 'movieSorting';
  static Future<void> saveMovieSorting(MovieSortType value) => _storage.setString(_movieSortingKey, value.name);
  static MovieSortType? readMovieSorting() => MovieSortType.values.firstWhereOrNull((e) => e.name == _storage.getString(_movieSortingKey));
  //#endregion

  //#region Theaters
  static const _selectedTheatersKey = 'selectedTheaters';
  static const _favoriteTheatersKey = 'favoriteTheaters';
  static String _theatersKey(String theaterId) => 'theater:$theaterId';
  static const _listSeparator = '|';

  static Future<void> saveSelectedTheaters(Iterable<Theater> theaters) => _saveTheaters(_selectedTheatersKey, theaters);
  static List<Theater> readSelectedTheaters() => _readTheaters(_selectedTheatersKey);

  static Future<void> saveFavoriteTheaters(Iterable<Theater> theaters) => _saveTheaters(_favoriteTheatersKey, theaters);
  static List<Theater> readFavoriteTheaters() => _readTheaters(_favoriteTheatersKey);

  static Future<void> _saveTheaters(String key, Iterable<Theater> theaters) async {
    // Save theater data
    await _saveTheatersData(theaters);

    // Save favorite theaters ids
    await _storage.setString(key, theaters.map((theater) => theater.id.id).join(_listSeparator));
  }

  static List<Theater> _readTheaters(String key) {
    // Read
    final theatersString = _storage.getString(key);
    if (isStringNullOrEmpty(theatersString)) return [];

    // Decode
    final theatersIds = theatersString!.split(_listSeparator);

    // Convert to Theater
    final theaters = <Theater>[];
    for (final id in theatersIds) {
      final theater = _readTheaterData(id);
      theaters.addNotNull(theater);
    }
    return theaters;
  }

  static Future<void> _saveTheatersData(Iterable<Theater> theaters) async {
    for (final theater in theaters) {
      final key = _theatersKey(theater.id.id);
      if (!_storage.containsKey(key)) {
        await _storage.setString(key, json.encode(theater.toJson()));
      }
    }
  }

  static Theater? _readTheaterData(String theaterId) {
    // Read
    final theaterString = _storage.getString(_theatersKey(theaterId));
    if (isStringNullOrEmpty(theaterString)) return null;

    // Decode
    try {
      return Theater.fromJson(json.decode(theaterString!));
    } catch(e, s) {
      reportError(e, s);
      return null;
    }
  }
  //#endregion

  //#region Hidden movies
  static const _hiddenMoviesIdsKey = 'hiddenMoviesIds';
  static Future<void> saveHiddenMoviesIds(Iterable<String> moviesIds) => _storage.setString(_hiddenMoviesIdsKey, moviesIds.join(_listSeparator));
  static List<String> readHiddenMoviesIds() => _storage.getString(_hiddenMoviesIdsKey)?.split(_listSeparator) ?? [];
  //#endregion

  /// Wipe all local storage. Used when switching country, since selected/favorite theaters and hidden movies are tied to the previous provider's data.
  static Future<void> clear() => _storage.clear();
}