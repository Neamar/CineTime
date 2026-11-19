/// All cache policies of the app, gathered so durations can be compared at a glance.
abstract final class CachePolicies {
  /// Used by requests without a specific policy (e.g. theater search, FR trailers).
  static const defaultPolicy = CachePolicy(freshFor: Duration(days: 1), keepFor: Duration(days: 1));

  /// Showtimes of a theater, fetched automatically (e.g. page opened).
  /// Kept a week as a fallback, so showtimes are still available offline.
  static const showtimes = CachePolicy(freshFor: Duration(hours: 3), keepFor: Duration(days: 7));

  /// Showtimes of a theater, refreshed on purpose (e.g. pull-to-refresh): fresher data is required, while avoiding too many calls.
  static const showtimesRefresh = CachePolicy(freshFor: Duration(minutes: 30), keepFor: Duration(days: 7));

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
