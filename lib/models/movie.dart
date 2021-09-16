import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/utils/_utils.dart';

class Movie extends Identifiable {
  const Movie({
    required ApiId id,
    required this.title,
    this.poster,
    this.releaseDate,
    this.trailerId,
    this.directors,
    this.actors,
    this.genres,
    this.synopsis,
    this.duration,
    this.pressRating,
    this.userRating,
  }) : super(id);

  final String title;
  final String? poster;    //Path to the image (not full url)

  final DateTime? releaseDate;
  String? get releaseDateDisplay => releaseDate != null ? AppResources.formatterDate.format(releaseDate!) : null;

  final ApiId? trailerId;
  final String? directors;
  final String? actors;
  final String? genres;
  final String? synopsis;

  final int? duration;   // In seconds
  String get durationDisplay => duration != null ? '${duration! ~/ 3600}h${((duration! % 3600) ~/ 60).toTwoDigitsString()}' : '';

  final double? pressRating;
  final double? userRating;
  double? get rating => (pressRating != null && userRating != null ? (pressRating! + userRating!) / 2 : pressRating) ?? userRating;
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