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
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      version: _$enumDecodeNullable(_$ShowVersionEnumMap, json['version']),
      format: _$enumDecodeNullable(_$ShowFormatEnumMap, json['format']) ??
          ShowFormat.f2D,
    );

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$ShowVersionEnumMap = {
  ShowVersion.original: 'original',
  ShowVersion.dubbed: 'dubbed',
};

const _$ShowFormatEnumMap = {
  ShowFormat.f2D: 'f2D',
  ShowFormat.f3D: 'f3D',
  ShowFormat.IMAX: 'IMAX',
  ShowFormat.IMAX_3D: 'IMAX_3D',
};
