// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movie _$MovieFromJson(Map<String, dynamic> json) => Movie(
      code: json['code'] as String,
      title: json['title'] as String,
      poster: json['poster'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      trailerCode: json['trailerCode'] as String?,
      directors: json['directors'] as String?,
      actors: json['actors'] as String?,
      genres: json['genres'] as String?,
      synopsis: json['synopsis'] as String?,
      duration: json['duration'] as int?,
      certificate: json['certificate'] == null
          ? null
          : MovieCertificate.fromJson(
              json['certificate'] as Map<String, dynamic>),
      pressRating: (json['pressRating'] as num?)?.toDouble(),
      userRating: (json['userRating'] as num?)?.toDouble(),
    );

MovieCertificate _$MovieCertificateFromJson(Map<String, dynamic> json) =>
    MovieCertificate(
      code: json['code'] as String,
      description: json['description'] as String?,
    );
