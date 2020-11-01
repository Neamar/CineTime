// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'showtimes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TheatersShowTimes _$TheatersShowTimesFromJson(Map<String, dynamic> json) {
  return TheatersShowTimes(
    fetchedAt: StorageService.dateFromString(json['fetchedAt'] as String),
    fromCache: json['fromCache'] as bool,
    moviesShowTimes: (json['moviesShowTimes'] as List)?.map((e) =>
        e == null ? null : MovieShowTimes.fromJson(e as Map<String, dynamic>)),
  );
}

Map<String, dynamic> _$TheatersShowTimesToJson(TheatersShowTimes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fromCache', instance.fromCache);
  writeNotNull('moviesShowTimes', instance.moviesShowTimes?.toList());
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
  return val;
}

TheaterShowTimes _$TheaterShowTimesFromJson(Map<String, dynamic> json) {
  return TheaterShowTimes(
    json['theater'] == null
        ? null
        : Theater.fromJson(json['theater'] as Map<String, dynamic>),
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
  return val;
}

RoomShowTimes _$RoomShowTimesFromJson(Map<String, dynamic> json) {
  return RoomShowTimes(
    screen: json['screen'] as String,
    seatCount: json['seatCount'] as int,
    isOriginalLanguage: json['isOriginalLanguage'] as bool,
    is3D: json['is3D'] as bool,
    isIMAX: json['isIMAX'] as bool,
    showTimesRaw: (json['showTimes'] as List)
        ?.map((e) => e == null ? null : DateTime.parse(e as String))
        ?.toList(),
  );
}

Map<String, dynamic> _$RoomShowTimesToJson(RoomShowTimes instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('screen', instance.screen);
  writeNotNull('seatCount', instance.seatCount);
  writeNotNull('isOriginalLanguage', instance.isOriginalLanguage);
  writeNotNull('is3D', instance.is3D);
  writeNotNull('isIMAX', instance.isIMAX);
  writeNotNull('showTimes',
      instance.showTimesRaw?.map((e) => e?.toIso8601String())?.toList());
  return val;
}
