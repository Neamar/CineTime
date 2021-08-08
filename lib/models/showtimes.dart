import 'dart:collection';

import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/services/web_services.dart';
import 'package:cinetime/helpers/tools.dart';
import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'showtimes.g.dart';

@JsonSerializable()
class MoviesShowTimes {
  final bool fromCache;
  final List<MovieShowTimes> moviesShowTimes;

  @JsonKey(fromJson: StorageService.dateFromString, toJson: StorageService.dateToString)
  final DateTime fetchedAt;

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

  MovieShowTimes(this.movie, {Iterable<TheaterShowTimes> theatersShowTimes, Iterable<TheaterShowTimes> filteredTheatersShowTimes}) :
    this.theatersShowTimes = theatersShowTimes ?? <TheaterShowTimes>[],
    this.filteredTheatersShowTimes = filteredTheatersShowTimes ?? <TheaterShowTimes>[];

  String toFullString(bool applyFilters) {
    final lines = <String>[];

    // Movie name
    lines.add("Séances pour '${movie.title}'");

    // For each theater
    for (final theaterShowTimes in getTheatersShowTimesDisplay(applyFilters == true)) {
      // Separator
      lines.add('');

      // Theater's name
      lines.add(theaterShowTimes.theater.name);

      lines.add('TODO');    // TODO
      /* TODO
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

  TheaterShowTimes(this.theater, { List<ShowTime> showTimes }) :
    this.showTimes = showTimes ?? <ShowTime>[];

  /// Simple cache for [showTimesSummary]
  String _showTimesSummary;

  /// Return a short summary of the next showtimes
  /// Examples :
  /// - 'Me Je Ve Sa Di'
  /// - 'Prochaine séance le Me 25 mars'
  String get showTimesSummary {
    if (_showTimesSummary == null) {
      final now = WebServices.mockedNow;
      final nextWednesday = now.getNextWednesday();

      // Get all date with a show, from [now], without duplicates, sorted.
      final daysWithShow = showTimes
        .where((s) => s.dateTime.isAfter(now))     //TODO use https://github.com/jogboms/time.dart (for all project)
        .map((s) => s.dateTime.toDate)
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
  SplayTreeMap<Date, List<ShowTime>> _showTimesMap;

  /// Formatted & sorted map of showtimes, where keys are the day.
  /// All showtimes elements in lists are aligned per time.
  SplayTreeMap<Date, List<ShowTime>> get formattedShowTimes {
    if (_showTimesMap == null) {
      const aligned = true;
      _showTimesMap = SplayTreeMap();

      // Unaligned, simple version
      if (!aligned) {
        for (final showTime in showTimes) {
          final date = showTime.dateTime.toDate;
          final st = _showTimesMap.putIfAbsent(date, () => []);
          st.add(showTime);
        }
      }

      // Aligned version
      else {
        // List all unique times
        final timesRef = showTimes
            .map((st) => st.dateTime.toTime)
            .toSet()
            .toList(growable: false)
          ..sort();
        final timesRefMap = Map.fromIterables(timesRef, List.generate(timesRef.length, (index) => index));

        // Build map
        for (final showTime in showTimes) {
          final date = showTime.dateTime.toDate;
          final time = showTime.dateTime.toTime;

          // Get day list or create it
          final showTimes = _showTimesMap.putIfAbsent(date, () => List.filled(timesRef.length, null, growable: false));

          // Insert showTime at right index
          showTimes[timesRefMap[time]] = showTime;
        }
      }
    }

    return _showTimesMap;
  }

  TheaterShowTimes copyWith({List<ShowTime> showTimes}) => TheaterShowTimes(
    theater,
    showTimes: showTimes ?? this.showTimes,
  );

  factory TheaterShowTimes.fromJson(Map<String, dynamic> json) => _$TheaterShowTimesFromJson(json);
  Map<String, dynamic> toJson() => _$TheaterShowTimesToJson(this);
}

@JsonSerializable()
class RoomShowTimes {
  final String screen;    // Theater room name
  final int seatCount;    // Theater room seat capacity
  final bool isOriginalLanguage;
  final bool is3D;
  final bool isIMAX;

  final List<DateTime> showTimesRaw;    // Sorted list of DateTime

  const RoomShowTimes({this.screen, this.seatCount, this.isOriginalLanguage, bool is3D, bool isIMAX, this.showTimesRaw}) :
    this.is3D = is3D ?? false,
    this.isIMAX = isIMAX ?? false;

  List<String> get tags => [
    isOriginalLanguage == true ? 'VO' : 'VF',
    if (is3D) '3D',
    if (isIMAX) 'IMAX',
  ];

  /// Return List<List<String>> to build a grid like this :
  /// {
  ///    Me Je :                     13:35  15:40  17:45
  ///    Ve :                 10:50  13:35  15:40
  ///    Tous les jours :     10:50  13:35  15:40  17:45
  /// }
  ///
  /// First list is lines.
  /// See toShortWeekdaysString() doc for more info
  ///
  List<List<String>> get showTimesDisplay {    //TODO handle simple cache
    //TODO separate next week and after (multiple lines)

    // Build a Map<Date, Set<Time>> : one list of Time per Date
    var datesShowTimes = Map<Date, Set<Time>>();
    for (var showTime in showTimesRaw) {
      final date = showTime.toDate;
      final time = showTime.toTime;

      final dateShowTimes = datesShowTimes.putIfAbsent(date, () => Set<Time>());
      dateShowTimes.add(time);
    }

    // List of coupled Dates and Times
    final showTimesList = <ShowTimes>[];

    // Group dates that have the exact same times
    for (var dateShowTimesEntry in datesShowTimes.entries) {
      // Get day list with exact same times
      // TODO force grouping if missing times are passed (Exemple : we are wednesday 11h, ignore showtime before 11h when grouping)
      final showTimes = showTimesList.firstWhere((showTimes) => dateShowTimesEntry.value.containsSame(showTimes.times), orElse: () => null);
      if (showTimes != null)
        showTimes.dates.add(dateShowTimesEntry.key);
      else
        showTimesList.add(ShowTimes(Set.from([dateShowTimesEntry.key]), dateShowTimesEntry.value));
    }

    // Build the header
    final timesHeader = datesShowTimes.values
        .expand((times) => times)
        .toSet()
        .toList(growable: false)
      ..sort();

    final columnCount = 1 + timesHeader.length;

    // Build the double list of formatted strings
    final lines = List<List<String>>.filled(showTimesList.length, null, growable: false);
    for (var y = 0; y < showTimesList.length; y++) {
      final showTime = showTimesList[y];
      final cells = List<String>.filled(columnCount, null, growable: false);
      cells[0] = showTime.datesDisplay;

      for (var x = 1; x < columnCount; x ++) {
        final timeHeader = timesHeader[x - 1];
        cells[x] = showTime.times.contains(timeHeader) ? timeHeader.toString() : null;
      }

      lines[y] = cells;
    }

    // Return formatted double list
    return lines;
  }

  RoomShowTimes copyWith({List<DateTime> showTimesRaw}) => RoomShowTimes(
    screen: screen,
    seatCount: seatCount,
    isOriginalLanguage: isOriginalLanguage,
    is3D: is3D,
    isIMAX: isIMAX,
    showTimesRaw: showTimesRaw ?? this.showTimesRaw,
  );

  factory RoomShowTimes.fromJson(Map<String, dynamic> json) => _$RoomShowTimesFromJson(json);
  Map<String, dynamic> toJson() => _$RoomShowTimesToJson(this);
}

class ShowTimes {
  final Set<Date> dates;
  final Set<Time> times;

  const ShowTimes(this.dates, this.times);

  String get datesDisplay => dates.toShortWeekdaysString(WebServices.mockedNow);
  String get timesDisplay => times.map((time) => time.toString()).join('  ');
}

@JsonSerializable()
class ShowTime {
  const ShowTime(this.dateTime, { this.screen, this.seatCount, this.tags });

  /// Date and Time
  final DateTime dateTime;

  /// Theater room name
  final String screen;

  /// Theater room seat capacity
  final int seatCount;

  /// Specs
  /// Can be ('VO' or 'VF'), '3D', 'IMAX'
  final List<String> tags;

  factory ShowTime.fromJson(Map<String, dynamic> json) => _$ShowTimeFromJson(json);
  Map<String, dynamic> toJson() => _$ShowTimeToJson(this);
}