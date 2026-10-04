import 'dart:io';

import 'package:cinetime/utils/_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:sleek_http_client/sleek_http_client.dart' hide HttpResponseException, JsonObject, JsonList;

/// Caches successful responses to disk, keyed by [keyBuilder].
/// Placed outermost in the interceptor list, so a cache hit short-circuits everything after it (GraphQL error check, logging, the real network call).
class CacheInterceptor implements HttpInterceptor {
  CacheInterceptor({required this.keyBuilder, this.shouldCache});

  /// Whether to use cache or not
  static const enabled = true;

  /// Shared by all API clients (hosts differ, so keys can't collide), and created only once even if a client is re-instantiated.
  static final _cacheManager = CacheManager(Config(
    'CtCache',
    stalePeriod: const Duration(days: 1),
  ));

  final String Function(http.BaseRequest request) keyBuilder;

  /// When it returns false for a request, cache is bypassed (neither read nor written). Defaults to caching everything.
  final bool Function(http.BaseRequest request)? shouldCache;

  @override
  Future<http.Response> intercept(http.BaseRequest request, HttpInterceptorChain chain) async {
    if (shouldCache?.call(request) == false) return chain.proceed(request);

    final cacheKey = keyBuilder(request);

    // Check cache
    final cachedResponseFile = await _cacheManager.getFileFromCache(cacheKey);

    // If cache is available
    if (cachedResponseFile != null) {
      debugPrint('[CacheInterceptor] ✅ HIT — reading from cache for $cacheKey');

      // Read response from cached file
      final cachedResponse = await cachedResponseFile.file.readAsString();

      // Process response
      return http.Response(cachedResponse, 200,
        headers: {HttpHeaders.contentTypeHeader: SleekHttpClient.contentTypeJson}, // Needed so content is decoded using utf-8
        request: http.Request('CACHE', Uri.parse(cachedResponseFile.file.path)),
      );
    }

    // Cache miss: proceed with the real request
    debugPrint('[CacheInterceptor] ❌ MISS — fetching from network for $cacheKey');
    final response = await chain.proceed(request);

    // Store in cache
    if (SleekHttpClient.isStatusCodeSuccess(response.statusCode)) {
      try {
        await _cacheManager.putFile(cacheKey, response.bodyBytes);
        debugPrint('[CacheInterceptor] 💾 Writing response to cache for $cacheKey');
      } catch (e, s) {
        reportError(e, s);
      }
    }

    return response;
  }
}
