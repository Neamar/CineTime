import 'package:cinetime/models/_models.dart';

/// Enum representing the available API providers (one per country/region).
enum ApiProviderType {
  allocine('France');

  const ApiProviderType(this.displayName);

  final String displayName;
}

/// Abstract interface for a movie/theater API provider.
///
/// Each country/region implements this interface to provide theater search,
/// showtimes, movie info, and related URL helpers.
abstract class ApiProvider {
  /// The type of this provider.
  ApiProviderType get type;

  /// Get theaters that match [query] (free text query).
  Future<List<Theater>> searchTheaters(String query);

  /// Get theaters around geo-position.
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude);

  /// Get movies and showtimes for the given [theaters].
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters, { bool useCache = true });

  /// Get detailed movie info (synopsis, certificate).
  Future<MovieInfo> getMovieInfo(ApiId movieId);

  /// Get the video URI for a trailer.
  Future<Uri?> getVideoUri(ApiId videoId);

  /// Get the full URL of an image from its [path].
  /// If [isThumbnail] is true, returns a smaller version.
  String? getImageUrl(String? path, {bool isThumbnail = false});

  /// Get the URL to the movie's page on the provider's website.
  String getMoviePageUrl(ApiId movieId);

  /// Get the URL to the movie's user ratings page.
  String getMovieUsersRatingUrl(ApiId movieId);

  /// Get the URL to the movie's press ratings page.
  String getMoviePressRatingUrl(ApiId movieId);
}
