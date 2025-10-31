// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, unnecessary_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'package:cinetime/models/api_id.dart';
import 'package:cinetime/models/movie.conv.g.dart';
import 'package:cinetime/models/showtimes.conv.g.dart';
import 'package:cinetime/models/theater.conv.g.dart';
import 'package:dogs_core/dogs_core.dart';
import 'package:cinetime/models/api_id.dart' as gen0;
import 'package:cinetime/models/movie.conv.g.dart' as gen1;
import 'package:cinetime/models/showtimes.conv.g.dart' as gen2;
import 'package:cinetime/models/theater.conv.g.dart' as gen3;
export 'package:cinetime/models/api_id.dart';
export 'package:cinetime/models/movie.conv.g.dart';
export 'package:cinetime/models/showtimes.conv.g.dart';
export 'package:cinetime/models/theater.conv.g.dart';

DogPlugin GeneratedModelsPlugin() => (engine) {
  engine.linkAll([
    gen0.ApiIdConverter(),
    gen1.MovieConverter(),
    gen2.MoviesShowTimesConverter(),
    gen2.MovieShowTimesConverter(),
    gen2.TheaterShowTimesConverter(),
    gen2.ShowTimeSpecConverter(),
    gen3.TheaterConverter(),
  ]);
};
