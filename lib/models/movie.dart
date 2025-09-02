import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';

class Movie extends Identifiable {
  Movie({
    required ApiId id,
    required this.title,
    this.poster,
    this.releaseDate,
    this.trailerId,
    this.directors,
    this.actors,
    JsonList? genresApi,
    this.synopsis,
    String? durationApi,
    this.usersRating,
    this.pressRating,
  }) :
    genres = _buildGenresFromApi(genresApi),
    durationDisplay = _buildDurationFromApi(durationApi),
    super(id);

  final String title;
  final String? poster;    //Path to the image (not full url)

  final DateTime? releaseDate;
  String? get releaseDateDisplay => releaseDate != null ? AppResources.formatterDate.format(releaseDate!) : null;

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

  static String? _buildGenresFromApi(JsonList? genresApi) => genresApi?.map((genreApi) => _genresMap[genreApi]).joinNotEmpty(', ');
  static String? _buildDurationFromApi(String? durationApi) {
    if (isStringNullOrEmpty(durationApi)) return null;

    List<String> parts = durationApi!.split(':');
    if (parts.length != 3) return null;

    final hours = int.tryParse(parts[0]);
    if (hours == null) return null;

    final minutes = int.tryParse(parts[1]);
    if (minutes == null) return null;

    return '${hours}h${minutes.toTwoDigitsString()}';
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

const _genresMap = {
  'ACTION': 'Action',
  'ADVENTURE': 'Aventure',
  'ANIMATION': 'Animation',
  'BIOPIC': 'Biopic',
  'BOLLYWOOD': 'Bollywood',
  'CARTOON': 'Dessin animé',
  'CLASSIC': 'Classique',
  'COMEDY': 'Comédie',
  'COMEDY_DRAMA': 'Comédie dramatique',
  'CONCERT': 'Concert',
  'DETECTIVE': 'Policier',
  'DIVERS': 'Divers',
  'DOCUMENTARY': 'Documentaire',
  'DRAMA': 'Drame',
  'EROTIC': 'Érotique',
  'EXPERIMENTAL': 'Expérimental',
  'FAMILY': 'Famille',
  'FANTASY': 'Fantaisie',
  'HISTORICAL': 'Historique',
  'HISTORICAL_EPIC': 'Épique',
  'HORROR': 'Horreur',
  'JUDICIAL': 'Judiciaire',
  'KOREAN_DRAMA': 'Drama',
  'MARTIAL_ARTS': 'Arts Martiaux',
  'MEDICAL': 'Médical',
  'MOBISODE': 'Programme court',
  'MOVIE_NIGHT': 'Nuit du cinéma',
  'MUSIC': 'Musique',
  'MUSICAL': 'Comédie musicale',
  'OPERA': 'Opéra',
  'ROMANCE': 'Romance',
  'SCIENCE_FICTION': 'Science-fiction',
  'PERFORMANCE': 'Performance',
  'SOAP': 'Drame',
  'SPORT_EVENT': 'Sport',
  'SPY': 'Espion',
  'THRILLER': 'Thriller',
  'WARMOVIE': 'Film de guerre',
  'WEB_SERIES': 'Série web',
  'WESTERN': 'Western',
};