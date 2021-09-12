import 'dart:collection';

import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/services/web_services.dart';
import 'package:cinetime/helpers/tools.dart';
import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'showtimes.g.dart';

@JsonSerializable()
class MoviesShowTimes {
  final bool? fromCache;
  final List<MovieShowTimes>? moviesShowTimes;

  @JsonKey(fromJson: StorageService.dateFromString, toJson: StorageService.dateToString)
  final DateTime? fetchedAt;

  const MoviesShowTimes({this.fetchedAt, this.fromCache, this.moviesShowTimes});

  factory MoviesShowTimes.fromJson(Map<String, dynamic> json) => _$MoviesShowTimesFromJson(json);
  Map<String, dynamic> toJson() => _$MoviesShowTimesToJson(this);
}

@JsonSerializable()
class MovieShowTimes {
  final Movie movie;
  final List<TheaterShowTimes> theatersShowTimes;
  final List<TheaterShowTimes> filteredTheatersShowTimes;
  List<TheaterShowTimes> getTheatersShowTimesDisplay(bool applyFilter) =>
    applyFilter == true && filteredTheatersShowTimes.isNotEmpty
      ? filteredTheatersShowTimes
      : theatersShowTimes;

  MovieShowTimes(this.movie, {Iterable<TheaterShowTimes>? theatersShowTimes, Iterable<TheaterShowTimes>? filteredTheatersShowTimes}) :
    this.theatersShowTimes = theatersShowTimes as List<TheaterShowTimes>? ?? <TheaterShowTimes>[],
    this.filteredTheatersShowTimes = filteredTheatersShowTimes as List<TheaterShowTimes>? ?? <TheaterShowTimes>[];

  String toFullString(bool applyFilters) {
    final lines = <String?>[];

    // Movie name
    lines.add("Séances pour '${movie.title}'");

    // For each theater
    for (final theaterShowTimes in getTheatersShowTimesDisplay(applyFilters == true)) {
      // Separator
      lines.add('');

      // Theater's name
      lines.add(theaterShowTimes.theater.name);

      lines.add('TODO');    // TODO
      /*
      // For each room
      for (final roomsShowTimes in theaterShowTimes.roomsShowTimes) {
        final roomShowTimes = roomsShowTimes.showTimesDisplay;
        final header = "[${roomsShowTimes.tags.join(' ')}] ";

        // for each ShowTimes
        for (final showTimes in roomShowTimes)
          lines.add(header + showTimes.where((s) => s != null).join(' '));
      }*/
    }

    // Return formatted string
    return lines.join('\n');
  }

  factory MovieShowTimes.fromJson(Map<String, dynamic> json) => _$MovieShowTimesFromJson(json);
  Map<String, dynamic> toJson() => _$MovieShowTimesToJson(this);
}

@JsonSerializable()
class TheaterShowTimes {
  /// Theater data
  final Theater theater;

  /// List of showtimes, sorted by date
  final List<ShowTime> showTimes;

  TheaterShowTimes(this.theater, { List<ShowTime>? showTimes }) :
    this.showTimes = showTimes ?? <ShowTime>[];

  /// Simple cache for [showTimesSummary]
  String? _showTimesSummary;

  /// Return a short summary of the next showtimes
  /// Examples :
  /// - 'Me Je Ve Sa Di'
  /// - 'Prochaine séance le Me 25 mars'
  String? get showTimesSummary {
    if (_showTimesSummary == null) {
      final now = WebServices.mockedNow;
      final nextWednesday = now.getNextWednesday();

      // Get all date with a show, from [now], without duplicates, sorted.
      final daysWithShow = showTimes
        .where((s) => s.dateTime!.isAfter(now))     //TODO use https://github.com/jogboms/time.dart (for all project)
        .map((s) => s.dateTime!.toDate)
        .toSet()
        .toList(growable: false)
      ..sort();

      // If there are no date before next wednesday
      if (daysWithShow.first.isAfter(nextWednesday))
        return 'Prochaine séance le ${daysWithShow.first.toWeekdayString(withDay: true, withMonth: true)}';

      // Get all dates with a show before next wednesday
      final currentWeekShowTimes = daysWithShow.where((date) => date.isBefore(nextWednesday));

      // Format string & cache data
      _showTimesSummary = currentWeekShowTimes.toShortWeekdaysString(now);
    }

    return _showTimesSummary;
  }

  /// Simple cache for [formattedShowTimes]
  SplayTreeMap<Date, List<ShowTime?>>? _showTimesMap;

  /// Formatted & sorted map of showtimes, where keys are the day.
  /// All showtimes elements in lists are aligned per time.
  SplayTreeMap<Date, List<ShowTime?>>? get formattedShowTimes {
    if (_showTimesMap == null) {
      const aligned = true;
      _showTimesMap = SplayTreeMap();

      // Unaligned, simple version
      if (!aligned) {
        for (final showTime in showTimes) {
          final date = showTime.dateTime!.toDate;
          final st = _showTimesMap!.putIfAbsent(date, () => []);
          st.add(showTime);
        }
      }

      // Aligned version
      else {
        // List all unique times
        final timesRef = showTimes
            .map((st) => st.dateTime!.toTime)
            .toSet()
            .toList(growable: false)
          ..sort();
        final timesRefMap = Map.fromIterables(timesRef, List.generate(timesRef.length, (index) => index));

        // Build map
        for (final showTime in showTimes) {
          final date = showTime.dateTime!.toDate;
          final time = showTime.dateTime!.toTime;

          // Get day list or create it
          final showTimes = _showTimesMap!.putIfAbsent(date, () => List.filled(timesRef.length, null, growable: false));

          // Insert showTime at right index
          showTimes[timesRefMap[time]!] = showTime;
        }
      }
    }

    return _showTimesMap;
  }

  TheaterShowTimes copyWith({List<ShowTime>? showTimes}) => TheaterShowTimes(
    theater,
    showTimes: showTimes ?? this.showTimes,
  );

  factory TheaterShowTimes.fromJson(Map<String, dynamic> json) => _$TheaterShowTimesFromJson(json);
  Map<String, dynamic> toJson() => _$TheaterShowTimesToJson(this);
}

@JsonSerializable()
class ShowTime {
  const ShowTime(this.dateTime, { this.screen, this.seatCount, List<String>? tags }) : tags = tags ?? const <String>[];

  /// Date and Time
  final DateTime? dateTime;

  /// Theater room name
  final String? screen;

  /// Theater room seat capacity
  final int? seatCount;

  /// Specs
  /// Can be ('VO' or 'VF'), '3D', 'IMAX'
  final List<String> tags;

  factory ShowTime.fromJson(Map<String, dynamic> json) => _$ShowTimeFromJson(json);
  Map<String, dynamic> toJson() => _$ShowTimeToJson(this);
}