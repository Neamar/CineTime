import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/connectivity_exception.dart';
import 'package:cinetime/utils/exceptions/detailed_exception.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'web_services.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = Iterable<dynamic>;

const _httpMethodGet = 'GET';
const _httpMethodPost = 'POST';

class ApiClient {
  //#region Vars
  static const _graphUrl = 'https://graph.allocine.fr/v1/mobile/';

  static const _timeOutDuration = Duration(seconds: 30);
  static const contentTypeJson = 'application/json';

  static const _logHeaders = true;

  ApiClient() : _client = http.Client();

  final http.Client _client;
  //#endregion

  //#region Tests
  Future<MoviesShowTimes> getMoviesList(Iterable<Theater> theaters, { bool useCache = true }) async {
    // Build movieShowTimes list
    final moviesShowTimesMap = Map<Movie, MovieShowTimes>();

    // For each theater
    for (final theater in theaters) {
      // Send request
      JsonObject? responseJson;
      if (WebServices.useMocks) {
        const urls = [
          'https://gist.githubusercontent.com/Nico04/68c748a39f00e0180558673789cd5c40/raw/a7a548dd4e96060eaecefea892304b53ff0bacc0/showTimes1.json',
          'https://gist.githubusercontent.com/Nico04/81aa12b3c7078df19cbd32bb9b5b47cf/raw/7f08ed7153f685dd76c41fa0868f28ad28a0d522/showTimes2.json',
          'https://gist.githubusercontent.com/Nico04/d6886737ebe58291cd849bcf8119b73f/raw/60d0a79060c4a5f7f90a1ddc573e7440b43394e6/showTimes3.json',
        ];

        responseJson = await _send<JsonObject>(
          _httpMethodGet,
          urls.elementAt(theaters.toList(growable: false).indexOf(theater) % urls.length),
        );
      } else {
        responseJson = await _sendGraphQL<JsonObject>(
          query: r"query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { theater(id: $id) { __typename id internalId name theaterCircuits { __typename id internalId name } flags { __typename hasBooking } companies { __typename company { __typename id internalId name } activity } } movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { __typename totalCount pageInfo { __typename hasNextPage endCursor } edges { __typename node { __typename showtimes { __typename id internalId startsAt isPreview projection techno diffusionVersion data { __typename ticketing { __typename urls type provider } } } movie { __typename id title languages credits(department: DIRECTION, first: 3) { __typename edges { __typename node { __typename person { __typename id internalId firstName lastName } } } } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename id internalId firstName lastName } voiceActor { __typename id internalId firstName lastName } originalVoiceActor { __typename id internalId firstName lastName } } } } releases(type: [RELEASED], country: $country) { __typename releaseDate { __typename date } } genres runTime videos(externalVideo: false, first: 1) { __typename id internalId } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } editorialReviews { __typename rating } poster { __typename url } } } } } }",
          variables: {
            "id": 'Theater:${theater.code}'.toBase64(),
            "from": "2021-09-11T00:00:00",
            "to": "2021-09-12T00:00:00",
            "hasPreview": false,
            "order": [
              "PREVIEW",
              "REVERSE_RELEASE_DATE",
              "WEEKLY_POPULARITY"
            ],
            "country": "FRANCE"
          },
        );
      }

      // Process response
      responseJson = responseJson!['data']!;

      // Get movie info
      final JsonList moviesShowTimesJson = responseJson!['movieShowtimeList']['edges']!;
      for (JsonObject movieShowTimesJson in moviesShowTimesJson) {
        movieShowTimesJson = movieShowTimesJson['node']!;

        // Build Movie info
        JsonObject movieJson = movieShowTimesJson['movie']!;
        final String movieCode = movieJson['id'];
        var movie = moviesShowTimesMap.keys.firstWhereOrNull((m) => m.code == movieCode);   // rename code to it, and make code a getter that decodes id ?

        if (movie == null) {
          JsonList releasesJson = movieJson['releases'] ?? [];
          JsonList genresJson = movieJson['genres'] ?? [];
          JsonList videosJson = movieJson['videos'] ?? [];
          JsonObject statisticsJson = movieJson['stats'] ?? {};

          String? personsFromJson(JsonList? personsJson) {
            if (personsJson == null) return null;
            return personsJson.map((json) {
              json = json['node'];
              final JsonObject? personJson = json['person'] ?? json['actor'];
              return '${personJson?['firstName']} ${personJson?['lastName']}';
            }).join(', ');
          }

          movie = Movie(
            code: movieCode,
            title: movieJson['title'],
            directors: personsFromJson(movieJson['credits']?['edges']),
            actors: personsFromJson(movieJson['cast']?['edges']),
            releaseDate: dateFromString(releasesJson.firstOrNull?['releaseDate']?['date']),
            duration: movieJson['runtime'],
            genres: genresJson.join(', '),
            certificate: null,    // TODO
            poster: movieJson['poster']?['url'],
            trailerCode: videosJson.firstOrNull?['internalId'],
            pressRating: statisticsJson['pressReview']?['score'],
            userRating: statisticsJson['userRating']?['score'],
          );
        }

        // Build ShowTimes
        final JsonList? showTimesJson = movieShowTimesJson['showtimes'];
        if (isIterableNullOrEmpty(showTimesJson))
          continue;

        const versionMap = {
          'ORIGINAL': ShowVersion.original,
          'DUBBED': ShowVersion.dubbed,
        };
        ShowFormat parseFormat(JsonList? json) {
          if (isIterableNullOrEmpty(json)) return ShowFormat.f2D;
          final flat = json!.join('|');
          if (flat.contains('IMAX'))
            return flat.contains('3D') ? ShowFormat.IMAX_3D : ShowFormat.IMAX;
          if (flat.contains('3D'))
            return ShowFormat.f3D;
          return ShowFormat.f2D;
        }

        final showTimes = showTimesJson!.map((showTimeJson) {
          return ShowTime(
            DateTime.tryParse(showTimeJson['startsAt']),
            //screen: screen,   // TODO
            //seatCount: seatCount,   // TODO
            version: versionMap[showTimeJson['diffusionVersion']],
            format: parseFormat(showTimeJson['projection']),
            tags: [showTimeJson['diffusionVersion']],   // TODO change type
          );
        }).toList();

        // Get or create MovieShowTimes
        final movieShowTimes = moviesShowTimesMap.putIfAbsent(movie, () => MovieShowTimes(movie!));

        // Update or create TheaterShowTimes
        var theaterShowTimes = movieShowTimes.theatersShowTimes.firstWhereOrNull((t) => t.theater == theater);
        if (theaterShowTimes == null) {
          theaterShowTimes = TheaterShowTimes(theater);
          movieShowTimes.theatersShowTimes.add(theaterShowTimes);
        }
        theaterShowTimes.showTimes.addAll(showTimes);
      }
    }

    // Return data
    return MoviesShowTimes(
      fetchedAt: DateTime.now(),  // TODO save this value to shared pref and restore it ?
      fromCache: false,   // TODO remove that field
      moviesShowTimes: moviesShowTimesMap.values.toList(growable: false),
    );
  }
  //#endregion

  //#region Generics
  ///
  Future<T?> _sendGraphQL<T>({required String query, required JsonObject variables}) async {
    // Headers
    const headers = const {
      'ac-auth-token': 'c4O6_g8tU74:APA91bF2NxCVPnWjh28JmIG1MOR46BLg-YqZOyG1dpA9bc1m7SrB99GBBryokSmdYTL11WoW-bUS0pQmu2D2Y_9KwoWZW3x6UH4nl5GOIOpyvefse-E7vwsiKStN3ncSRmjWsdR8rK7b',
      'authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpYXQiOjE1NzE4NDM5NTcsInVzZXJuYW1lIjoiYW5vbnltb3VzIiwiYXBwbGljYXRpb25fbmFtZSI6Im1vYmlsZSIsInV1aWQiOiJmMDg3YTZiZi05YTdlLTQ3YTUtYjc5YS0zMDNiNWEwOWZkOWYiLCJzY29wZSI6bnVsbCwiZXhwIjoxNjg2NzAwNzk5fQ.oRS_jzmvfFAQ47wH0pU3eKKnlCy93FhblrBXxPZx2iwUUINibd70MBkI8C8wmZ-AeRhVCR8kavW8dLIqs5rUfA6piFwdYpt0lsAhTR417ABOxVrZ8dv0FX3qg1JLIzan-kSN4TwUZ3yeTjls0PB3OtSBKzoywGvFAu2jMYG1IZyBjxnkfi1nf1qGXbYsBfEaSjrj-LDV6Jjq_MPyMVvngNYKWzFNyzVAKIpAZ-UzzAQujAKwNQcg2j3Y3wfImydZEOW_wqkOKCyDOw9sWCWE2D-SObbFOSrjqKBywI-Q9GlfsUz-rW7ptea_HzLnjZ9mymXc6yq7KMzbgG4W9CZd8-qvHejCXVN9oM2RJ7Xrq5tDD345NoZ5plfCmhwSYA0DSZLw21n3SL3xl78fMITNQqpjlUWRPV8YqZA1o-UNgwMpOWIoojLWx-XBX33znnWlwSa174peZ1k60BQ3ZdCt9A7kyOukzvjNn3IOIVVgS04bBxl4holc5lzcEZSgjoP6dDIEJKib1v_AAxA34alVqWngeDYhd0wAO-crYW1HEd8ogtCoBjugwSy7526qrh68mSJxY66nr4Cle21z1wLC5lOsex0FbuwvOeFba0ycaI8NJPTUriOdvtHAjhDRSem4HjypGvKs5AzlZ3LAJACCHICNwo3NzYjcxfT4Wo1ur-M',
      'host': 'graph.allocine.fr',
      'user-agent': 'androidapp/0.0.1',
    };

    // Body
    final body = {
      "query": query,
      "variables": variables,
    };

    // Send request
    return await _send(_httpMethodPost, _graphUrl, headers: headers, bodyJson: body);
  }

  /// Send a classic request
  Future<T?> _send<T>(String method, String url, {Map<String, String>? headers, JsonObject? bodyJson, String? stringBody}) async {
    // Create request
    final request = http.Request(method, Uri.parse(url));

    // Set headers
    request.headers.addAll({
      HttpHeaders.acceptHeader: contentTypeJson,
      if (bodyJson != null) HttpHeaders.contentTypeHeader: contentTypeJson,
    });
    if (headers != null)
      request.headers.addAll(headers);

    // Set body
    if (bodyJson != null)
      request.body = json.encode(bodyJson);
    else if (stringBody != null)
      request.body = stringBody;

    // Send request
    return await _sendRequest<T>(request);
  }

  /// Send a generic request
  Future<T?> _sendRequest<T>(http.BaseRequest request) async {
    // Check internet
    await throwIfNoInternet();

    // Log
    _log(request: request);

    // All in one Future to handle timeout
    http.Response? response;
    try {
      await (() async {
        //Send request
        final streamedResponse = await _client.send(request);

        //Wait for the full response
        response = await http.Response.fromStream(streamedResponse);
      }()).timeout(_timeOutDuration);
    } on TimeoutException {
      throw ConnectivityException(ConnectivityExceptionType.timeout);
    }

    // Process response
    return _processResponse<T>(response!);
  }

  static T? _processResponse<T>(http.Response response) {
    // Wrap response in a ResponseHandler to facilitate treatment
    final responseHandler = _ResponseHandler(response);

    // Logging
    _log(responseHandler: responseHandler);

    // Process response - Success
    if (responseHandler.isSuccess) {
      // If body doesn't need to be processed
      if (isTypeUndefined<T>()) {
        return null;
      }

      // If raw string is asked
      else if (T == String) {
        return responseHandler.bodyString as T;
      }

      // Other case : try json
      else {
        return responseHandler.bodyJson<T>();
      }
    }

    // Process response - Error
    else {
      JsonObject? processedResponse;
      if (responseHandler.isBodyJson) {
        processedResponse = responseHandler.bodyJson();
      }

      throw HttpResponseException(response, responseJson: processedResponse);
    }
  }

  /// Log a request or a response
  /// Only provide either one, not both
  static void _log({http.BaseRequest? request, _ResponseHandler? responseHandler}) {
    if (request == null && responseHandler == null) return;
    const includeBody = true;

    // Common properties
    request = request ?? responseHandler!.response.request;
    final method = request?.method;
    final url = request?.url.toString();

    // Type specific
    String typeSymbol = '';
    String statusCode = '';
    String body = '';
    String? headers;

    // It's a response
    if (responseHandler != null) {
      final r = responseHandler.response;
      typeSymbol = '<';
      statusCode = r.statusCode != 200 ? '(${r.statusCode}) ' : '';
      if (includeBody) {
        if (responseHandler.isBodyJson) {
          body = responseHandler.bodyString;
        } else {
          body = '${r.contentLength} bytes';
        }
      }
      if (_logHeaders) {
        headers = r.headers.toString();
      }
    }

    // It's a request
    else if (request != null) {
      typeSymbol = '?';
      if (includeBody) {
        body = request is http.Request ? request.body : '';
      }
      if (_logHeaders) {
        headers = request.headers.toString();
      }
    }

    // Build log string
    debugPrint('WS ($typeSymbol) $statusCode[$method $url] $body');
    if (headers != null) {
      debugPrint('WS (${typeSymbol}H) $headers');
    }
  }

  static Future<void> throwIfNoInternet() async {
    if (!(await isConnectedToInternet())) throw ConnectivityException(ConnectivityExceptionType.noInternet);
  }

  static Future<bool> isConnectedToInternet() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  static bool isHttpSuccessCode (int httpStatusCode) => httpStatusCode >= 200 && httpStatusCode < 300;
  //#endregion
}

class _ResponseHandler {
  _ResponseHandler(this.response) :
    isSuccess = ApiClient.isHttpSuccessCode(response.statusCode),
    isBodyJson = ContentType.parse(response.headers[HttpHeaders.contentTypeHeader] ?? '').mimeType == ApiClient.contentTypeJson;

  final http.Response response;

  final bool isSuccess;
  final bool isBodyJson;

  String? _bodyString;
  String get bodyString => _bodyString ?? (_bodyString = response.body);

  dynamic _bodyJson;
  T? bodyJson<T>() {
    // Decode json
    if (_bodyJson == null && bodyString.isNotEmpty) {
      try {
        _bodyJson = json.decode(bodyString);
      } catch (e) {
        // Error is handled bellow
        debugPrint('ResponseHandler.Error : Could not decode json : $e : $bodyString');
      }
    }

    // cast
    try {
      return _bodyJson as T;
    } catch (e) {
      debugPrint('ResponseHandler.Error : Could not cast : $e');
      return null;
    }
  }
}

class HttpResponseException extends DetailedException {
  HttpResponseException(this.response, { JsonObject? responseJson }) :
    super(
      _buildMessage(response, responseJson),
      details: '[${response.request?.method}] ${response.request?.url}\n${response.body}',
    );

  HttpResponseException.fromRaw(int statusCode, String url, {String? message}) :
    response = http.Response(message ?? '', statusCode),
    super(
      'Erreur $statusCode',
      details: '$url\n$message',
    );

  final http.Response response;
  int get statusCode => response.statusCode;

  bool get shouldBeReported => statusCode != 401;

  static String _buildMessage(http.Response response, JsonObject? responseJson) {
    final errorMessage = responseJson?.elementAt('error');    // May be a String, or a more complex json
    return 'Erreur ${response.statusCode}' + (errorMessage != null && errorMessage is String ? ' : $errorMessage' : '');
  }
}