import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cinetime/helpers/tools.dart';
import 'package:cinetime/models/_models.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';

class WebServices {   // TODO remove
  static bool useMocks = !kReleaseMode;
  static DateTime get mockedNow => useMocks ? DateTime(2020, 3, 11, 11, 55) : DateTime.now();

  static const _partnerKey = "100ED" + "1DA33EB";
  static const _secretKey = "1a1ed8c1bed24d60" + "ae3472eed1da33eb";
  static const _baseUrl = "https://api.allocine.fr/rest/v3/";

  static final _signatureDateFormatter = DateFormat("yyyyMMdd");
  static final _cacheManager = CtCacheManager();

  /// Send a http GET request, return decoded response
  static Future<Map<String, dynamic>> _httpGet(String method, Map<String, String> params, { bool? useCache, String? mockUrl }) async {
    useCache ??= false;

    // Add parameters
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
      responseFile = await _cacheManager.getSingleFile(url!);    // TODO because url contains 'sed' that changes every day, cache will just work for one day. Use flutter_cache_manager v2.0 when released and provide a custom key. Then add a mechanism to choose cache duration per request (synopsis can be long, whereas getMoviesList needs to be short).
    } else {
      responseFile = (await _cacheManager.downloadFile(url!)).file;
    }

    // Read response from cached file
    final response = await responseFile.readAsString();

    // Process response
    return json.decode(response);
  }
}

class CtCacheManager extends CacheManager {
  static const key = "CtCache";

  static CtCacheManager? _instance;

  factory CtCacheManager() {
    _instance ??= CtCacheManager._();
    return _instance!;
  }

  CtCacheManager._() : super(Config(
    key,
    stalePeriod: Duration(days: 1),
  ));

  @override
  Future<FileInfo?> getFileFromCache(String url, {bool ignoreMemCache = false}) async {
    debugPrint('WS.cache (?) [$url]');
    final fileInfo = await super.getFileFromCache(url, ignoreMemCache: ignoreMemCache);
    debugPrint('WS.cache (${fileInfo != null ? '✓' : '☓'}) [$url]');
    return fileInfo;
  }

  @override
  Future<FileInfo> downloadFile(String url, {String? key, Map<String, String>? authHeaders, bool force = false}) async {
    debugPrint('WS.server (?) [$url]');
    final fileInfo = await super.downloadFile(url, key: key, authHeaders: authHeaders, force: force);
    debugPrint('WS.server (✓) [$url]');
    return fileInfo;
  }
}

class NoInternetException extends ExceptionWithMessage {
  NoInternetException() : super('Verifiez votre connexion internet');
}