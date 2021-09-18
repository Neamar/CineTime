import 'dart:collection';

import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/utils/_utils.dart';
import '_models.dart';

class MoviesShowTimes {
  final bool? fromCache;
  final List<MovieShowTimes>? moviesShowTimes;
  final DateTime? fetchedAt;

  const MoviesShowTimes({this.fetchedAt, this.fromCache, this.moviesShowTimes});
}

class MovieShowTimes {
  MovieShowTimes(this.movie, {List<TheaterShowTimes>? theatersShowTimes}) :
    this.theatersShowTimes = theatersShowTimes ?? [];

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

  // OPTI use basic cache system ?
  String toFullString() {
    final lines = <String?>[];

    // Movie name
    lines.add("Séances pour '${movie.title}'");

    // For each theater
    for (final theaterShowTimes in theatersShowTimes) {
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
}

typedef FormattedShowTimes = SplayTreeMap<Date, List<ShowTime?>>;

class TheaterShowTimes {
  TheaterShowTimes(this.theater, { List<ShowTime>? showTimes }) :
    this.showTimes = showTimes ?? <ShowTime>[];

  /// Theater data
  final Theater theater;

  /// List of showtimes, sorted by date
  final List<ShowTime> showTimes;

  /// Simple cache for [showTimesSummary]
  String? _showTimesSummary;

  /// Return a short summary of the next showtimes
  /// Examples :
  /// - 'Me Je Ve Sa Di'
  /// - 'Prochaine séance le Me 25 mars'
  String? get showTimesSummary {
    if (_showTimesSummary == null) {
      final now = ApiClient.mockedNow;
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

  /// Formatted & sorted map of showtimes, where keys are the day.
  /// All showtimes elements in lists are aligned per time.
  FormattedShowTimes getFormattedShowTimes(ShowTimeSpec filter) {
    const aligned = true;
    final filteredShowTimes = showTimes.where((showTime) => showTime.spec == filter).toList(growable: false);
    final showTimesMap = FormattedShowTimes();

    // Unaligned, simple version
    if (!aligned) {
      for (final showTime in filteredShowTimes) {
        final date = showTime.dateTime!.toDate;
        final st = showTimesMap.putIfAbsent(date, () => []);
        st.add(showTime);
      }
    }

    // Aligned version
    else {
      // List all unique times
      final timesRef = filteredShowTimes
          .map((st) => st.dateTime!.toTime)
          .toSet()
          .toList(growable: false)
        ..sort();
      final timesRefMap = Map.fromIterables(timesRef, List.generate(timesRef.length, (index) => index));

      // Build map
      for (final showTime in filteredShowTimes) {
        final date = showTime.dateTime!.toDate;
        final time = showTime.dateTime!.toTime;

        // Get day list or create it
        final showTimes = showTimesMap.putIfAbsent(date, () => List.filled(timesRef.length, null, growable: false));

        // Insert showTime at right index
        showTimes[timesRefMap[time]!] = showTime;
      }
    }

    return showTimesMap;
  }

  TheaterShowTimes copyWith({List<ShowTime>? showTimes}) => TheaterShowTimes(
    theater,
    showTimes: showTimes ?? this.showTimes,
  );
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
  final DateTime? dateTime;

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