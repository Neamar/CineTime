import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/http_response_exception.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sleek_http_client/sleek_http_client.dart' hide HttpResponseException, JsonObject, JsonList;

import 'cache_policies.dart';

/// Caches successful responses on disk, following a [CachePolicy] per request, and serves them as a fallback when the network call fails.
/// Raw responses are stored (not parsed data), so parsing changes also apply to cached data.
/// Configured per request with [CacheOptions].
///
/// Placed outermost in the interceptor list, so a cache hit short-circuits everything after it (GraphQL error check, logging, the real network call),
/// and so any error thrown after it (no internet, timeout, GraphQL error, incomplete page, ...) triggers the fallback.
class CacheInterceptor implements HttpInterceptor {
  const CacheInterceptor();

  /// Whether to use cache or not
  static const enabled = true;

  /// Key of the [CacheOptions] in the request extra
  static const optionsKey = 'cacheOptions';

  /// Increase [_version] when the entry format changes: previous entries are then deleted.
  static const _directoryPrefix = 'http_cache_v';
  static const _version = 1;

  /// Cache directory. Null until initialized (or if initialization failed): cache is then bypassed.
  static Directory? _directory;

  /// Get the cache directory ready, then delete old entries in the background.
  /// Never throws: on failure, cache is just bypassed.
  static Future<void> init() async {
    try {
      final parentPath = (await getApplicationCacheDirectory()).path;
      final directory = _directory = await Directory('$parentPath/$_directoryPrefix$_version').create(recursive: true);
      unawaited(_purge(parentPath, directory));
    } catch (e, s) {
      reportError(e, s);
    }
  }

  /// Delete all entries (e.g. when switching country).
  static Future<void> clear() async {
    final directory = _directory;
    if (directory == null) return;
    try {
      await directory.delete(recursive: true);
      await directory.create(recursive: true);
    } catch (e, s) {
      reportError(e, s);
    }
  }

  /// Delete directories of previous versions, and entries older than [CachePolicies.deleteAfter].
  /// Based on files modification date, so entries don't need to be read.
  static Future<void> _purge(String parentPath, Directory directory) async {
    try {
      for (var version = 1; version < _version; version++) {
        final previousDirectory = Directory('$parentPath/$_directoryPrefix$version');
        if (await previousDirectory.exists()) await previousDirectory.delete(recursive: true);
      }

      final deleteBefore = DateTime.now().subtract(CachePolicies.deleteAfter);
      await for (final entity in directory.list()) {
        if (entity is File && (await entity.lastModified()).isBefore(deleteBefore)) await entity.delete();
      }
    } catch (e, s) {
      reportError(e, s);
    }
  }

  @override
  Future<http.Response> intercept(http.BaseRequest request, HttpInterceptorChain chain) async {
    // Get options and directory
    final options = request.extra[optionsKey] as CacheOptions?;
    final directory = _directory;

    // Bypass cache
    if (!enabled || directory == null || options?.enabled == false) return chain.proceed(request);

    // Get policy and log label
    final policy = options?.policy ?? CachePolicies.defaultPolicy;
    final logLabel = '[${request.method}] ${request.url}${options?.key != null ? ' (${options!.key})' : ''}';
    final file = File('${directory.path}/${_buildKey(request, options?.key)}');

    // Check cache
    final entry = await _read(file, maxAge: policy.keepFor);

    // If entry is fresh, skip network
    if (entry != null && entry.age < policy.freshFor) {
      debugPrint('[CacheInterceptor] ✅ HIT — $logLabel');
      options?.status?._record(entry.storedAt, isFallback: false);
      return entry.toResponse(request);
    }

    // Otherwise, proceed with the real request
    debugPrint('[CacheInterceptor] ❌ MISS — $logLabel');
    final http.Response response;
    try {
      response = await chain.proceed(request);
    } on RequestAbortedException {
      rethrow;    // Cancelled on purpose: not a failure
    } catch (e, s) {
      if (entry == null) rethrow;
      return _fallback(request, entry, options, logLabel, e, s);
    }

    // HTTP errors are received as a response: the client only turns them into an exception after the interceptors
    if (!SleekHttpClient.isStatusCodeSuccess(response.statusCode)) {
      if (entry == null) return response;
      return _fallback(request, entry, options, logLabel, HttpResponseException(response), StackTrace.current);
    }

    // Store in cache
    final newEntry = _CacheEntry.fromResponse(response, storedAt: DateTime.now());
    await _write(file, newEntry);
    options?.status?._record(newEntry.storedAt, isFallback: false);
    return response;
  }

  http.Response _fallback(http.BaseRequest request, _CacheEntry entry, CacheOptions? options, String logLabel, Object error, StackTrace stack) {
    debugPrint('[CacheInterceptor] 🛟 FALLBACK — $logLabel');
    reportError(error, stack);    // Swallowed here, so reported here. Network errors are filtered out by reportError.
    options?.status?._record(entry.storedAt, isFallback: true);
    return entry.toResponse(request);
  }

  /// Build the file name of a request's entry.
  /// Hashed, as raw keys can be long (GraphQL query in the body) and contain characters not allowed in file names.
  /// Host is always included, so keys of different APIs can't collide.
  static String _buildKey(http.BaseRequest request, String? key) {
    key ??= '${request.method}|${request.url}|${request is http.Request ? request.body : ''}';
    return sha256.convert(utf8.encode('${request.url.host}|$key')).toString();
  }

  /// Read the entry in [file], if any and younger than [maxAge].
  static Future<_CacheEntry?> _read(File file, {required Duration maxAge}) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on PathNotFoundException {
      return null;
    } catch (e, s) {
      reportError(e, s);
      return null;
    }

    try {
      final entry = _CacheEntry.fromBytes(bytes);
      return entry.age < maxAge ? entry : null;
    } catch (e, s) {
      reportError(e, s);    // Corrupted entry: ignored, and overwritten by the next successful call
      return null;
    }
  }

  /// Never throws: a cache failure must not fail the request.
  static Future<void> _write(File file, _CacheEntry entry) async {
    try {
      // Write to a temporary file first, then rename it (atomic), so a concurrent read never gets a partial entry
      final tempFile = File('${file.path}.${entry.storedAt.microsecondsSinceEpoch}.tmp');
      await tempFile.writeAsBytes(entry.toBytes(), flush: true);
      await tempFile.rename(file.path);
    } catch (e, s) {
      reportError(e, s);
    }
  }
}

/// Cache options of a request, passed through its extra (see [toExtra]).
class CacheOptions {
  const CacheOptions({this.key, this.policy, this.status}) : enabled = true;

  /// Bypass the cache entirely (neither read nor written).
  const CacheOptions.disabled() : key = null, policy = null, status = null, enabled = false;

  /// Explicit key, instead of the default one built from the request (method, url and body).
  /// Useful when a response stays usable while the request changes (e.g. a date in the body).
  final String? key;

  /// Defaults to [CachePolicies.defaultPolicy].
  final CachePolicy? policy;

  /// Filled by the interceptor, to know where the response comes from.
  final CacheStatus? status;

  final bool enabled;

  Map<String, Object> toExtra() => {CacheInterceptor.optionsKey: this};
}

/// Origin of the responses of one or several requests, filled by [CacheInterceptor].
/// The same instance can be passed to several requests (e.g. one per theater), to get their aggregated origin.
class CacheStatus {
  /// Oldest storage date among the responses (the network call date, if not served from cache).
  DateTime? get oldestUpdate => _oldestUpdate;
  DateTime? _oldestUpdate;

  /// Whether at least one response is a fallback, served because the network call failed.
  bool get isFallback => _isFallback;
  bool _isFallback = false;

  void _record(DateTime storedAt, {required bool isFallback}) {
    final oldestUpdate = _oldestUpdate;
    if (oldestUpdate == null || storedAt.isBefore(oldestUpdate)) _oldestUpdate = storedAt;
    _isFallback |= isFallback;
  }
}

/// A cached response.
/// Stored as a JSON header line (metadata), followed by the raw response body.
class _CacheEntry {
  const _CacheEntry({required this.storedAt, required this.statusCode, required this.contentType, required this.body});

  _CacheEntry.fromResponse(http.Response response, {required this.storedAt}) :
    statusCode = response.statusCode,
    contentType = response.headers[HttpHeaders.contentTypeHeader],
    body = response.bodyBytes;

  /// Throws if [bytes] isn't a valid entry.
  factory _CacheEntry.fromBytes(Uint8List bytes) {
    final headerEnd = bytes.indexOf(_headerSeparator);
    final Map<String, dynamic> header = json.decode(utf8.decode(Uint8List.sublistView(bytes, 0, headerEnd)));
    return _CacheEntry(
      storedAt: DateTime.fromMillisecondsSinceEpoch(header['storedAt']),
      statusCode: header['statusCode'],
      contentType: header['contentType'],
      body: Uint8List.sublistView(bytes, headerEnd + 1),
    );
  }

  static const _headerSeparator = 0x0A;    // '\n', never found in a JSON-encoded string

  final DateTime storedAt;
  final int statusCode;
  final String? contentType;
  final Uint8List body;

  Duration get age => DateTime.now().difference(storedAt);

  Uint8List toBytes() {
    final header = json.encode({
      'storedAt': storedAt.millisecondsSinceEpoch,
      'statusCode': statusCode,
      'contentType': contentType,
    });
    return (BytesBuilder(copy: false)
      ..add(utf8.encode(header))
      ..addByte(_headerSeparator)
      ..add(body)).takeBytes();
  }

  /// Original content type is restored, so the body is decoded with the right charset.
  http.Response toResponse(http.BaseRequest request) => http.Response.bytes(body, statusCode,
    headers: {if (contentType != null) HttpHeaders.contentTypeHeader: contentType!},
    request: request,
  );
}
