import 'dart:convert';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class StorageService {
  //#region Init
  static late SharedPreferencesWithCache _storage;
  static const _migrationCompletedKey = 'migrationCompleted';

  static Future<void> init() async {
    // TEMP One-time import of data stored by the legacy API (different store and "flutter." key prefix)
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: _migrationCompletedKey,
    );
    _storage = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());

    // TEMP One-time conversion of theaters stored in the v3.0.0 format
    await _migrateTheatersStorage();
  }
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
  // Each list is stored as a whole (theaters data included) in a single key, so a change is a single write.
  static const _selectedTheatersKey = 'selectedTheaterList';
  static const _favoriteTheatersKey = 'favoriteTheaterList';
  static const _listSeparator = '|';

  static Future<void> saveSelectedTheaters(Iterable<Theater> theaters) => _saveTheaters(_selectedTheatersKey, theaters);
  static List<Theater> readSelectedTheaters() => _readTheaters(_selectedTheatersKey);

  static Future<void> saveFavoriteTheaters(Iterable<Theater> theaters) => _saveTheaters(_favoriteTheatersKey, theaters);
  static List<Theater> readFavoriteTheaters() => _readTheaters(_favoriteTheatersKey);

  /// Not async on purpose: the write is sent right away, so successive saves are written in call order.
  static Future<void> _saveTheaters(String key, Iterable<Theater> theaters) =>
    _storage.setString(key, json.encode(theaters.map((theater) => theater.toJson()).toList()));

  static List<Theater> _readTheaters(String key) {
    // Read
    final theatersString = _storage.getString(key);
    if (isStringNullOrEmpty(theatersString)) return [];

    // Decode
    final List theatersJson;
    try {
      theatersJson = json.decode(theatersString!);
    } catch(e, s) {
      reportError(e, s);
      return [];
    }

    // Convert to Theater (a corrupted entry is skipped, without losing the others)
    final theaters = <Theater>[];
    for (final theaterJson in theatersJson) {
      try {
        theaters.add(Theater.fromJson(theaterJson));
      } catch(e, s) {
        reportError(e, s);
      }
    }
    return theaters;
  }

  /// TEMP Convert theaters stored in the v3.0.0 format: lists of ids ('|' separated), with each theater data in its own `theater:<id>` key.
  /// Theaters data is kept as raw JSON, because [Theater.fromJson] can't be used before [AppService] is ready.
  static Future<void> _migrateTheatersStorage() async {
    const legacyListKeys = {'selectedTheaters': _selectedTheatersKey, 'favoriteTheaters': _favoriteTheatersKey};
    const legacyTheaterKeyPrefix = 'theater:';

    // Convert lists
    for (final MapEntry(key: legacyKey, value: key) in legacyListKeys.entries) {
      final ids = _storage.getString(legacyKey);
      if (ids == null) continue;

      final theatersJson = <Object?>[];
      for (final id in ids.split(_listSeparator)) {
        final theaterString = _storage.getString('$legacyTheaterKeyPrefix$id');
        if (isStringNullOrEmpty(theaterString)) continue;
        try {
          theatersJson.add(json.decode(theaterString!));
        } catch(e, s) {
          reportError(e, s);
        }
      }
      await _storage.setString(key, json.encode(theatersJson));
    }

    // Remove legacy keys, only once converted (if interrupted before, conversion is simply done again on next launch)
    for (final key in _storage.keys.where((key) => legacyListKeys.containsKey(key) || key.startsWith(legacyTheaterKeyPrefix))) {
      await _storage.remove(key);
    }
  }
  //#endregion

  //#region Hidden movies
  static const _hiddenMoviesIdsKey = 'hiddenMoviesIds';
  static Future<void> saveHiddenMoviesIds(Iterable<String> moviesIds) => _storage.setString(_hiddenMoviesIdsKey, moviesIds.join(_listSeparator));
  static List<String> readHiddenMoviesIds() => _storage.getString(_hiddenMoviesIdsKey)?.split(_listSeparator) ?? [];
  //#endregion

  /// Wipe all local storage. Used when switching country, since selected/favorite theaters and hidden movies are tied to the previous provider's data.
  static Future<void> clear() async {
    await _storage.clear();
    await _storage.setBool(_migrationCompletedKey, true);   // Keep the flag, otherwise the legacy data would be re-imported on next launch
  }
}