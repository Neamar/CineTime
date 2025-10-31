import 'dart:collection';

import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import '_models.dart';

class MoviesShowTimes {
  const MoviesShowTimes({required this.theaters, required this.moviesShowTimes, required this.ghostShowTimes, required this.fetchedFrom, required this.fetchedTo});

  /// List of all theaters
  final List<Theater> theaters;

  /// List of movies, containing showtimes for each theater
  final List<MovieShowTimes> moviesShowTimes;

  /// List of ghost showtimes (showtimes without movie info), grouped by theater.
  final List<TheaterShowTimes> ghostShowTimes;

  /// Date from which showtimes were fetched
  final DateTime fetchedFrom;

  /// Date until which showtimes were fetched
  final DateTime fetchedTo;

  String get periodDisplay {
    var fetchedTo = this.fetchedTo;
    if(fetchedTo == fetchedTo.toDate) fetchedTo = fetchedTo.subtract(const Duration(minutes: 5));   // If [fetchedTo] is midnight, means it's excluded
    return 'Entre le ${fetchedFrom.day} et le ${fetchedTo.day}';
  }

  /// All dates with at least a show, without duplicates.
  Set<Date> get daysWithShow {
    final daysWithShow = <Date>{};
    for (final mst in moviesShowTimes) {
      for (final tst in mst.theatersShowTimes) {
        daysWithShow.addAll(tst.daysWithShow);
      }
    }
    return daysWithShow;
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


  /// Simple cache for [filteredShowTimes]
  final _filteredShowTimes = <ShowTimeSpec, List<ShowTime>>{};

  /// Return showtimes filtered by [spec]
  List<ShowTime> getFilteredShowTimes(ShowTimeSpec spec) => _filteredShowTimes.putIfAbsent(spec, () => showTimes.where((st) => st.spec == spec).toList(growable: false));


  /// Simple cache for [daysWithShow]
  SplayTreeSet<Date>? _daysWithShow;

  /// All dates with at least a show, without duplicates, sorted.
  SplayTreeSet<Date> get daysWithShow => _daysWithShow ??= showTimes.daysWithShow;


  /// Simple cache for [filteredDayWithShow]
  final _filteredDayWithShow = <ShowTimeSpec, SplayTreeSet<Date>>{};

  /// All dates with at least a show, filtered by [spec], without duplicates, sorted.
  SplayTreeSet<Date> getFilteredDayWithShow(ShowTimeSpec spec) => _filteredDayWithShow.putIfAbsent(spec, () => getFilteredShowTimes(spec).daysWithShow);


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

  TheaterShowTimes copyWith({List<ShowTime>? showTimes}) => TheaterShowTimes(
    theater,
    showTimes: showTimes ?? this.showTimes,
  );
}

extension ExtendedShowTimeList on List<ShowTime> {
  /// All dates with at least a show, without duplicates, sorted.
  SplayTreeSet<Date> get daysWithShow => SplayTreeSet.of(map((s) => s.dateTime.toDate));
}

class DayShowTimes {
  const DayShowTimes(this.date, this.showTimes);

  /// Date
  final Date date;

  /// Showtimes list for this [day].
  /// Elements are aligned per time, so some may be null.
  final List<ShowTime?> showTimes;
}

enum ShowVersion {
  original('VOST'),   // Version originale (pas français) sous-titrée français
  dubbed('VF'),       // Version voix française (sous-titrée français si la langue du film est en français)
  local('VF');        // Version française sans sous-titre

  const ShowVersion(this.label);

  final String label;
}

enum ShowFormat {
  f2D(''),
  f3D('3D'),
  // ignore: constant_identifier_names
  IMAX('IMAX'),
  // ignore: constant_identifier_names
  IMAX_3D('IMAX 3D');

  const ShowFormat(this.label);

  final String label;
}

class ShowTime {
  const ShowTime(this.dateTime, {required this.spec, this.ticketingUrl});

  /// Date and Time
  final DateTime dateTime;

  /// Spec
  final ShowTimeSpec spec;

  /// Ticketing/booking URL
  final String? ticketingUrl;
}

class ShowTimeSpec {
  const ShowTimeSpec({
    this.version = ShowVersion.original,
    this.format = ShowFormat.f2D,
  });

  final ShowVersion version;
  final ShowFormat format;

  String toDisplayString(bool isMovieFrench) {
    String label = version.label;
    if (version == ShowVersion.dubbed && isMovieFrench) label += 'ST';
    if (format != ShowFormat.f2D) label += ' ${format.label}';
    return label;
  }

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
