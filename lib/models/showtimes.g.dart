// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'showtimes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoviesShowTimes _$MoviesShowTimesFromJson(Map<String, dynamic> json) {
  return MoviesShowTimes(
    fetchedAt: StorageService.dateFromString(json['fetchedAt'] as String),
    fromCache: json['fromCache'] as bool,
    moviesShowTimes: (json['moviesShowTimes'] as List)
        ?.map((e) => e == null
            ? null
            : MovieShowTimes.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$MoviesShowTimesToJson(MoviesShowTimes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fromCache', instance.fromCache);
  writeNotNull('moviesShowTimes', instance.moviesShowTimes);
  writeNotNull('fetchedAt', StorageService.dateToString(instance.fetchedAt));
  return val;
}

MovieShowTimes _$MovieShowTimesFromJson(Map<String, dynamic> json) {
  return MovieShowTimes(
    json['movie'] == null
        ? null
        : Movie.fromJson(json['movie'] as Map<String, dynamic>),
    theatersShowTimes: (json['theatersShowTimes'] as List)?.map((e) => e == null
        ? null
        : TheaterShowTimes.fromJson(e as Map<String, dynamic>)),
    filteredTheatersShowTimes: (json['filteredTheatersShowTimes'] as List)?.map(
        (e) => e == null
            ? null
            : TheaterShowTimes.fromJson(e as Map<String, dynamic>)),
  );
}

Map<String, dynamic> _$MovieShowTimesToJson(MovieShowTimes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('movie', instance.movie);
  writeNotNull('theatersShowTimes', instance.theatersShowTimes);
  writeNotNull('filteredTheatersShowTimes', instance.filteredTheatersShowTimes);
  return val;
}

TheaterShowTimes _$TheaterShowTimesFromJson(Map<String, dynamic> json) {
  return TheaterShowTimes(
    json['theater'] == null
        ? null
        : Theater.fromJson(json['theater'] as Map<String, dynamic>),
    showTimes: (json['showTimes'] as List)
        ?.map((e) =>
            e == null ? null : ShowTime.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$TheaterShowTimesToJson(TheaterShowTimes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('theater', instance.theater);
  writeNotNull('showTimes', instance.showTimes);
  return val;
}

ShowTime _$ShowTimeFromJson(Map<String, dynamic> json) {
  return ShowTime(
    json['dateTime'] == null
        ? null
        : DateTime.parse(json['dateTime'] as String),
    screen: json['screen'] as String,
    seatCount: json['seatCount'] as int,
    tags: (json['tags'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$ShowTimeToJson(ShowTime instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('dateTime', instance.dateTime?.toIso8601String());
  writeNotNull('screen', instance.screen);
  writeNotNull('seatCount', instance.seatCount);
  writeNotNull('tags', instance.tags);
  return val;
}
