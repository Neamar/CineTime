// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'showtimes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoviesShowTimes _$MoviesShowTimesFromJson(Map<String, dynamic> json) =>
    MoviesShowTimes(
      fetchedAt: StorageService.dateFromString(json['fetchedAt'] as String?),
      fromCache: json['fromCache'] as bool?,
      moviesShowTimes: (json['moviesShowTimes'] as List<dynamic>?)
          ?.map((e) => MovieShowTimes.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

MovieShowTimes _$MovieShowTimesFromJson(Map<String, dynamic> json) =>
    MovieShowTimes(
      Movie.fromJson(json['movie'] as Map<String, dynamic>),
      theatersShowTimes: (json['theatersShowTimes'] as List<dynamic>?)
          ?.map((e) => TheaterShowTimes.fromJson(e as Map<String, dynamic>)),
      filteredTheatersShowTimes: (json['filteredTheatersShowTimes']
              as List<dynamic>?)
          ?.map((e) => TheaterShowTimes.fromJson(e as Map<String, dynamic>)),
    );

TheaterShowTimes _$TheaterShowTimesFromJson(Map<String, dynamic> json) =>
    TheaterShowTimes(
      Theater.fromJson(json['theater'] as Map<String, dynamic>),
      showTimes: (json['showTimes'] as List<dynamic>?)
          ?.map((e) => ShowTime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

ShowTime _$ShowTimeFromJson(Map<String, dynamic> json) => ShowTime(
      json['dateTime'] == null
          ? null
          : DateTime.parse(json['dateTime'] as String),
      screen: json['screen'] as String?,
      seatCount: json['seatCount'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
