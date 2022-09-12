import 'dart:collection';

import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import '_models.dart';

class MoviesShowTimes {
  const MoviesShowTimes({required this.theaters, required this.moviesShowTimes, required this.fetchedFrom, required this.fetchedTo});

  final List<Theater> theaters;
  final List<MovieShowTimes> moviesShowTimes;
  final DateTime fetchedFrom;
  final DateTime fetchedTo;

  String get periodDisplay {
    var fetchedTo = this.fetchedTo;
    if(fetchedTo == fetchedTo.toDate) fetchedTo = fetchedTo.subtract(const Duration(minutes: 5));   // If [fetchedTo] is midnight, means it's excluded
    return 'Entre le ${fetchedFrom.day} et le ${fetchedTo.day}';
  }
}

class MovieShowTimes {
  MovieShowTimes(this.movie, {List<TheaterShowTimes>? theatersShowTimes}) :
    theatersShowTimes = theatersShowTimes ?? [];

  final Movie movie;
  final List<TheaterShowTimes> theatersShowTimes;

  List<ShowTimeSpec>? _showTimesSpecOptions;
  List<ShowTimeSpec> get showTimesSpecOptions {
    if (_showTimesSpecOptions == null) {
      // Build options set
      final options = <ShowTimeSpec>{};
      for (final theaterShowTimes in theatersShowTimes) {
        for (final showTime in theaterShowTimes.showTimes) {
          options.add(showTime.spec);
        }
      }

      // Sort list
      final optionList = options.toList(growable: false);
      optionList.sort((o1, o2) {
        final s1 = o1.toString();
        final s2 = o2.toString();

        // Compare length first
        final lengthComparison = s1.length.compareTo(s2.length);
        if (lengthComparison != 0) return lengthComparison;

        // Compare alpha
        return s2.compareTo(s1);
      });
      _showTimesSpecOptions = optionList;
    }
    return _showTimesSpecOptions!;
  }

  int compareTo(MovieShowTimes other, MovieSortType type) => movie.compareTo(other.movie, type);
}

class TheaterShowTimes {
  TheaterShowTimes(this.theater, { List<ShowTime>? showTimes }) :
    showTimes = showTimes ?? <ShowTime>[];

  /// Theater data
  final Theater theater;

  /// Unfiltered list of showtimes, sorted by date
  final List<ShowTime> showTimes;


  /// Simple cache for [daysWithShow]
  List<Date>? _daysWithShow;

  /// Get all date with a show, without duplicates, sorted.
  List<Date> get daysWithShow {
    return _daysWithShow ??= showTimes
        .map((s) => s.dateTime.toDate)
        .toSet()
        .toList(growable: false)
      ..sort();
  }

  /// Simple cache for [showTimesSummary]
  String? _showTimesSummary;

  /// Return a short summary of the next showtimes
  /// Examples :
  /// - 'Tous les jours'
  /// - 'Me Je Ve Sa Di'
  /// - 'Prochaine séance le Me 25 mars'
  String? get showTimesSummary {
    // Compute & cache value
    _showTimesSummary ??= () {
      final today = AppService.now.toDate;
      final nextWednesday = today.getNextWednesday();

      // If there are no date before next wednesday
      if (daysWithShow.first.isAfterOrSame(nextWednesday))
        return 'Prochaine séance le ${daysWithShow.first.toWeekdayString(withDay: true, withMonth: true)}';

      // Get all dates with a show before next wednesday
      final currentWeekShowTimes = daysWithShow.where((date) => date.isBefore(nextWednesday));

      // If dates are each days until next tuesday
      if (nextWednesday.difference(today).inDays == currentWeekShowTimes.length)
        return 'Tous les jours';

      // Fill a list of formatted weekday string
      final weekdaysString = currentWeekShowTimes.map((weekday) => weekday.toWeekdayString());

      // Return formatted line
      return weekdaysString.join(' ');
    } ();

    return _showTimesSummary;
  }

  /// Simple cache for [getFormattedShowTimes]
  final _formattedShowTimes = <ShowTimeSpec, List<DayShowTimes>>{};

  /// Sorted list of [DayShowTimes] for this [filter].
  /// With simple caching system.
  List<DayShowTimes> getFormattedShowTimes(ShowTimeSpec filter) {
    // Check cache
    var showTimesList = _formattedShowTimes[filter];

    // Compute value if needed
    if (showTimesList == null) {
      final filteredShowTimes = showTimes.where((showTime) => showTime.spec == filter).toList(growable: false);

      // List all different times
      final timesRef = filteredShowTimes
          .map((st) => st.dateTime.toTime)
          .toSet()
          .toList(growable: false)
        ..sort();

      // Build a map of <time reference, index>
      final timesRefMap = Map.fromIterables(timesRef, List.generate(timesRef.length, (index) => index));

      // Organise showtimes per day
      final showTimesMap = SplayTreeMap<Date, DayShowTimes>();
      for (final showTime in filteredShowTimes) {
        final date = showTime.dateTime.toDate;
        final time = showTime.dateTime.toTime;

        // Get day list or create it
        final showTimes = showTimesMap.putIfAbsent(date, () => DayShowTimes(date, List.filled(timesRef.length, null, growable: false)));

        // Set showTime at right index
        showTimes.showTimes[timesRefMap[time]!] = showTime;
      }

      // Save value to cache
      _formattedShowTimes[filter] = showTimesList = showTimesMap.values.toList(growable: false);
    }

    // Return value
    return showTimesList;
  }

  TheaterShowTimes copyWith({List<ShowTime>? showTimes}) => TheaterShowTimes(
    theater,
    showTimes: showTimes ?? this.showTimes,
  );
}

class DayShowTimes {
  const DayShowTimes(this.date, this.showTimes);

  /// Date
  final Date date;

  /// Showtimes list for this [day].
  /// Elements are aligned per time, so some may be null.
  final List<ShowTime?> showTimes;
}

enum ShowVersion { original, dubbed, local }
extension ExtendedShowVersion on ShowVersion {
  static const _versionMap = {
    ShowVersion.original: 'VO',
    ShowVersion.dubbed: 'VF',
    ShowVersion.local: 'VF',
  };

  String toDisplayString() => _versionMap[this]!;
}

// ignore: constant_identifier_names
enum ShowFormat { f2D, f3D, IMAX, IMAX_3D }
extension ExtendedShowFormat on ShowFormat {
  static const _formatMap = {
    ShowFormat.f2D: '',
    ShowFormat.f3D: '3D',
    ShowFormat.IMAX: 'IMAX',
    ShowFormat.IMAX_3D: 'IMAX 3D',
  };

  String toDisplayString() => _formatMap[this]!;
}

class ShowTime {
  const ShowTime(this.dateTime, {required this.spec});

  /// Date and Time
  final DateTime dateTime;

  /// Spec
  final ShowTimeSpec spec;
}

class ShowTimeSpec {
  const ShowTimeSpec({
    this.version = ShowVersion.original,
    this.format = ShowFormat.f2D,
  });

  final ShowVersion version;
  final ShowFormat format;

  @override
  String toString() => version.toDisplayString() + (format != ShowFormat.f2D ? ' ${format.toDisplayString()}' : '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ShowTimeSpec &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          format == other.format;

  @override
  int get hashCode => version.hashCode ^ format.hashCode;
}