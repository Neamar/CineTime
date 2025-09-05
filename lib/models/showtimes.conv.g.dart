// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'dart:core';
import 'package:dogs_core/dogs_core.dart' as gen;
import 'package:lyell/lyell.dart' as gen;
import 'dart:core' as gen0;
import 'package:cinetime/models/theater.dart' as gen1;
import 'package:cinetime/models/showtimes.dart' as gen2;
import 'package:cinetime/models/movie.dart' as gen3;
import 'package:cinetime/models/showtimes.dart';

class MoviesShowTimesConverter extends gen.DefaultStructureConverter<gen2.MoviesShowTimes> {
  MoviesShowTimesConverter()
      : super(
            struct: const gen.DogStructure<gen2.MoviesShowTimes>(
                'MoviesShowTimes',
                gen.StructureConformity.basic,
                [
                  gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen1.Theater>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen1.Theater>()]), gen.TypeToken<gen1.Theater>(), null,
                      gen.IterableKind.list, 'theaters', false, true, []),
                  gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.MovieShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.MovieShowTimes>()]),
                      gen.TypeToken<gen2.MovieShowTimes>(), null, gen.IterableKind.list, 'moviesShowTimes', false, true, []),
                  gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.TheaterShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.TheaterShowTimes>()]),
                      gen.TypeToken<gen2.TheaterShowTimes>(), null, gen.IterableKind.list, 'ghostShowTimes', false, true, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen0.DateTime>(), gen.TypeToken<gen0.DateTime>(), null, gen.IterableKind.none, 'fetchedFrom', false, true, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen0.DateTime>(), gen.TypeToken<gen0.DateTime>(), null, gen.IterableKind.none, 'fetchedTo', false, true, [])
                ],
                [],
                gen.ObjectFactoryStructureProxy<gen2.MoviesShowTimes>(_activator, [_$theaters, _$moviesShowTimes, _$ghostShowTimes, _$fetchedFrom, _$fetchedTo], _values)));

  static dynamic _$theaters(gen2.MoviesShowTimes obj) => obj.theaters;

  static dynamic _$moviesShowTimes(gen2.MoviesShowTimes obj) => obj.moviesShowTimes;

  static dynamic _$ghostShowTimes(gen2.MoviesShowTimes obj) => obj.ghostShowTimes;

  static dynamic _$fetchedFrom(gen2.MoviesShowTimes obj) => obj.fetchedFrom;

  static dynamic _$fetchedTo(gen2.MoviesShowTimes obj) => obj.fetchedTo;

  static List<dynamic> _values(gen2.MoviesShowTimes obj) => [obj.theaters, obj.moviesShowTimes, obj.ghostShowTimes, obj.fetchedFrom, obj.fetchedTo];

  static gen2.MoviesShowTimes _activator(List list) {
    return gen2.MoviesShowTimes(
        theaters: list[0].cast<gen1.Theater>(), moviesShowTimes: list[1].cast<gen2.MovieShowTimes>(), ghostShowTimes: list[2].cast<gen2.TheaterShowTimes>(), fetchedFrom: list[3], fetchedTo: list[4]);
  }
}

class MoviesShowTimesBuilder {
  MoviesShowTimesBuilder([gen2.MoviesShowTimes? $src]) {
    if ($src == null) {
      $values = List.filled(5, null);
    } else {
      $values = MoviesShowTimesConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.MoviesShowTimes? $src;

  set theaters(gen0.List<gen1.Theater> value) {
    $values[0] = value;
  }

  gen0.List<gen1.Theater> get theaters => $values[0];

  set moviesShowTimes(gen0.List<gen2.MovieShowTimes> value) {
    $values[1] = value;
  }

  gen0.List<gen2.MovieShowTimes> get moviesShowTimes => $values[1];

  set ghostShowTimes(gen0.List<gen2.TheaterShowTimes> value) {
    $values[2] = value;
  }

  gen0.List<gen2.TheaterShowTimes> get ghostShowTimes => $values[2];

  set fetchedFrom(gen0.DateTime value) {
    $values[3] = value;
  }

  gen0.DateTime get fetchedFrom => $values[3];

  set fetchedTo(gen0.DateTime value) {
    $values[4] = value;
  }

  gen0.DateTime get fetchedTo => $values[4];

  gen2.MoviesShowTimes build() {
    var instance = MoviesShowTimesConverter._activator($values);

    return instance;
  }
}

extension MoviesShowTimesDogsExtension on gen2.MoviesShowTimes {
  gen2.MoviesShowTimes rebuild(Function(MoviesShowTimesBuilder b) f) {
    var builder = MoviesShowTimesBuilder(this);
    f(builder);
    return builder.build();
  }

  MoviesShowTimesBuilder toBuilder() {
    return MoviesShowTimesBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.MoviesShowTimes);
  }
}

class MovieShowTimesConverter extends gen.DefaultStructureConverter<gen2.MovieShowTimes> {
  MovieShowTimesConverter()
      : super(
            struct: const gen.DogStructure<gen2.MovieShowTimes>(
                'MovieShowTimes',
                gen.StructureConformity.basic,
                [
                  gen.DogStructureField(gen.QualifiedTerminal<gen3.Movie>(), gen.TypeToken<gen3.Movie>(), null, gen.IterableKind.none, 'movie', false, true, []),
                  gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.TheaterShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.TheaterShowTimes>()]),
                      gen.TypeToken<gen2.TheaterShowTimes>(), null, gen.IterableKind.list, 'theatersShowTimes', true, true, [])
                ],
                [],
                gen.ObjectFactoryStructureProxy<gen2.MovieShowTimes>(_activator, [_$movie, _$theatersShowTimes], _values)));

  static dynamic _$movie(gen2.MovieShowTimes obj) => obj.movie;

  static dynamic _$theatersShowTimes(gen2.MovieShowTimes obj) => obj.theatersShowTimes;

  static List<dynamic> _values(gen2.MovieShowTimes obj) => [obj.movie, obj.theatersShowTimes];

  static gen2.MovieShowTimes _activator(List list) {
    return gen2.MovieShowTimes(list[0], theatersShowTimes: list[1]?.cast<gen2.TheaterShowTimes>());
  }
}

class MovieShowTimesBuilder {
  MovieShowTimesBuilder([gen2.MovieShowTimes? $src]) {
    if ($src == null) {
      $values = List.filled(2, null);
    } else {
      $values = MovieShowTimesConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.MovieShowTimes? $src;

  set movie(gen3.Movie value) {
    $values[0] = value;
  }

  gen3.Movie get movie => $values[0];

  set theatersShowTimes(gen0.List<gen2.TheaterShowTimes>? value) {
    $values[1] = value;
  }

  gen0.List<gen2.TheaterShowTimes>? get theatersShowTimes => $values[1];

  gen2.MovieShowTimes build() {
    var instance = MovieShowTimesConverter._activator($values);

    return instance;
  }
}

extension MovieShowTimesDogsExtension on gen2.MovieShowTimes {
  gen2.MovieShowTimes rebuild(Function(MovieShowTimesBuilder b) f) {
    var builder = MovieShowTimesBuilder(this);
    f(builder);
    return builder.build();
  }

  MovieShowTimesBuilder toBuilder() {
    return MovieShowTimesBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.MovieShowTimes);
  }
}

class TheaterShowTimesConverter extends gen.DefaultStructureConverter<gen2.TheaterShowTimes> {
  TheaterShowTimesConverter()
      : super(
            struct: const gen.DogStructure<gen2.TheaterShowTimes>(
                'TheaterShowTimes',
                gen.StructureConformity.basic,
                [
                  gen.DogStructureField(gen.QualifiedTerminal<gen1.Theater>(), gen.TypeToken<gen1.Theater>(), null, gen.IterableKind.none, 'theater', false, true, []),
                  gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.ShowTime>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.ShowTime>()]), gen.TypeToken<gen2.ShowTime>(), null,
                      gen.IterableKind.list, 'showTimes', true, true, [])
                ],
                [],
                gen.ObjectFactoryStructureProxy<gen2.TheaterShowTimes>(_activator, [_$theater, _$showTimes], _values)));

  static dynamic _$theater(gen2.TheaterShowTimes obj) => obj.theater;

  static dynamic _$showTimes(gen2.TheaterShowTimes obj) => obj.showTimes;

  static List<dynamic> _values(gen2.TheaterShowTimes obj) => [obj.theater, obj.showTimes];

  static gen2.TheaterShowTimes _activator(List list) {
    return gen2.TheaterShowTimes(list[0], showTimes: list[1]?.cast<gen2.ShowTime>());
  }
}

class TheaterShowTimesBuilder {
  TheaterShowTimesBuilder([gen2.TheaterShowTimes? $src]) {
    if ($src == null) {
      $values = List.filled(2, null);
    } else {
      $values = TheaterShowTimesConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.TheaterShowTimes? $src;

  set theater(gen1.Theater value) {
    $values[0] = value;
  }

  gen1.Theater get theater => $values[0];

  set showTimes(gen0.List<gen2.ShowTime>? value) {
    $values[1] = value;
  }

  gen0.List<gen2.ShowTime>? get showTimes => $values[1];

  gen2.TheaterShowTimes build() {
    var instance = TheaterShowTimesConverter._activator($values);

    return instance;
  }
}

extension TheaterShowTimesDogsExtension on gen2.TheaterShowTimes {
  gen2.TheaterShowTimes rebuild(Function(TheaterShowTimesBuilder b) f) {
    var builder = TheaterShowTimesBuilder(this);
    f(builder);
    return builder.build();
  }

  TheaterShowTimesBuilder toBuilder() {
    return TheaterShowTimesBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.TheaterShowTimes);
  }
}

class ShowTimeSpecConverter extends gen.DefaultStructureConverter<gen2.ShowTimeSpec> {
  ShowTimeSpecConverter()
      : super(
            struct: const gen.DogStructure<gen2.ShowTimeSpec>(
                'ShowTimeSpec',
                gen.StructureConformity.basic,
                [
                  gen.DogStructureField(gen.QualifiedTerminal<gen2.ShowVersion>(), gen.TypeToken<gen2.ShowVersion>(), null, gen.IterableKind.none, 'version', false, true, []),
                  gen.DogStructureField(gen.QualifiedTerminal<gen2.ShowFormat>(), gen.TypeToken<gen2.ShowFormat>(), null, gen.IterableKind.none, 'format', false, true, [])
                ],
                [],
                gen.ObjectFactoryStructureProxy<gen2.ShowTimeSpec>(_activator, [_$version, _$format], _values)));

  static dynamic _$version(gen2.ShowTimeSpec obj) => obj.version;

  static dynamic _$format(gen2.ShowTimeSpec obj) => obj.format;

  static List<dynamic> _values(gen2.ShowTimeSpec obj) => [obj.version, obj.format];

  static gen2.ShowTimeSpec _activator(List list) {
    return gen2.ShowTimeSpec(version: list[0], format: list[1]);
  }
}

class ShowTimeSpecBuilder {
  ShowTimeSpecBuilder([gen2.ShowTimeSpec? $src]) {
    if ($src == null) {
      $values = List.filled(2, null);
    } else {
      $values = ShowTimeSpecConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.ShowTimeSpec? $src;

  set version(gen2.ShowVersion value) {
    $values[0] = value;
  }

  gen2.ShowVersion get version => $values[0];

  set format(gen2.ShowFormat value) {
    $values[1] = value;
  }

  gen2.ShowFormat get format => $values[1];

  gen2.ShowTimeSpec build() {
    var instance = ShowTimeSpecConverter._activator($values);

    return instance;
  }
}

extension ShowTimeSpecDogsExtension on gen2.ShowTimeSpec {
  gen2.ShowTimeSpec rebuild(Function(ShowTimeSpecBuilder b) f) {
    var builder = ShowTimeSpecBuilder(this);
    f(builder);
    return builder.build();
  }

  ShowTimeSpecBuilder toBuilder() {
    return ShowTimeSpecBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.ShowTimeSpec);
  }
}
