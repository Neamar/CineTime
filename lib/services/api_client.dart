import 'package:cinetime/models/_models.dart';

enum Country { france, belgium }

abstract class ApiClient {
  /// Decode an [ApiId] previously persisted via [ApiId.encodedId] (e.g. from local storage).
  ApiId decodeStoredId(String encoded);

  /// Whether the source supports searching theaters around a geo-position.
  bool get supportsGeoSearch;

  Future<List<Theater>> searchTheaters(String query);
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude);
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters);
  Future<MovieInfo> getMovieInfo(ApiId movieId);
  Future<VideoData?> getVideoData(ApiId videoId);
  String? getImageUrl(String? path, {bool isThumbnail = false});
  Future<DateTime?> getShowEndTime(DateTime startAt, Duration? movieDuration, Uri ticketingUri);
  String moviePageUrl(String movieId);
  String movieUsersRatingUrl(String movieId);
  String moviePressRatingUrl(String movieId);

  String showTimeAudioSubtitlesToDisplayString(ShowTimeSpec spec);

  final _specDisplayCache = <ShowTimeSpec, String>{};

  /// Full display label of a spec (audio + subtitles + technology), cached since it's used in build methods.
  String showTimeSpecToDisplayString(ShowTimeSpec spec) => _specDisplayCache.putIfAbsent(spec, () {
    String label = showTimeAudioSubtitlesToDisplayString(spec);
    if (spec.technology != null) {
      label += ' ${spec.technology}';
    }
    return label;
  });
}

/// Everything needed to play a video.
class VideoData {
  const VideoData(this.uri, {this.headers = const {}});

  final Uri uri;

  /// HTTP headers required to read [uri]
  final Map<String, String> headers;
}
