import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';

class Movie extends Identifiable {
  Movie({
    required ApiId id,
    required this.title,
    this.originalTitle,
    this.poster,
    this.releaseYear,
    this.releaseDate,
    this.languages,
    this.trailerId,
    this.country,
    this.countryCode,
    this.directors,
    this.actors,
    this.genres,
    this.synopsis,
    this.durationDisplay,
    this.usersRating,
    this.pressRating,
  }) : super(id);

  final String title;
  final String? originalTitle;
  final String? poster;    // Path to the image (not full url)

  final String? releaseYear;    // Only the year (when full release date is not available)
  final DateTime? releaseDate;
  late final String? releaseYearDisplay = () {
    final releaseYearResolved = () {
      final releaseDate = this.releaseDate;
      if (releaseDate != null) {
        // Display release year if movie is more than 6 month old
        return AppService.now.difference(releaseDate) > const Duration(days: 6 * 30)
            ? releaseDate.year.toString()
            : null;
      } else if (releaseYear != null) {
        // Display is year is NOT current year
        final currentYear = AppService.now.year.toString();
        return currentYear != releaseYear
            ? releaseYear
            : null;
      }
      return null;
    } ();
    return releaseYearResolved != null ? '($releaseYearResolved)' : null;
  } ();
  late final String? releaseDateDisplay = releaseDate != null ? AppResources.formatterDate.format(releaseDate!) : null;

  /// Formated, displayable list of language, in french
  final String? languages;

  final String? country;
  final String? countryCode;
  late final String? countryDisplay = countryCode ?? country;

  final ApiId? trailerId;
  final String? directors;
  final String? actors;
  final String? genres;
  final String? synopsis;

  final String? durationDisplay;
  late final Duration duration = () {
    if (durationDisplay == null) return Duration.zero;

    final parts = durationDisplay!.split('h');
    if (parts.length != 2) return Duration.zero;

    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  } ();

  final double? usersRating;
  final double? pressRating;
  double? getRating({MovieRatingType? preferredType}) => switch(preferredType) {
    MovieRatingType.users || null => usersRating ?? pressRating,
    MovieRatingType.press => pressRating ?? usersRating,
  };

  String get movieUrl => AppService.api.moviePageUrl(id.id);
  String get usersRatingUrl => AppService.api.movieUsersRatingUrl(id.id);
  String get pressRatingUrl => AppService.api.moviePressRatingUrl(id.id);

  /// Return true if this movie match the [search] query
  bool matchSearch(String search) {
    search = search.normalized;
    if (title.normalized.contains(search)) return true;
    if (directors?.normalized.contains(search) == true) return true;
    if (actors?.normalized.contains(search) == true) return true;
    return false;
  }

  int compareTo(Movie other, MovieSortType type) {
    switch(type) {
      case MovieSortType.usersRating:
        if (usersRating != null && other.usersRating != null) return other.usersRating!.compareTo(usersRating!);
        if (pressRating != null && other.pressRating != null) return other.pressRating!.compareTo(pressRating!);
        return title.compareTo(other.title);
      case MovieSortType.pressRating:
        if (pressRating != null && other.pressRating != null) return other.pressRating!.compareTo(pressRating!);
        if (usersRating != null && other.usersRating != null) return other.usersRating!.compareTo(usersRating!);
        return title.compareTo(other.title);
      case MovieSortType.releaseDate:
        final date1 = releaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final date2 = other.releaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return date2.compareTo(date1);
      case MovieSortType.nextShow:
        return title.compareTo(other.title);  // Fallback: showtime data not available at Movie level
      case MovieSortType.duration:
        return duration.compareTo(other.duration);
    }
  }
}

class MovieInfo {
  const MovieInfo({this.synopsis, this.certificate});

  final String? synopsis;
  final String? certificate;
}

class MovieVideo {
  const MovieVideo({
    this.quality,
    required this.height,
    required this.url,
    required this.size,
  });

  final String? quality;
  final int height;
  final String url;
  final int size;

  Uri? get uri => Uri.tryParse(url);

  factory MovieVideo.fromJson(Map<String, dynamic> json) => MovieVideo(
    quality: json['quality'],
    height: json['height'],
    url: json['url'],
    size: json['size'],
  );
}

enum MovieSortType {
  usersRating('Note spectateurs', preferredRatingType: MovieRatingType.users),
  pressRating('Note presse', preferredRatingType: MovieRatingType.press),
  releaseDate('Date de sortie'),
  nextShow('Prochaine séance'),
  duration('Durée');

  const MovieSortType(this.label, {this.preferredRatingType});

  final String label;
  final MovieRatingType? preferredRatingType;
}

enum MovieRatingType { users, press }
