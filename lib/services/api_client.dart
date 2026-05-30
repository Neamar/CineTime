// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/services/api_providers/api_provider.dart';
import 'package:cinetime/services/api_providers/allocine_api_provider.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/data_error.dart';
import 'package:cinetime/utils/exceptions/unauthorized_exception.dart';
import 'package:cinetime/utils/exceptions/connectivity_exception.dart';
import 'package:cinetime/utils/exceptions/http_response_exception.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_service.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = Iterable<dynamic>;

const httpMethodGet = 'GET';
const httpMethodPost = 'POST';

class ApiClient {
  //#region Vars
  /// Whether to use cache or not
  static const useCache = true;

  /// API url
  static const _graphUrl = 'https://graph.all' + 'ocine.fr/v1/mobile/';

  /// Request timeout duration
  static const _timeOutDuration = Duration(seconds: 30);

  /// Json mime type
  static const contentTypeJsonMimeType = 'application/json';
  static const contentTypeJson = '$contentTypeJsonMimeType; charset=utf-8';

  /// Whether to log headers also or not.
  static const _logHeaders = false;

  ApiClient() : _client = SentryHttpClient(
    failedRequestStatusCodes: [
      SentryStatusCode.range(400, 599),   // Report all errors
    ],
  ) {
    _activeProvider = AllocineApiProvider(this);
  }

  final http.Client _client;
  final _cacheManager = CacheManager(Config(
    'CtCache',
    stalePeriod: const Duration(days: 1),
  ));

  late final ApiProvider _activeProvider;

  /// The currently active API provider.
  ApiProvider get activeProvider => _activeProvider;
  //#endregion

  //#region Requests
  /// Get theaters that match [query] (free text query)
  Future<List<Theater>> searchTheaters(String query) => _activeProvider.searchTheaters(query);

  /// Get theaters around geo-position
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) => _activeProvider.searchTheatersGeo(latitude, longitude);

  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters, { bool useCache = useCache }) => _activeProvider.getMoviesList(theaters, useCache: useCache);

  /// Get detailed movie info
  /// Return synopsis and certificate
  Future<MovieInfo> getMovieInfo(ApiId movieId) => _activeProvider.getMovieInfo(movieId);

  Future<Uri?> getVideoUri(ApiId videoId) => _activeProvider.getVideoUri(videoId);
  //#endregion

  //#region Tools
  /// Get the full url or an image from [path].
  /// if [isThumbnail] is true, image will be small. Otherwise it will return full size.
  static String? getImageUrl(String? path, {bool isThumbnail = false}) {
    return AppService.api.activeProvider.getImageUrl(path, isThumbnail: isThumbnail);
  }
  //#endregion

  //#region Other
  /// Get the show end time from ticketing url
  static Future<DateTime?> getShowEndTime(DateTime startAt, Duration? movieDuration, Uri ticketingUri) async {
    // UGC
    if (ticketingUri.host.contains('ugc.fr')) {
      final response = await http.get(ticketingUri);
      throwIfHttpError(response);
      final htmlContent = response.body;

      // Extract raw value
      final regex = RegExp(r'<div class="showing-endtime.*?">.*?(\d{2}:\d{2}).*?</div>', dotAll: true, caseSensitive: false);
      final match = regex.firstMatch(htmlContent);

      // Extract the captured group containing the time
      final endTime = match?.group(1)?.trim();
      if (endTime == null) throw const DataError('Could not find end time in UGC page');

      // Parse the time and build end date
      final timeParts = endTime.split(':');
      var endDate = startAt.copyWith(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      // If the end time is before the start time, it means it's on the next day
      if (endDate.isBefore(startAt)) {
        endDate = endDate.copyWith(day: endDate.day + 1);
      }
      return endDate;
    }

    // Pathé
    else if (ticketingUri.host.contains('pa' + 'the.fr')) {
      // Pathé ticketing page is more complex:
      // - Requires javascript to load
      // - Displayed end time is actually just based on start time, movie duration and ads duration
      // So we just fetch the ads duration (actually independent of the movie) and add it to the start time.

      // Ignore if movieDuration is null
      if (movieDuration == null) return null;

      // First, get a auth token
      final authResponse = await http.post(Uri.parse('https://s.pa' + 'the.fr/oauth/api/jwt/token'), body: json.encode({
        'grant_type': 'client_credentials',
        'client_id': 'API_CLI'
      }));
      throwIfHttpError(authResponse);
      final authToken = json.decode(authResponse.body)['access_token'];
      final headers = {
        'Authorization': 'Bearer $authToken',
      };

      // Then, get the ads duration
      final adsResponse = await http.get(Uri.parse('https://s.pa' + 'the.fr/api/setting/fr-FR/booking/display'), headers: headers);
      throwIfHttpError(adsResponse);
      final adsDuration = json.decode(adsResponse.body)['adsDuration'] as int;

      // Compute total show duration
      final showDuration = movieDuration + Duration(minutes: adsDuration);

      // Return end time
      return startAt.add(showDuration);
    }

    // Ciné Boutique
    if (ticketingUri.host.contains('cine.bo' + 'utique')) {
      // Get API token
      final response = await http.get(ticketingUri);
      throwIfHttpError(response);
      final htmlContent = response.body;

      // Extract API token
      final apiToken = RegExp(r'<meta.+api_token.+content="(.+)">', caseSensitive: false).firstMatch(htmlContent)?.group(1);
      if (apiToken == null) throw const DataError('Could not find APi Token in Ciné Boutique page');

      // Get showtime data
      final showTimeId = ticketingUri.queryParameters['showId'];
      final subDomain = ticketingUri.host.split('.').first;
      final showTimeResponse = await http.get(Uri.parse('https://$subDomain.cineo' + 'ffice.fr/vad/shows/$showTimeId?api_token=$apiToken'));
      throwIfHttpError(showTimeResponse);

      // Extract showtime data
      final showTimeData = json.decode(showTimeResponse.body);
      final endTime = showTimeData['showend'] as String;
      return DateTime.parse(endTime).toLocal();
    }

    return null;
  }
  //#endregion

  //#region Generics
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Return correctly formatted date
  static String dateToString(DateTime date) => '${_dateFormat.format(date)}T00:00:00';

  /// Return the path part of an url
  static String? getPathFromUrl(String? url) => url != null ? Uri.parse(url).path : null;

  /// Build a unique key based on the request, used for cache.
  static String _getCacheKeyFromRequest(http.Request request) {
    // If it's a GraphQL request
    if (request.url.toString() == _graphUrl) {
      return request.body.replaceAllMapped(RegExp(r'.+?query (.+?)\(.+",.+?variables":(.+)', dotAll: true), (match) => '${match.group(1)}${match.group(2)}');
    }

    // If it's a classic request
    else {
      return request.url.toString();
    }
  }

  /// Get an auth token for GraphQL request.
  /// Usually one per device.
  Future<String> _getAuthToken() async {
    // Using hardcoded token works for now, but it may be revoked at any time.
    return 'cjgBOHVXRrKkCYZvUEkkIe:APA91bGs9N8b4emKZXuSSBJkRp_UDzBOHLlGyjIL9ykztjyv4xtL-dP7gO5E05ucMh_LoZ5TCWCI7VjQNR__XOdXo_jiMiHXyRPFd52qtY0Jmfvyv2Ba35Y';    // S4m windIP 9.7.8
  }

  /// Delete all locally saved auth tokens
  Future<void> clearAuthToken() async {
    await StorageService.deleteAuthToken();
  }

  /// Regex to detect invalid token error, so we can clear it and get a new one.
  /// Error message may vary, and case also.
  /// Seen examples :
  /// - {"error":"Invalid token."}
  /// - {"error":"Missing Token"}
  /// - {"error":"InvalidToken"}
  /// - {"error":"MissingToken"}
  /// - {"error":"The registration is not found."}
  static final _tokenErrorRegex = RegExp(r'(((Invalid)|(Missing)) ?Token)|(The registration is not found)', caseSensitive: false);

  /// Send a graphQL request
  /// If [enableAutoRetryOnUnauthorized] is true, it will auto retry if authToken is invalid (after getting a new one)
  Future<T> sendGraphQL<T>({required String query, required JsonObject variables, bool useCache = useCache, bool enableAutoRetryOnUnauthorized = true }) async {
    // Headers
    final headers = {
      'a' + 'c-auth-token': await _getAuthToken(),
      'authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciO' + 'iJSUzI1NiJ9.eyJpYXQiOjE2NzU0NDEwNTksImV4cCI6MTgzMzU4MDc5OSwidXNlcm5hbWUiOiJhbm9ueW1vdXMiLCJhcHBsaWNhdGlvbl9uYW1lIjoibW9iaWxlIiwidX' + 'VpZCI6ImJmMDQ3YjgzLWQ0MzktNGM0My1iYWQ4LTBhNTc3MzFkZGM4OCIsInNjb3BlIjpudWxsfQ.s-_yFAY2wLi0ggRE_GKjuoH4A1lPBaf9iVhbzqUu_ityjVMe4R' + 'UdQHwlXqedQv3cinnLszpwfMPDg78qrQEn2vfoWe6_Af_pj0WRJV3mhrf4EpTnBFy-7NZoXDLNDtobi99XRUJpG-89kreZXzBZbMuuirVyn0XwHgDk8Pnatdh6uLWiQHSxXz9qeXgNT-R1FOS0aNlS604oAvQ_PJa1CC6qmLFtmjOZUhWul' + 'yBSUos1rhrf3BvEHM4G0XME_ocr_79PIOKWP5c4PrW-8hydQRDQmu-OAaMldsRc9Rgy_8UAYSn4n-AqiUAa1Ckdjz3UpVbA75pJJ6HsbiMZBpNb4nVanaPisL0LuyqcMp0I49iIZbOF0szHK0wZMcVmCuU3ZLTHcQsDWhVhMpA2SdMV6-vR-Vgw86nGCJZ89KQ_-mnvBxI6fPPinzhaTsvspfcnoggJLcZjqV_bRzwB6wn4MjCbI1jEkTSng0ebPZSHXqNx6EHriQ7LEAoMKmckYVVuvKGaYkriemY6SWGSeNTDNn9QPnh4BKAIhitRN0Anxs6vE1IQYUBcpFm7GSxjGi2_wzEy6g5iobEn2MR80wIWLP9k932c' + '7mcE69NSD4y5iyFYIwcdxfBvsrVoPWoEWLdSkwXjsGBgtBv3MA6jRTkFUlZH90V' + 'xcIsNz0BEnH6G240',
      'host': 'graph.all' + 'ocine.fr',
    };

    // Body
    final body = {
      'query': query,
      'variables': variables,
    };

    // Send request
    try {
      return await send<T>(httpMethodPost, _graphUrl, headers: headers, bodyJson: body, useCache: useCache);
    } catch(e) {
      // Unauthorized
      if (e is HttpResponseException && e.statusCode == 400 && _tokenErrorRegex.hasMatch(e.body)) {
        // Clear tokens (to get new ones next time)
        await clearAuthToken();

        // If allowed, retry
        if (enableAutoRetryOnUnauthorized) {
          return await sendGraphQL(query: query, variables: variables, useCache: useCache, enableAutoRetryOnUnauthorized: false);
        }

        // If not allowed to retry, juts throw
        else {
          throw UnauthorizedException(e.toString());
        }
      }

      // In all other cases, just rethrow
      rethrow;
    }
  }

  /// Send a classic request
  Future<T> send<T>(String method, String url, {Map<String, String>? headers, JsonObject? bodyJson, String? stringBody, bool useCache = useCache}) async {
    // Create request
    final request = http.Request(method, Uri.parse(url));

    // Set headers
    request.headers.addAll({
      HttpHeaders.acceptHeader: contentTypeJson,
      if (bodyJson != null) HttpHeaders.contentTypeHeader: contentTypeJson,
      'user-agent': 'androidapp/0.0.1',
    });
    if (headers != null)
      request.headers.addAll(headers);

    // Set body
    if (bodyJson != null)
      request.body = json.encode(bodyJson);
    else if (stringBody != null)
      request.body = stringBody;

    // Send request
    return await _sendRequest<T>(request, useCache: useCache);
  }

  /// Send a generic request
  Future<T> _sendRequest<T>(http.Request request, {bool useCache = useCache}) async {
    // Log
    _log(request: request);

    // Prepare cache key
    final cacheKey = _getCacheKeyFromRequest(request);

    // Get response
    final response = await () async {
      // If we can use cache
      if (useCache) {
        // Check cache
        final cachedResponseFile = await _cacheManager.getFileFromCache(cacheKey);

        // If cache is available
        if (cachedResponseFile != null) {
          // Read response from cached file
          final cachedResponse = await cachedResponseFile.file.readAsString();
          useCache = false;

          // Process response
          return http.Response(cachedResponse, 200,
            headers: {HttpHeaders.contentTypeHeader: contentTypeJson}, // Needed so content is decoded using utf-8
            request: http.Request('CACHE', Uri.parse(cachedResponseFile.file.path)),
          );
        }
      }

      // Check internet
      await throwIfNoInternet();

      // All in one Future to handle timeout
      try {
        return await(() async {
          //Send request
          final streamedResponse = await _client.send(request);

          //Wait for the full response
          return await http.Response.fromStream(streamedResponse);
        }()).timeout(_timeOutDuration);
      } on TimeoutException {
        throw const ConnectivityException(ConnectivityExceptionType.timeout);
      }
    } ();

    // Process response
    return _processResponse<T>(response, useCache ? cacheKey : null);
  }

  /// Process server's [response].
  /// Returns processed result as Json or String.
  /// Cache body if [cacheKey] is provided.
  T _processResponse<T>(http.Response response, String? cacheKey) {
    // Wrap response in a ResponseHandler to facilitate treatment
    final responseHandler = _ResponseHandler(response);

    // Logging
    _log(responseHandler: responseHandler);

    // Process response - Success
    if (responseHandler.isSuccess) {
      // Check for errors
      // A GraphQL request may return a 200 HTTP status code with errors
      if (responseHandler.isBodyJson) {
        final processedResponse = responseHandler.bodyJsonOrNull<JsonObject>();
        final errors = processedResponse?['errors'];
        if (errors != null) {
          throw HttpResponseException(response);
        }
      }

      // Store in cache
      if (cacheKey != null) {
        try {
          _cacheManager.putFile(cacheKey, response.bodyBytes);
          debugPrint('API (˅) [CACHED $cacheKey]');
        } catch (e, s) {
          reportError(e, s);
        }
      }

      // If raw string is asked
      if (T == String) {
        return responseHandler.bodyString as T;
      }

      // Json
      else if (T == JsonObject || T == JsonList) {
        return responseHandler.bodyJson<T>();
      }

      // If body doesn't need to be processed
      else if (isTypeUndefined<T>()) {
        return null as T;
      }

      // Unhandled types
      else {
        throw UnimplementedError('$T is not a supported type');
      }
    }

    // Process response - Error
    else {
      throw HttpResponseException(response);
    }
  }

  /// Log a request or a response
  /// Only provide either one, not both
  static void _log({http.BaseRequest? request, _ResponseHandler? responseHandler}) {
    if (kReleaseMode || request == null && responseHandler == null) return;
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
          body = responseHandler.bodyString.removeAllNewLines();
        } else {
          final sizeInKo = ((r.contentLength ?? 0) / 1024).round();
          if (sizeInKo <= 10) {
            body = responseHandler.bodyString.removeAllNewLines();
          } else {
            body = '$sizeInKo ko';
          }
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

        // Crop string if it's a GraphQL request body
        body = body.replaceAllMapped(RegExp(r'("query .+?\()(.+")(,.+?variables":)', dotAll: true), (match) => '${match.group(1)}...)${match.group(3)}');
      }
      if (_logHeaders) {
        headers = request.headers.toString();
      }
    }

    // Build log string
    debugPrint('API ($typeSymbol) $statusCode[$method $url] $body');
    if (headers != null) {
      debugPrint('API (${typeSymbol}H) $headers');
    }
  }

  static Future<void> throwIfNoInternet() async {
    if (await isOffline()) {
      debugPrint('API (✕) NO INTERNET');
      throw const ConnectivityException(ConnectivityExceptionType.noInternet);
    }
  }

  static Future<bool> isOffline() async => (await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);

  static Future<bool> isOnline() async => !(await isOffline());

  static bool isHttpSuccessCode(int httpStatusCode) => httpStatusCode >= 200 && httpStatusCode < 300;
  static void throwIfHttpError(http.Response response) {
    if (!isHttpSuccessCode(response.statusCode)) {
      throw HttpResponseException(response);
    }
  }
  //#endregion
}

class _ResponseHandler {
  _ResponseHandler(this.response) :
    isSuccess = ApiClient.isHttpSuccessCode(response.statusCode),
    isBodyJson = ContentType.parse(response.headers[HttpHeaders.contentTypeHeader] ?? '').mimeType == ApiClient.contentTypeJsonMimeType;

  final http.Response response;

  final bool isSuccess;
  final bool isBodyJson;

  String? _bodyString;
  String get bodyString => _bodyString ?? (_bodyString = response.body);

  /// Decode body as JSON and cast as [T].
  /// May throw if unexpected format.
  T bodyJson<T>() {
    // Decode json
    final bodyJson = json.decode(bodyString);

    // cast
    return bodyJson as T;
  }

  /// Same as [bodyJson], but will return null if operation fails.
  T? bodyJsonOrNull<T>() {
    try {
      return bodyJson<T?>();
    } catch(e) {
      debugPrint('ResponseHandler.Error : Could not decode json : $e : $bodyString');
    }
    return null;
  }
}

class _RandomFidGenerator {
  static const int fidLength = 22;
  static const int fid4BitPrefix = 0x70; // Byte.parseByte("01110000", 2);
  static const int removePrefixMask = 0x0F; // Byte.parseByte("00001111", 2);

  static String createRandomFid() {
    final uuid = Random().nextInt(1 << 32);   // If we need a real UUID, we might want to use a package like uuid.
    final bytesFromUUID = getBytesFromUUID(uuid);
    final b2 = bytesFromUUID[0];
    bytesFromUUID[16] = b2;
    bytesFromUUID[0] = (b2 & removePrefixMask) | fid4BitPrefix;
    return encodeFidBase64UrlSafe(bytesFromUUID);
  }

  static List<int> getBytesFromUUID(int uuid) {
    final buffer = ByteData(17);
    buffer.setUint64(0, uuid);
    buffer.setUint64(8, uuid);
    return buffer.buffer.asUint8List();
  }

  static String encodeFidBase64UrlSafe(List<int> bytes) => base64Url.encode(bytes).substring(0, fidLength);
}
};