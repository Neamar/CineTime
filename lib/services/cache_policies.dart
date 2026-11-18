/// All cache policies of the app, gathered so durations can be compared at a glance.
abstract final class CachePolicies {
  /// Used by requests without a specific policy (e.g. theater search, FR trailers).
  static const defaultPolicy = CachePolicy(freshFor: Duration(days: 1), keepFor: Duration(days: 1));

  /// Movie details (synopsis, certificate, ...): rarely updated, and still readable offline once opened.
  static const movieInfo = CachePolicy(freshFor: Duration(days: 3), keepFor: Duration(days: 30));

  /// Entries older than this are deleted at startup.
  /// Must be greater than or equal to the longest [CachePolicy.keepFor].
  static const deleteAfter = Duration(days: 30);
}

/// How long a cached response is used.
class CachePolicy {
  const CachePolicy({required this.freshFor, required this.keepFor});

  /// A younger entry is served from cache, without any network call.
  final Duration freshFor;

  /// A younger entry is served as a fallback when the network call fails. An older one is ignored.
  /// There is no fallback when equal to [freshFor] (a kept entry is always fresh).
  final Duration keepFor;
}
