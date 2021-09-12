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

Map<String, dynamic> _$MovieToJson(Movie instance) {
  final val = <String, dynamic>{
    'code': instance.code,
    'title': instance.title,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('poster', instance.poster);
  writeNotNull('releaseDate', instance.releaseDate?.toIso8601String());
  writeNotNull('trailerCode', instance.trailerCode);
  writeNotNull('directors', instance.directors);
  writeNotNull('actors', instance.actors);
  writeNotNull('genres', instance.genres);
  writeNotNull('synopsis', instance.synopsis);
  writeNotNull('duration', instance.duration);
  writeNotNull('certificate', instance.certificate);
  writeNotNull('pressRating', instance.pressRating);
  writeNotNull('userRating', instance.userRating);
  return val;
}

MovieCertificate _$MovieCertificateFromJson(Map<String, dynamic> json) =>
    MovieCertificate(
      code: json['code'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$MovieCertificateToJson(MovieCertificate instance) {
  final val = <String, dynamic>{
    'code': instance.code,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  return val;
}
