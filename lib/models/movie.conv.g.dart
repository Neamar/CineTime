// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, unnecessary_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'dart:core';
import 'package:dogs_core/dogs_core.dart' as gen;
import 'package:lyell/lyell.dart' as gen;
import 'package:cinetime/models/api_id.dart' as gen0;
import 'dart:core' as gen1;
import 'package:cinetime/models/movie.dart' as gen2;
import 'package:dogs_core/src/annotations.dart' as gen3;
import 'package:cinetime/models/movie.dart';

class MovieConverter extends gen.DefaultStructureConverter<gen2.Movie> {
  MovieConverter()
    : super(
        struct: const gen.DogStructure<gen2.Movie>(
          'Movie',
          gen.StructureConformity.basic,
          [
            gen.DogStructureField(gen.QualifiedTerminal<gen0.ApiId>(), null, 'id', false, true, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'title', false, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'poster', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.DateTime>(), null, 'releaseDate', true, true, []),
            gen.DogStructureField(gen.QualifiedTypeTreeN<gen1.List<gen1.String>, gen1.List<dynamic>>([gen.QualifiedTerminal<gen1.String>()]), null, 'languages', false, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen0.ApiId>(), null, 'trailerId', true, true, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'directors', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'actors', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'genres', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'synopsis', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.String>(), null, 'durationDisplay', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.double>(), null, 'usersRating', true, false, []),
            gen.DogStructureField(gen.QualifiedTerminal<gen1.double>(), null, 'pressRating', true, false, []),
          ],
          [gen3.serializable],
          gen.ObjectFactoryStructureProxy<gen2.Movie>(_activator, [
            _$id,
            _$title,
            _$poster,
            _$releaseDate,
            _$languages,
            _$trailerId,
            _$directors,
            _$actors,
            _$genres,
            _$synopsis,
            _$durationDisplay,
            _$usersRating,
            _$pressRating,
          ], _values),
        ),
      );

  static dynamic _$id(gen2.Movie obj) => obj.id;

  static dynamic _$title(gen2.Movie obj) => obj.title;

  static dynamic _$poster(gen2.Movie obj) => obj.poster;

  static dynamic _$releaseDate(gen2.Movie obj) => obj.releaseDate;

  static dynamic _$languages(gen2.Movie obj) => obj.languages;

  static dynamic _$trailerId(gen2.Movie obj) => obj.trailerId;

  static dynamic _$directors(gen2.Movie obj) => obj.directors;

  static dynamic _$actors(gen2.Movie obj) => obj.actors;

  static dynamic _$genres(gen2.Movie obj) => obj.genres;

  static dynamic _$synopsis(gen2.Movie obj) => obj.synopsis;

  static dynamic _$durationDisplay(gen2.Movie obj) => obj.durationDisplay;

  static dynamic _$usersRating(gen2.Movie obj) => obj.usersRating;

  static dynamic _$pressRating(gen2.Movie obj) => obj.pressRating;

  static List<dynamic> _values(gen2.Movie obj) => [
    obj.id,
    obj.title,
    obj.poster,
    obj.releaseDate,
    obj.languages,
    obj.trailerId,
    obj.directors,
    obj.actors,
    obj.genres,
    obj.synopsis,
    obj.durationDisplay,
    obj.usersRating,
    obj.pressRating,
  ];

  static gen2.Movie _activator(List list) {
    return gen2.Movie(
      id: list[0],
      title: list[1],
      poster: list[2],
      releaseDate: list[3],
      languages: list[4],
      trailerId: list[5],
      directors: list[6],
      actors: list[7],
      genres: list[8],
      synopsis: list[9],
      durationDisplay: list[10],
      usersRating: list[11],
      pressRating: list[12],
    );
  }
}

abstract class Movie$Copy {
  gen2.Movie call({
    gen0.ApiId? id,
    gen1.String? title,
    gen1.String? poster,
    gen1.DateTime? releaseDate,
    gen1.List<gen1.String>? languages,
    gen0.ApiId? trailerId,
    gen1.String? directors,
    gen1.String? actors,
    gen1.String? genres,
    gen1.String? synopsis,
    gen1.String? durationDisplay,
    gen1.double? usersRating,
    gen1.double? pressRating,
  });
}

class MovieBuilder implements Movie$Copy {
  MovieBuilder([gen2.Movie? $src]) {
    if ($src == null) {
      $values = List.filled(13, null);
    } else {
      $values = MovieConverter._values($src);
      this.$src = $src;
    }
  }

  late List<dynamic> $values;

  gen2.Movie? $src;

  set id(gen0.ApiId value) {
    $values[0] = value;
  }

  gen0.ApiId get id => $values[0];

  set title(gen1.String value) {
    $values[1] = value;
  }

  gen1.String get title => $values[1];

  set poster(gen1.String? value) {
    $values[2] = value;
  }

  gen1.String? get poster => $values[2];

  set releaseDate(gen1.DateTime? value) {
    $values[3] = value;
  }

  gen1.DateTime? get releaseDate => $values[3];

  set languages(gen1.List<gen1.String> value) {
    $values[4] = value;
  }

  gen1.List<gen1.String> get languages => $values[4];

  set trailerId(gen0.ApiId? value) {
    $values[5] = value;
  }

  gen0.ApiId? get trailerId => $values[5];

  set directors(gen1.String? value) {
    $values[6] = value;
  }

  gen1.String? get directors => $values[6];

  set actors(gen1.String? value) {
    $values[7] = value;
  }

  gen1.String? get actors => $values[7];

  set genres(gen1.String? value) {
    $values[8] = value;
  }

  gen1.String? get genres => $values[8];

  set synopsis(gen1.String? value) {
    $values[9] = value;
  }

  gen1.String? get synopsis => $values[9];

  set durationDisplay(gen1.String? value) {
    $values[10] = value;
  }

  gen1.String? get durationDisplay => $values[10];

  set usersRating(gen1.double? value) {
    $values[11] = value;
  }

  gen1.double? get usersRating => $values[11];

  set pressRating(gen1.double? value) {
    $values[12] = value;
  }

  gen1.double? get pressRating => $values[12];

  @override
  gen2.Movie call({
    Object? id = #sentinel,
    Object? title = #sentinel,
    Object? poster = #sentinel,
    Object? releaseDate = #sentinel,
    Object? languages = #sentinel,
    Object? trailerId = #sentinel,
    Object? directors = #sentinel,
    Object? actors = #sentinel,
    Object? genres = #sentinel,
    Object? synopsis = #sentinel,
    Object? durationDisplay = #sentinel,
    Object? usersRating = #sentinel,
    Object? pressRating = #sentinel,
  }) {
    if (id != #sentinel) {
      this.id = id as gen0.ApiId;
    }
    if (title != #sentinel) {
      this.title = title as gen1.String;
    }
    if (poster != #sentinel) {
      this.poster = poster as gen1.String?;
    }
    if (releaseDate != #sentinel) {
      this.releaseDate = releaseDate as gen1.DateTime?;
    }
    if (languages != #sentinel) {
      this.languages = languages as gen1.List<gen1.String>;
    }
    if (trailerId != #sentinel) {
      this.trailerId = trailerId as gen0.ApiId?;
    }
    if (directors != #sentinel) {
      this.directors = directors as gen1.String?;
    }
    if (actors != #sentinel) {
      this.actors = actors as gen1.String?;
    }
    if (genres != #sentinel) {
      this.genres = genres as gen1.String?;
    }
    if (synopsis != #sentinel) {
      this.synopsis = synopsis as gen1.String?;
    }
    if (durationDisplay != #sentinel) {
      this.durationDisplay = durationDisplay as gen1.String?;
    }
    if (usersRating != #sentinel) {
      this.usersRating = usersRating as gen1.double?;
    }
    if (pressRating != #sentinel) {
      this.pressRating = pressRating as gen1.double?;
    }
    return build();
  }

  gen2.Movie build() {
    var instance = MovieConverter._activator($values);

    return instance;
  }
}

extension MovieDogsExtension on gen2.Movie {
  gen2.Movie rebuild(Function(MovieBuilder b) f) {
    var builder = MovieBuilder(this);
    f(builder);
    return builder.build();
  }

  Movie$Copy get copy => toBuilder();
  MovieBuilder toBuilder() {
    return MovieBuilder(this);
  }

  Map<String, dynamic> toNative() {
    return gen.dogs.convertObjectToNative(this, gen2.Movie);
  }
}
