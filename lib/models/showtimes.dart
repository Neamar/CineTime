import 'dart:collection';

import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import '_models.dart';

class MoviesShowTimes {
  MoviesShowTimes({required this.theaters, required this.moviesShowTimes, required this.ghostShowTimes, required this.fetchedFrom, required this.fetchedTo});

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

  late final String periodDisplay = () {
    var fetchedTo = this.fetchedTo;
    if(fetchedTo == fetchedTo.toDate) fetchedTo = fetchedTo.subtract(const Duration(minutes: 5));   // If [fetchedTo] is midnight, means it's excluded
    return 'Entre le ${fetchedFrom.day} et le ${fetchedTo.day}';
  } ();

  /// All dates with at least a show, without duplicates.
  late final Set<Date> daysWithShow = () {
    final daysWithShow = <Date>{};
    for (final mst in moviesShowTimes) {
      for (final tst in mst.theatersShowTimes) {
        daysWithShow.addAll(tst.daysWithShow);
      }
    }
    return daysWithShow;
  } ();
}

class MovieShowTimes {
  MovieShowTimes(this.movie, {List<TheaterShowTimes>? theatersShowTimes}) :
    theatersShowTimes = theatersShowTimes ?? [];

  final Movie movie;
  final List<TheaterShowTimes> theatersShowTimes;

  /// Lazily computed & cached list of all showtimes specs, sorted.
  late final List<ShowTimeSpec> showTimesSpecOptions = () {
    final options = SplayTreeSet<ShowTimeSpec>((s1, s2) => s1.compareTo(s2));
    for (final theaterShowTimes in theatersShowTimes) {
      for (final showTime in theaterShowTimes.showTimes) {
        options.add(showTime.spec);
      }
    }
    return options.toList(growable: false);
  } ();

  /// [showTimesSpecOptions] grouped by audio version + subtitles (keys have no technology), order preserved.
  late final Map<ShowTimeSpec, List<ShowTimeSpec>> showTimesSpecOptionsByAudioSubtitles =
      showTimesSpecOptions.groupListsBy((spec) => spec.withoutTechnology);

  /// Total number of showtimes across all theaters, whatever their spec.
  late final int showTimesCount = theatersShowTimes.map((tst) => tst.showTimes.length).sum;

  /// Number of showtimes across all theaters matching [spec].
  int getFilteredShowTimesCount(ShowTimeSpec spec) => theatersShowTimes.map((tst) => tst.getFilteredShowTimes(spec).length).sum;

  /// The earliest upcoming showtime date across all theaters.
  late final DateTime? nextShowDate = theatersShowTimes
    .map((tst) => tst.showTimes.firstOrNull?.dateTime)
    .nonNulls
    .minOrNull;

  int compareTo(MovieShowTimes other, MovieSortType type) {
    if (type == MovieSortType.nextShow) {
      final d1 = nextShowDate;
      final d2 = other.nextShowDate;
      if (d1 != null && d2 != null) return d1.compareTo(d2);
      if (d1 != null) return -1;  // this has a show, other doesn't → sort first
      if (d2 != null) return 1;   // other has a show, this doesn't → sort last
    }
    return movie.compareTo(other.movie, type);
  }
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


  /// All dates with at least a show, without duplicates, sorted.
  late final SplayTreeSet<Date> daysWithShow = showTimes.daysWithShow;


  /// Simple cache for [filteredDayWithShow]
  final _filteredDayWithShow = <ShowTimeSpec, SplayTreeSet<Date>>{};

  /// All dates with at least a show, filtered by [spec], without duplicates, sorted.
  SplayTreeSet<Date> getFilteredDayWithShow(ShowTimeSpec spec) => _filteredDayWithShow.putIfAbsent(spec, () => getFilteredShowTimes(spec).daysWithShow);


  /// Return a short summary of the next showtimes
  /// Examples :
  /// - 'Tous les jours'
  /// - 'Me Je Ve Sa Di'
  /// - 'Prochaine séance le Me 25 mars'
  late final String showTimesSummary = () {
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

class ShowTime {
  const ShowTime(this.dateTime, {required this.spec, this.ticketingUrl});

  /// Date and Time
  final DateTime dateTime;

  /// Spec
  final ShowTimeSpec spec;

  /// Ticketing/booking URL
  final String? ticketingUrl;
}

class ShowTimeSpec implements Comparable<ShowTimeSpec> {
  const ShowTimeSpec({
    required this.audioVersion,
    this.subtitles = const {},
    this.technology,
  });

  // Audio version
  final ShowAudioVersion audioVersion;

  /// Subtitles
  final Set<ShowSubtitles> subtitles;

  /// Technology, already formatted for display.
  /// Examples: 3D, IMAX, IMAX 3D, LaserUltra, 4DX 3D, ...
  final String? technology;

  /// This spec without its technology, to group specs by audio version + subtitles.
  ShowTimeSpec get withoutTechnology => ShowTimeSpec(audioVersion: audioVersion, subtitles: subtitles);

  /// Build a display-ready technology string from raw source tokens (HTML classes, JSON tags, ...).
  /// Tokens are deduplicated (order preserved), joined with a space, with "3D" always placed last (e.g. "IMAX 3D", "4DX 3D").
  static String? formatTechnology(Iterable<String> tokens) {
    final unique = LinkedHashSet<String>.of(tokens.where((t) => t.isNotEmpty));
    if (unique.isEmpty) return null;
    final has3D = unique.remove('3D');
    return [...unique, if (has3D) '3D'].join(' ');
  }

  @override
  int compareTo(ShowTimeSpec other) {
    // 1. Compare audio version
    final audioVersionComparison = Enum.compareByIndex(audioVersion, other.audioVersion);
    if (audioVersionComparison != 0) return audioVersionComparison;

    // 2. Compare subtitles by length (shorter first), then by content (so specs with different subtitles never compare equal)
    final subtitleLengthComparison = subtitles.length.compareTo(other.subtitles.length);
    if (subtitleLengthComparison != 0) return subtitleLengthComparison;
    final subtitleContentComparison = subtitles.map((s) => s.code).compareUnordered(other.subtitles.map((s) => s.code));
    if (subtitleContentComparison != 0) return subtitleContentComparison;

    // 3. Compare technology
    return (technology ?? '').compareTo(other.technology ?? '');
  }

  static const _setEquality = SetEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ShowTimeSpec &&
              runtimeType == other.runtimeType &&
              audioVersion == other.audioVersion &&
              _setEquality.equals(subtitles, other.subtitles) &&
              technology == other.technology;

  @override
  int get hashCode => audioVersion.hashCode ^ _setEquality.hash(subtitles) ^ technology.hashCode;
}

enum ShowAudioVersion {
  original('VO', 'Version originale'),
  french('VF', 'Version française'),
  dutch('VN', 'Version néerlandaise'),
  german('DF', 'Version allemande');

  const ShowAudioVersion(this.code, this.label);

  final String code;
  final String label;
}

enum ShowSubtitles {
  french('FR', 'Sous-titres français'),
  dutch('NL', 'Sous-titres néerlandais');

  const ShowSubtitles(this.code, this.label);

  final String code;
  final String label;
}
