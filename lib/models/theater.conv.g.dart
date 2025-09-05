// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'dart:core';
import 'package:dogs_core/dogs_core.dart' as gen;
import 'package:lyell/lyell.dart' as gen;
import 'package:cinetime/models/api_id.dart' as gen0;
import 'dart:core' as gen1;
import 'package:cinetime/models/theater.dart' as gen2;
import 'package:cinetime/models/theater.dart';

class TheaterConverter extends gen.DefaultStructureConverter<gen2.Theater> {
  TheaterConverter()
      : super(
            struct: const gen.DogStructure<gen2.Theater>(
                'Theater',
                gen.StructureConformity.basic,
                [
                  gen.DogStructureField(gen.QualifiedTerminal<gen0.ApiId>(), gen.TypeToken<gen0.ApiId>(), null, gen.IterableKind.none, 'id', false, true, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), gen.TypeToken<gen1.String>(), null, gen.IterableKind.none, 'name', false, false, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), gen.TypeToken<gen1.String>(), null, gen.IterableKind.none, 'street', true, false, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), gen.TypeToken<gen1.String>(), null, gen.IterableKind.none, 'zipCode', true, false, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), gen.TypeToken<gen1.String>(), null, gen.IterableKind.none, 'city', true, false, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.double>(), gen.TypeToken<gen1.double>(), null, gen.IterableKind.none, 'distance', true, false, [])
                ],
                [],
                gen.ObjectFactoryStructureProxy<gen2.Theater>(_activator, [_$id, _$name, _$street, _$zipCode, _$city, _$distance], _values)));

  static dynamic _$id(gen2.Theater obj) => obj.id;

  static dynamic _$name(gen2.Theater obj) => obj.name;

  static dynamic _$street(gen2.Theater obj) => obj.street;

  static dynamic _$zipCode(gen2.Theater obj) => obj.zipCode;

  static dynamic _$city(gen2.Theater obj) => obj.city;

  static dynamic _$distance(gen2.Theater obj) => obj.distance;

  static List<dynamic> _values(gen2.Theater obj) => [obj.id, obj.name, obj.street, obj.zipCode, obj.city, obj.distance];

  static gen2.Theater _activator(List list) {
    return gen2.Theater(id: list[0], name: list[1], street: list[2], zipCode: list[3], city: list[4], distance: list[5]);
  }
}

class TheaterBuilder {
  TheaterBuilder([gen2.Theater? $src]) {
    if ($src == null) {
      $values = List.filled(6, null);
    } else {
      $values = TheaterConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.Theater? $src;

  set id(gen0.ApiId value) {
    $values[0] = value;
  }

  gen0.ApiId get id => $values[0];

  set name(gen1.String value) {
    $values[1] = value;
  }

  gen1.String get name => $values[1];

  set street(gen1.String? value) {
    $values[2] = value;
  }

  gen1.String? get street => $values[2];

  set zipCode(gen1.String? value) {
    $values[3] = value;
  }

  gen1.String? get zipCode => $values[3];

  set city(gen1.String? value) {
    $values[4] = value;
  }

  gen1.String? get city => $values[4];

  set distance(gen1.double? value) {
    $values[5] = value;
  }

  gen1.double? get distance => $values[5];

  gen2.Theater build() {
    var instance = TheaterConverter._activator($values);

    return instance;
  }
}

extension TheaterDogsExtension on gen2.Theater {
  gen2.Theater rebuild(Function(TheaterBuilder b) f) {
    var builder = TheaterBuilder(this);
    f(builder);
    return builder.build();
  }

  TheaterBuilder toBuilder() {
    return TheaterBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.Theater);
  }
}
