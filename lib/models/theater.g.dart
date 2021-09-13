// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theater.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Theater _$TheaterFromJson(Map<String, dynamic> json) => Theater(
      code: json['code'] as String,
      name: json['name'] as String,
      poster: json['poster'] as String?,
      street: json['street'] as String?,
      zipCode: json['zipCode'] as String?,
      city: json['city'] as String?,
    );

Map<String, dynamic> _$TheaterToJson(Theater instance) {
  final val = <String, dynamic>{
    'code': instance.code,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('poster', instance.poster);
  writeNotNull('street', instance.street);
  writeNotNull('zipCode', instance.zipCode);
  writeNotNull('city', instance.city);
  return val;
}
