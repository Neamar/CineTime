import 'package:cinetime/models/_models.dart';

abstract class ApiClient {
  /// Decode an [ApiId] previously persisted via [ApiId.encodedId] (e.g. from local storage).
  ApiId decodeStoredId(String encoded);

  Future<List<Theater>> searchTheaters(String query);
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude);
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters);
  Future<MovieInfo> getMovieInfo(ApiId movieId);
  Future<Uri?> getVideoUri(ApiId videoId);
  String? getImageUrl(String? path, {bool isThumbnail = false});
  Future<DateTime?> getShowEndTime(DateTime startAt, Duration? movieDuration, Uri ticketingUri);
  String moviePageUrl(String movieId);
  String movieUsersRatingUrl(String movieId);
  String moviePressRatingUrl(String movieId);
}
