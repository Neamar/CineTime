import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/helpers/tools.dart';
import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie extends Identifiable {
  final String title;
  final String poster;    //Path to the image (not full url)

  final DateTime releaseDate;
  String get releaseDateDisplay => releaseDate != null ? AppResources.formatterDate.format(releaseDate) : null;

  final String trailerCode;
  final String directors;
  final String actors;
  final String genres;
  final String synopsis;

  final int duration;   // In seconds
  String get durationDisplay => duration != null ? '${duration ~/ 3600}h${((duration % 3600) ~/ 60).toTwoDigitsString()}' : '';

  final MovieCertificate certificate;

  final double pressRating;
  final double userRating;
  double get rating => (pressRating != null && userRating != null ? (pressRating + userRating) / 2 : pressRating) ?? userRating;

  const Movie({String code, this.title, this.poster, this.releaseDate, this.trailerCode, this.directors, this.actors, this.genres, this.synopsis, this.duration, this.certificate, this.pressRating, this.userRating}) : super(code);

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson( instance) => _$MovieToJson(this);
}

// TODO use this instead of simple string
class MovieGenre extends Identifiable {
  final String name;

  const MovieGenre({String code, this.name}) : super(code);
}

@JsonSerializable()
class MovieCertificate extends Identifiable {
  final String description;

  const MovieCertificate({String code, this.description}) : super(code);

  factory MovieCertificate.fromJson(Map<String, dynamic> json) => _$MovieCertificateFromJson(json);
  Map<String, dynamic> toJson( instance) => _$MovieCertificateToJson(this);
}