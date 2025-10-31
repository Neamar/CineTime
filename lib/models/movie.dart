import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';

class Movie extends Identifiable {
  Movie({
    required ApiId id,
    required this.title,
    this.poster,
    this.releaseDate,
    this.languages = const [],
    this.trailerId,
    this.directors,
    this.actors,
    this.genres,
    this.synopsis,
    this.durationDisplay,
    this.usersRating,
    this.pressRating,
  }) : super(id);

  final String title;
  final String? poster;    //Path to the image (not full url)

  final DateTime? releaseDate;
  String? get releaseDateDisplay => releaseDate != null ? AppResources.formatterDate.format(releaseDate!) : null;

  final List<String> languages;
  bool get isFrench => languages.singleOrNull == 'FRENCH';

  final ApiId? trailerId;
  final String? directors;
  final String? actors;
  final String? genres;
  final String? synopsis;

  final String? durationDisplay;
  Duration get duration {
    if (durationDisplay == null) return Duration.zero;

    final parts = durationDisplay!.split('h');
    if (parts.length != 2) return Duration.zero;

    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  final double? usersRating;
  final double? pressRating;
  double? getRating({MovieRatingType? preferredType}) => switch(preferredType) {
    MovieRatingType.users || null => usersRating ?? pressRating,
    MovieRatingType.press => pressRating ?? usersRating,
  };

  static const String _movieBaseUrl = 'https://www.all' + 'ocine.fr/film/fich' + 'efilm';
  String get movieUrl => '${_movieBaseUrl}_gen_cfilm=$id.html';
  String get usersRatingUrl => '$_movieBaseUrl-$id/critiques/spectateurs/';
  String get pressRatingUrl => '$_movieBaseUrl-$id/critiques/presse/';

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
  duration('Durée');

  const MovieSortType(this.label, {this.preferredRatingType});

  final String label;
  final MovieRatingType? preferredRatingType;
}

enum MovieRatingType { users, press }
