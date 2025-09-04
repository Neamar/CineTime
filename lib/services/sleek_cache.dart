import 'package:value_stream/value_stream.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sleek_storage/sleek_storage.dart';

typedef AsyncValueGetter<T> = Future<T> Function();
typedef FromJson<T> = T Function(dynamic json);
typedef ToJson<T> = dynamic Function(T object);
typedef ValidityCallback = bool Function(DateTime? cachedAt);

T _defaultFromJson<T>(dynamic json) => json as T;
dynamic _defaultToJson<T>(T object) => object;

/// A simple cache manager for async tasks.
/// /!\ Stored value MUST be serializable to JSON.
/// Supports stale-while-revalidate and expiry.
///
/// Cache has two levels of validity:
/// - Stale: the data is old but can still be used (while a new fetch is performed in the background, or if fetch fails).
/// - Expired: the data is too old and should not be used.
///
/// TODO Add clearAllCache() & clearCache(key) methods
/// TODO clear expired cache entries automatically when app starts
class SleekCache {
  SleekCache._(this._storage, this.config);

  static Future<SleekCache> getInstance({SleekCacheGlobalConfig? config}) async {
    final storage = await SleekStorage.getInstance((await getTemporaryDirectory()).path, storageName: 'sleekCache');
    return SleekCache._(storage, config ?? const SleekCacheConfig());
  }

  final SleekStorage _storage;

  final SleekCacheGlobalConfig config;

  /// Run an async [task] and cache its result.
  /// If a valid cached value exists (not stale nor expired), it is returned immediately.
  /// Otherwise the [task] is run and the new value is cached and returned.
  /// If [task] throws an error, the cached value is returned if it is not expired.
  /// Otherwise the error is rethrown.
  Future<SleekCacheMetadata<T>> cachedTaskMeta<T>({
    required String key,
    required AsyncValueGetter<T> task,
    FromJson<T>? fromJson,
    ToJson<T>? toJson,
    SleekCacheConfig? config,
  }) async {
    final effectiveConfig = this.config.apply(config);

    // Check cached value
    final cache = _getCache(key, fromJson, toJson);
    final cachedMetadata = cache.value;

    // Check if cache is stale
    final cachedAt = cachedMetadata?.cachedAt;
    final isCacheStale = effectiveConfig._isCacheStale(cachedAt);

    // Return cached value if valid
    if (!isCacheStale) {
      return cachedMetadata!;
    }

    // Fetch new value
    T result;
    try {
      result = await task();
    } catch(e) {
      // Check if cache is expired
      final isCacheExpired = effectiveConfig._isCacheExpired(cachedAt);

      // Return cached value if not expired
      if (!isCacheExpired) {
        return cachedMetadata!;
      }

      // Rethrow error
      rethrow;
    }

    // Cache & return new value
    return cache.value = SleekCacheMetadata<T>._fetchedNow(value: result);
  }

  /// Shorthand for [cachedTaskMeta] that returns only the value.
  Future<T> cachedTask<T>({
    required String key,
    required AsyncValueGetter<T> task,
    FromJson<T>? fromJson,
    ToJson<T>? toJson,
    SleekCacheConfig? config,
  }) async => (await cachedTaskMeta(
    key: key,
    task: task,
    fromJson: fromJson,
    toJson: toJson,
    config: config,
  )).value;

  /// Run an async [task] and cache its result.
  /// If cached value is not expired (stale or not), it is emitted immediately.
  /// Then if cache is stale, [task] is run in the background and the new value is emitted.
  /// If cache is expired and [task] throws an error, the error is emitted.
  EventStream<SleekCacheMetadata<T>> cachedTaskBackgroundRefresh<T>({
    required String key,
    required AsyncValueGetter<T> task,
    FromJson<T>? fromJson,
    ToJson<T>? toJson,
    SleekCacheConfig? config,
  }) {
    final effectiveConfig = this.config.apply(config);

    // Check cached value
    final cache = _getCache(key, fromJson, toJson);
    var cachedMetadata = cache.value;

    // Check expiry
    final cachedAt = cachedMetadata?.cachedAt;
    final isCacheExpired = effectiveConfig._isCacheExpired(cachedAt);

    // Clear cache if expired
    if (isCacheExpired) {
      cachedMetadata = null;
    }

    // Build stream
    final stream = EventStream(cachedMetadata);

    // Check stale
    final isCacheStale = effectiveConfig._isCacheStale(cachedAt);

    // If cache is not stale, just return stream and stop here
    if (!isCacheStale) {
      return stream;
    }

    // Fetch new value in background
    () async {
      T result;
      try {
        result = await task();
      } catch(e) {
        // If cache was expired, emit error
        if (isCacheExpired) {
          stream.addError(e);
        }
        return;
      }

      // Cache new value
      final newMetadata = cache.value = SleekCacheMetadata<T>._fetchedNow(value: result);

      // Emit new value
      stream.add(newMetadata);
    }();

    // Return stream
    return stream;
  }

  SleekValue<SleekCacheMetadata<T>> _getCache<T>(String key, FromJson<T>? fromJson, ToJson<T>? toJson) => _storage.value<SleekCacheMetadata<T>>(
    key,
    fromJson: (key, json) => SleekCacheMetadata._fromJson(json, fromJson ?? _defaultFromJson),
    toJson: (value) => value._toJson(toJson ?? _defaultToJson),
  );
}

class SleekCacheGlobalConfig {
  const SleekCacheGlobalConfig({
    this.staleDuration,
    this.expiryDuration,
    this.isCacheStale,
    this.isCacheExpired,
  });

  /// Duration after which the cache is considered stale.
  final Duration? staleDuration;

  /// Duration after which the cache is considered expired.
  final Duration? expiryDuration;

  /// Custom callback to determine if the cache is stale.
  /// If provided, this callback overrides other settings.
  final ValidityCallback? isCacheStale;

  /// Custom callback to determine if the cache is expired.
  /// If provided, this callback overrides other settings.
  final ValidityCallback? isCacheExpired;

  /// Returns a [SleekCacheConfig] where each fields are overridden by each non-null field of [config].
  SleekCacheConfig apply(SleekCacheConfig? config) {
    return SleekCacheConfig(
      staleDuration: config?.staleDuration ?? staleDuration,
      staleDate: config?.staleDate,
      expiryDuration: config?.expiryDuration ?? expiryDuration,
      expiryDate: config?.expiryDate,
      isCacheStale: config?.isCacheStale ?? isCacheStale,
      isCacheExpired: config?.isCacheExpired ?? isCacheExpired,
    );
  }
}

class SleekCacheConfig extends SleekCacheGlobalConfig {
  const SleekCacheConfig({
    super.staleDuration,
    this.staleDate,
    super.expiryDuration,
    this.expiryDate,
    super.isCacheStale,
    super.isCacheExpired,
  });

  /// Date after which the cache is considered stale.
  final DateTime? staleDate;

  /// Date after which the cache is considered expired.
  final DateTime? expiryDate;

  bool _isCacheStale(DateTime? cachedAt) {
    if (isCacheStale != null) return isCacheStale!(cachedAt);
    return _isCacheExpired(cachedAt) || !_isCacheValid(cachedAt, staleDate, staleDuration);
  }

  bool _isCacheExpired(DateTime? cachedAt) {
    if (isCacheExpired != null) return isCacheExpired!(cachedAt);
    return !_isCacheValid(cachedAt, expiryDate, expiryDuration);
  }

  bool _isCacheValid(DateTime? cachedAt, DateTime? validUntil, Duration? validDuration) {   // TODO if both date and duration are set, we should check both and use the earliest
    // If no cached date, cache is not valid
    if (cachedAt == null) return false;

    // Build valid date
    validUntil ??= validDuration == null ? null : cachedAt.add(validDuration);

    // If no valid date, cache is always valid
    if (validUntil == null) return true;

    // Check valid date
    return DateTime.now().isBefore(validUntil);
  }
}

class SleekCacheMetadata<T> {
  const SleekCacheMetadata._({
    required this.value,
    required this.isFromCache,
    required this.cachedAt,
  });
  SleekCacheMetadata._fetchedNow({
    required this.value,
  }): isFromCache = false,
      cachedAt = DateTime.now();
  factory SleekCacheMetadata._fromJson(dynamic json, FromJson<T> valueFromJson) {
    return SleekCacheMetadata._(
      value: valueFromJson(json['value']),
      isFromCache: json['isFromCache'] as bool,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }

  final T value;
  final bool isFromCache;
  final DateTime cachedAt;

  Map<String, dynamic> _toJson(ToJson<T> valueToJson) => {
    'value': valueToJson(value),
    'isFromCache': isFromCache,
    'cachedAt': cachedAt.toIso8601String(),
  };
}
