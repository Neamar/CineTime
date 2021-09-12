import 'dart:collection';
import 'dart:convert';

import 'package:cinetime/models/_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _FavoriteTheatersKey = "favoriteTheaters";

  static late SharedPreferences _storage;

  static Future<void> init() async
    => _storage = await SharedPreferences.getInstance();

  static Future<void> saveFavoriteTheaters(Iterable<Theater> theaters) async
    => await _storage.setString(_FavoriteTheatersKey, json.encode(theaters.map((theater) => theater.toJson()).toList(growable: false)));

  static Iterable<Theater> readFavoriteTheaters() {
    //Read json
    final theatersString = _storage.getString(_FavoriteTheatersKey);
    if (theatersString?.isNotEmpty != true)
      return [];

    //Decode json
    List<dynamic> usersJson = json.decode(theatersString!);

    //Convert to Theater
    return usersJson.map((json) => Theater.fromJson(json));
  }

  static DateTime? dateFromString(String? dateString)
    => DateTime.tryParse(dateString ?? '')?.toLocal();

  static String? dateToString(DateTime? date)
    => date?.toUtc().toIso8601String();
}

class FavoriteTheatersHandler {
  static FavoriteTheatersHandler? instance;
  static void init() => instance = FavoriteTheatersHandler();

  final Set<Theater> _theaters;
  UnmodifiableListView<Theater> get theaters => UnmodifiableListView(_theaters);

  FavoriteTheatersHandler() : _theaters = StorageService.readFavoriteTheaters().toSet();

  bool isFavorite(Theater theater) => _theaters.contains(theater);

  Future<void> add(Theater theater) async {
    _theaters.add(theater);
    await StorageService.saveFavoriteTheaters(_theaters);
  }

  Future<void> remove(Theater theater) async {
    _theaters.remove(theater);
    await StorageService.saveFavoriteTheaters(_theaters);
  }
}