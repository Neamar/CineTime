import 'dart:convert';
import 'dart:io';

import 'package:cinetime/helpers/tools.dart';
import 'package:cinetime/models/_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';

class WebServices {
  static bool useMocks = !kReleaseMode;
  static DateTime get mockedNow => useMocks ? DateTime(2020, 3, 11, 11, 55) : DateTime.now();

  static const _partnerKey = "100ED" + "1DA33EB";
  static const _secretKey = "1a1ed8c1bed24d60" + "ae3472eed1da33eb";
  static const _baseUrl = "https://api.allocine.fr/rest/v3/";

  static final _signatureDateFormatter = DateFormat("yyyyMMdd");
  static final _cacheManager = CtCacheManager();

  /// Get theaters that match [query] (free text query)
  static Future<List<Theater>> searchTheaters(String query) async {
    // Build params
    final params = {
      'filter': 'theater',
      'q': '$query',
      'count': '25',
    };

    // Send request and return result
    return await _getTheatersList('search', params, "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/cinemas-search.json");
  }

  /// Get theaters around geo-position
  static Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) async {
    // Build params
    final params = {
      'lat': '$latitude',
      'long': '$longitude',
      'radius': '25',
      'count': '25',
    };

    // Send request and return result
    return await _getTheatersList('theaterlist', params, "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/cinemas-gps.json");
  }

  static Future<List<Theater>> _getTheatersList(String method, Map<String, String> params, [String mockUrl]) async {
    // Make request
    var responseJson = await _httpGet(method, params, mockUrl: mockUrl);

    // Process result
    responseJson = responseJson['feed'];
    List<dynamic> theatersJson = responseJson['theater'];

    var theaters = List<Theater>();
    for (Map<String, dynamic> theaterJson in theatersJson) {
      var poster = ((theaterJson['poster'] ?? theaterJson['picture']) as Map<String, dynamic>)?.elementAt('path');   // Return 'poster' with 'search' and 'picture' with 'theaterlist'

      theaters.add(Theater(
        code: theaterJson['code'],
        name: theaterJson['name'],
        street: theaterJson['address'],
        zipCode: theaterJson['postalCode'],
        city: theaterJson['city'],
        poster: poster?.endsWith('jpg') == true ? poster : null,    //It might be non-handled types, like '.pdf'.
        distance: theaterJson['distance'],   // Only with 'theaterlist'
      ));
    }

    return theaters;
  }

  /// Get all movies for specified theaters (with showtimes).
  /// [theatersCode] must be a list of theater codes.
  static Future<TheatersShowTimes> getMoviesList(Iterable<Theater> theaters, { bool useCache = true }) async {
    // Build params
    final theatersCode = theaters.map((t) => t.code);
    final params = {
      'theaters': theatersCode.join(','),
    };

    // Make request
    var responseJson = await _httpGet('showtimelist', params, mockUrl: "https://gist.githubusercontent.com/Nico04/c349103e5baf1316bf8b8afcb2436526/raw/7941b125f5b406f6310579dd326892e8eb6f26f3/movies.json", useCache: useCache);   //"https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/6f2ae30320e9e93807268f3a3772cdd8bba90987/cinema.json"

    // Process response
    responseJson = responseJson['feed'];
    List<dynamic> theatersShowtimesJson = responseJson['theaterShowtimes'];

    // Build movieShowTimes list
    var moviesShowTimesMap = Map<Movie, MovieShowTimes>();
    for (Map<String, dynamic> theaterShowtimesJson in theatersShowtimesJson) {
      // Get theater (should already exist, find by code)
      String theaterCode = theaterShowtimesJson['place']['theater']['code'];
      var theater = theaters.firstWhere((t) => t.code == theaterCode);

      // Get movie info
      List<dynamic> moviesShowTimesJson = theaterShowtimesJson['movieShowtimes'];
      for (Map<String, dynamic> movieShowTimesJson in moviesShowTimesJson) {

        // Build ShowTimes raw
        List<dynamic> showTimesDaysJson = movieShowTimesJson['scr'];
        if (showTimesDaysJson?.isNotEmpty != true)
          continue;

        var showTimesRaw = List<DateTime>();
        for (Map<String, dynamic> showTimesDayJson in showTimesDaysJson) {
          String showDayString = showTimesDayJson['d'];
          List<dynamic> showTimesHoursJson = showTimesDayJson['t'];

          for (Map<String, dynamic> showTimesHourJson in showTimesHoursJson) {
            String showHourString = showTimesHourJson['\$'];

            showTimesRaw.add(DateTime.parse('$showDayString $showHourString'));
          }
        }

        // Build ShowTime info
        Map<String, dynamic> screenFormatJson = movieShowTimesJson['screenFormat'] ?? Map();
        String screenFormatString = screenFormatJson['\$'] ?? '';
        Map<String, dynamic> screenJson = movieShowTimesJson['screen'] ?? Map();

        var showTime = RoomShowTimes(
          screen: screenJson['\$'],
          seatCount: movieShowTimesJson['seatCount'],
          isOriginalLanguage: movieShowTimesJson['version']['original'] == 'true',
          is3D: screenFormatString.contains('3D'),
          isIMAX: screenFormatString.contains('IMAX'),
          showTimesRaw: showTimesRaw..sort(),
        );

        // Build Movie info
        Map<String, dynamic> movieJson = movieShowTimesJson['onShow']['movie'];
        var movieCode = (movieJson['code'] as int).toString();
        var movie = moviesShowTimesMap.keys.firstWhere((m) => m.code == movieCode, orElse: () => null);
        if (movie == null) {
          Map<String, dynamic> castingJson = movieJson['castingShort'] ?? Map();
          Map<String, dynamic> releaseJson = movieJson['release'] ?? Map();
          List<dynamic> genresJson = movieJson['genre'] ?? List();
          Map<String, dynamic> certificateJson = movieJson['movieCertificate'] ?? Map();
          certificateJson = certificateJson['certificate'];
          Map<String, dynamic> posterJson = movieJson['poster'] ?? Map();
          Map<String, dynamic> trailerJson = movieJson['trailer'] ?? Map();
          Map<String, dynamic> statisticsJson = movieJson['statistics'] ?? Map();

          movie = Movie(
            code: movieCode,
            title: movieJson['title'],
            directors: castingJson['directors'],
            actors: castingJson['actors'],
            releaseDate: dateFromString(releaseJson['releaseDate']),
            duration: movieJson['runtime'],
            genres: genresJson.map((genreJson) => genreJson['\$']).join(', '),
            certificate: certificateJson != null
              ? MovieCertificate(
                  code: (certificateJson['code'] as int)?.toString(),
                  description: certificateJson['\$'],
                )
              : null,
            poster: posterJson['path'],
            trailerCode: trailerJson['code']?.toString(),
            pressRating: (statisticsJson['pressRating'] as num)?.toDouble(),
            userRating: (statisticsJson['userRating'] as num)?.toDouble(),
          );
        }

        // Get or create MovieShowTimes
        var movieShowTimes = moviesShowTimesMap.putIfAbsent(movie, () => MovieShowTimes(movie));

        // Update or create TheaterShowTimes
        var theaterShowTimes = movieShowTimes.theatersShowTimes.firstWhere((t) => t.theater == theater, orElse: () => null);
        if (theaterShowTimes == null) {
          theaterShowTimes = TheaterShowTimes(theater);
          movieShowTimes.theatersShowTimes.add(theaterShowTimes);
        }
        theaterShowTimes.roomsShowTimes.add(showTime);
      }
    }

    return TheatersShowTimes(
      fetchedAt: DateTime.now(),  // TODO save this value to shared pref and restore it ?
      fromCache: false,   // TODO remove that field
      moviesShowTimes: moviesShowTimesMap.values,
    );
  }

  /// Get the synopsis of the movie corresponding to [movieCode]
  static Future<String> getSynopsis(String movieCode) async {
    // Build params
    final params = {
      'code': movieCode,
      'profile': 'small',
    };

    // Make request
    var responseJson = await _httpGet('movie', params, useCache: true, mockUrl: "https://gist.githubusercontent.com/Neamar/9713818694c4c37f583c4d5cf4046611/raw/film.json");

    // Process result
    responseJson = responseJson['movie'];

    // Return result
    return removeAllHtmlTags(responseJson['synopsisShort']);
  }

  static Future<String> getTrailerUrl(String trailerCode) async {
    // Build params
    final params = {
      'mediafmt': 'mp4-lc',
      'code': trailerCode,
    };

    // Make request
    var responseJson = await _httpGet('media', params, useCache: true, mockUrl: "https://gist.githubusercontent.com/Nico04/6027f1596d5173e5682bc7b588d9b9f8/raw/9eca1a66bf8164806d965662fc3698f5d5148054/trailer.json");

    // Process result
    return responseJson['media']['rendition'][0]['href'];
  }

  /// Get the full url or an image from [path].
  /// if [isThumbnail] is true, image will be small. Otherwise it will return full size.
  static String getImageUrl(String path, bool isThumbnail) {
    if (path?.isNotEmpty != true) return null;
    return 'https://images.allocine.fr/' + (isThumbnail == true ? 'r_200_200' : '') + path;
  }

  static getMovieUrl(String movieCode) => "http://www.allocine.fr/film/fichefilm_gen_cfilm=$movieCode.html";

  /// Send a http GET request, return decoded response
  static Future<Map<String, dynamic>> _httpGet(String method, Map<String, String> params, { bool useCache, String mockUrl }) async {
    useCache ??= false;

    // Add parameters
    params ??= {};
    params.addAll({
      'sed': _signatureDateFormatter.format(DateTime.now()),
      'partner': _partnerKey,
      'format': 'json',
    });

    // Create the Query string
    var query = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
    final toSign = method + query + _secretKey;

    // Sign query
    final toSignBytes = utf8.encode(toSign);
    final signatureBytes = sha1.convert(toSignBytes).bytes;
    final signatureBase64 = base64.encode(signatureBytes);
    final signature = Uri.encodeQueryComponent(signatureBase64);
    query += '&sig=$signature';

    // Build url
    final url = useMocks
      ? mockUrl
      : _baseUrl + method + '?' + query;

    // Get response from cache or server
    File responseFile;
    if (useCache) {
      responseFile = await _cacheManager.getSingleFile(url);    // TODO because url contains 'sed' that changes every day, cache will just work for one day. Use flutter_cache_manager v2.0 when released and provide a custom key. Then add a mechanism to choose cache duration per request (synopsis can be long, whereas getMoviesList needs to be short).
    } else {
      responseFile = (await _cacheManager.downloadFile(url)).file;
    }

    // Read response from cached file
    final response = await responseFile.readAsString();

    // Process response
    return json.decode(response);
  }
}

class CtCacheManager extends BaseCacheManager {
  static const key = "CtCache";

  static CtCacheManager _instance;

  factory CtCacheManager() {
    if (_instance == null) {
      _instance = new CtCacheManager._();
    }
    return _instance;
  }

  CtCacheManager._() : super(key, maxAgeCacheObject: Duration(days: 7));

  final _defaultCacheManager = DefaultCacheManager();

  @override
  Future<String> getFilePath() async {
    return _defaultCacheManager.getFilePath();
  }

  @override
  Future<FileInfo> getFileFromCache(String url, {bool ignoreMemCache = false}) async {
    print('WS.cache (?) [$url]');
    final fileInfo = await super.getFileFromCache(url, ignoreMemCache: ignoreMemCache);
    print('WS.cache (${fileInfo != null ? '✓' : '☓'}) [$url]');
    return fileInfo;
  }

  @override
  Future<FileInfo> downloadFile(String url, {Map<String, String> authHeaders, bool force = false}) async {
    print('WS.server (?) [$url]');
    final fileInfo = await super.downloadFile(url, authHeaders: authHeaders, force: force);
    print('WS.server (✓) [$url]');
    return fileInfo;
  }
}

class NoInternetException extends ExceptionWithMessage {
  NoInternetException() : super('Verifiez votre connexion internet');
}