// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, unnecessary_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'dart:core';
import 'package:dogs_core/dogs_core.dart' as gen;
import 'package:lyell/lyell.dart' as gen;
import 'dart:core' as gen0;
import 'package:cinetime/models/theater.dart' as gen1;
import 'package:cinetime/models/showtimes.dart' as gen2;
import 'package:dogs_core/src/annotations.dart' as gen3;
import 'package:cinetime/models/movie.dart' as gen4;
import 'package:cinetime/models/showtimes.dart';

class MoviesShowTimesConverter extends gen.DefaultStructureConverter<gen2.MoviesShowTimes> {
  MoviesShowTimesConverter()
    : super(
        struct: const gen.DogStructure<gen2.MoviesShowTimes>(
          'MoviesShowTimes',
          gen.StructureConformity.basic,
          [
            gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen1.Theater>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen1.Theater>()]), null, 'theaters', false, true, []),
            gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.MovieShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.MovieShowTimes>()]), null, 'moviesShowTimes', false, true, []),
            gen.DogStructureField(
              gen.QualifiedTypeTreeN<gen0.List<gen2.TheaterShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.TheaterShowTimes>()]),
              null,
              'ghostShowTimes',
              false,
              true,
              [],
            ),
            gen.DogStructureField(gen.QualifiedTerminal<gen0.DateTime>(), null, 'fetchedFrom', false, true, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen0.DateTime>(), null, 'fetchedTo', false, true, []),
          ],
          [gen3.serializable],
          gen.ObjectFactoryStructureProxy<gen2.MoviesShowTimes>(_activator, [_$theaters, _$moviesShowTimes, _$ghostShowTimes, _$fetchedFrom, _$fetchedTo], _values),
        ),
      );

  static dynamic _$theaters(gen2.MoviesShowTimes obj) => obj.theaters;

  static dynamic _$moviesShowTimes(gen2.MoviesShowTimes obj) => obj.moviesShowTimes;

  static dynamic _$ghostShowTimes(gen2.MoviesShowTimes obj) => obj.ghostShowTimes;

  static dynamic _$fetchedFrom(gen2.MoviesShowTimes obj) => obj.fetchedFrom;

  static dynamic _$fetchedTo(gen2.MoviesShowTimes obj) => obj.fetchedTo;

  static List<dynamic> _values(gen2.MoviesShowTimes obj) => [obj.theaters, obj.moviesShowTimes, obj.ghostShowTimes, obj.fetchedFrom, obj.fetchedTo];

  static gen2.MoviesShowTimes _activator(List list) {
    return gen2.MoviesShowTimes(theaters: list[0], moviesShowTimes: list[1], ghostShowTimes: list[2], fetchedFrom: list[3], fetchedTo: list[4]);
  }
}

abstract class MoviesShowTimes$Copy {
  gen2.MoviesShowTimes call({
    gen0.List<gen1.Theater>? theaters,
    gen0.List<gen2.MovieShowTimes>? moviesShowTimes,
    gen0.List<gen2.TheaterShowTimes>? ghostShowTimes,
    gen0.DateTime? fetchedFrom,
    gen0.DateTime? fetchedTo,
  });
}

class MoviesShowTimesBuilder implements MoviesShowTimes$Copy {
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

  @override
  gen2.MoviesShowTimes call({Object? theaters = #sentinel, Object? moviesShowTimes = #sentinel, Object? ghostShowTimes = #sentinel, Object? fetchedFrom = #sentinel, Object? fetchedTo = #sentinel}) {
    if (theaters != #sentinel) {
      this.theaters = theaters as gen0.List<gen1.Theater>;
    }
    if (moviesShowTimes != #sentinel) {
      this.moviesShowTimes = moviesShowTimes as gen0.List<gen2.MovieShowTimes>;
    }
    if (ghostShowTimes != #sentinel) {
      this.ghostShowTimes = ghostShowTimes as gen0.List<gen2.TheaterShowTimes>;
    }
    if (fetchedFrom != #sentinel) {
      this.fetchedFrom = fetchedFrom as gen0.DateTime;
    }
    if (fetchedTo != #sentinel) {
      this.fetchedTo = fetchedTo as gen0.DateTime;
    }
    return build();
  }

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

  MoviesShowTimes$Copy get copy => toBuilder();
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
            gen.DogStructureField(gen.QualifiedTerminal<gen4.Movie>(), null, 'movie', false, true, []),
            gen.DogStructureField(
              gen.QualifiedTypeTreeN<gen0.List<gen2.TheaterShowTimes>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.TheaterShowTimes>()]),
              null,
              'theatersShowTimes',
              true,
              true,
              [],
            ),
          ],
          [gen3.serializable],
          gen.ObjectFactoryStructureProxy<gen2.MovieShowTimes>(_activator, [_$movie, _$theatersShowTimes], _values),
        ),
      );

  static dynamic _$movie(gen2.MovieShowTimes obj) => obj.movie;

  static dynamic _$theatersShowTimes(gen2.MovieShowTimes obj) => obj.theatersShowTimes;

  static List<dynamic> _values(gen2.MovieShowTimes obj) => [obj.movie, obj.theatersShowTimes];

  static gen2.MovieShowTimes _activator(List list) {
    return gen2.MovieShowTimes(list[0], theatersShowTimes: list[1]);
  }
}

abstract class MovieShowTimes$Copy {
  gen2.MovieShowTimes call({gen4.Movie? movie, gen0.List<gen2.TheaterShowTimes>? theatersShowTimes});
}

class MovieShowTimesBuilder implements MovieShowTimes$Copy {
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

  set movie(gen4.Movie value) {
    $values[0] = value;
  }

  gen4.Movie get movie => $values[0];

  set theatersShowTimes(gen0.List<gen2.TheaterShowTimes>? value) {
    $values[1] = value;
  }

  gen0.List<gen2.TheaterShowTimes>? get theatersShowTimes => $values[1];

  @override
  gen2.MovieShowTimes call({Object? movie = #sentinel, Object? theatersShowTimes = #sentinel}) {
    if (movie != #sentinel) {
      this.movie = movie as gen4.Movie;
    }
    if (theatersShowTimes != #sentinel) {
      this.theatersShowTimes = theatersShowTimes as gen0.List<gen2.TheaterShowTimes>?;
    }
    return build();
  }

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

  MovieShowTimes$Copy get copy => toBuilder();
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
            gen.DogStructureField(gen.QualifiedTerminal<gen1.Theater>(), null, 'theater', false, true, []),
            gen.DogStructureField(gen.QualifiedTypeTreeN<gen0.List<gen2.ShowTime>, gen0.List<dynamic>>([gen.QualifiedTerminal<gen2.ShowTime>()]), null, 'showTimes', true, true, []),
          ],
          [gen3.serializable],
          gen.ObjectFactoryStructureProxy<gen2.TheaterShowTimes>(_activator, [_$theater, _$showTimes], _values),
        ),
      );

  static dynamic _$theater(gen2.TheaterShowTimes obj) => obj.theater;

  static dynamic _$showTimes(gen2.TheaterShowTimes obj) => obj.showTimes;

  static List<dynamic> _values(gen2.TheaterShowTimes obj) => [obj.theater, obj.showTimes];

  static gen2.TheaterShowTimes _activator(List list) {
    return gen2.TheaterShowTimes(list[0], showTimes: list[1]);
  }
}

abstract class TheaterShowTimes$Copy {
  gen2.TheaterShowTimes call({gen1.Theater? theater, gen0.List<gen2.ShowTime>? showTimes});
}

class TheaterShowTimesBuilder implements TheaterShowTimes$Copy {
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

  @override
  gen2.TheaterShowTimes call({Object? theater = #sentinel, Object? showTimes = #sentinel}) {
    if (theater != #sentinel) {
      this.theater = theater as gen1.Theater;
    }
    if (showTimes != #sentinel) {
      this.showTimes = showTimes as gen0.List<gen2.ShowTime>?;
    }
    return build();
  }

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

  TheaterShowTimes$Copy get copy => toBuilder();
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
            gen.DogStructureField(gen.QualifiedTerminal<gen2.ShowVersion>(), null, 'version', false, true, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen2.ShowFormat>(), null, 'format', false, true, []),
          ],
          [gen3.serializable],
          gen.ObjectFactoryStructureProxy<gen2.ShowTimeSpec>(_activator, [_$version, _$format], _values),
        ),
      );

  static dynamic _$version(gen2.ShowTimeSpec obj) => obj.version;

  static dynamic _$format(gen2.ShowTimeSpec obj) => obj.format;

  static List<dynamic> _values(gen2.ShowTimeSpec obj) => [obj.version, obj.format];

  static gen2.ShowTimeSpec _activator(List list) {
    return gen2.ShowTimeSpec(version: list[0], format: list[1]);
  }
}

abstract class ShowTimeSpec$Copy {
  gen2.ShowTimeSpec call({gen2.ShowVersion? version, gen2.ShowFormat? format});
}

class ShowTimeSpecBuilder implements ShowTimeSpec$Copy {
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

  @override
  gen2.ShowTimeSpec call({Object? version = #sentinel, Object? format = #sentinel}) {
    if (version != #sentinel) {
      this.version = version as gen2.ShowVersion;
    }
    if (format != #sentinel) {
      this.format = format as gen2.ShowFormat;
    }
    return build();
  }

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

  ShowTimeSpec$Copy get copy => toBuilder();
  ShowTimeSpecBuilder toBuilder() {
    return ShowTimeSpecBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.ShowTimeSpec);
  }
}
