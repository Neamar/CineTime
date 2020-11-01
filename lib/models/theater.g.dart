// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theater.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Theater _$TheaterFromJson(Map<String, dynamic> json) {
  return Theater(
    code: json['code'] as String,
    name: json['name'] as String,
    poster: json['poster'] as String,
    street: json['street'] as String,
    zipCode: json['zipCode'] as String,
    city: json['city'] as String,
  );
}

Map<String, dynamic> _$TheaterToJson(Theater instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('code', instance.code);
  writeNotNull('name', instance.name);
  writeNotNull('poster', instance.poster);
  writeNotNull('street', instance.street);
  writeNotNull('zipCode', instance.zipCode);
  writeNotNull('city', instance.city);
  return val;
}
