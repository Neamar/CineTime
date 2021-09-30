import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';

class Movie extends Identifiable with Comparable<Movie> {
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
    this.pressRating,
    this.userRating,
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

  final double? pressRating;
  final double? userRating;
  double? get rating => (pressRating != null && userRating != null ? (pressRating! + userRating!) / 2 : pressRating) ?? userRating;

  @override
  int compareTo(Movie other) {
    if (this.userRating != null && other.userRating != null) return other.userRating!.compareTo(this.userRating!);
    if (this.pressRating != null && other.pressRating != null) return other.pressRating!.compareTo(this.pressRating!);
    return this.title.compareTo(other.title);
  }

  static String? _buildGenresFromApi(JsonList? genresApi) => genresApi?.map((genreApi) => _genresMap[genreApi]).joinNotNull(', ');
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

  factory MovieVideo.fromJson(Map<String, dynamic> json) => MovieVideo(
    quality: json['quality'],
    height: json['height'],
    url: json['url'],
    size: json['size'],
  );
}

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