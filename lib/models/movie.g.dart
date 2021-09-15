// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movie _$MovieFromJson(Map<String, dynamic> json) => Movie(
      id: json['id'] as String,
      title: json['title'] as String,
      poster: json['poster'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      trailerId: json['trailerId'] as String?,
      directors: json['directors'] as String?,
      actors: json['actors'] as String?,
      genres: json['genres'] as String?,
      synopsis: json['synopsis'] as String?,
      duration: json['duration'] as int?,
      pressRating: (json['pressRating'] as num?)?.toDouble(),
      userRating: (json['userRating'] as num?)?.toDouble(),
    );
