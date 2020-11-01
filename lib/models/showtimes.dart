import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/services/web_services.dart';
import 'package:cinetime/helpers/tools.dart';
import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'showtimes.g.dart';

@JsonSerializable()
class TheatersShowTimes {
  final bool fromCache;
  final Iterable<MovieShowTimes> moviesShowTimes;

  @JsonKey(fromJson: StorageService.dateFromString, toJson: StorageService.dateToString)
  final DateTime fetchedAt;

  const TheatersShowTimes({this.fetchedAt, this.fromCache, this.moviesShowTimes});

  factory TheatersShowTimes.fromJson(Map<String, dynamic> json) => _$TheatersShowTimesFromJson(json);
  Map<String, dynamic> toJson(instance) => _$TheatersShowTimesToJson(this);
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
    this.theatersShowTimes = theatersShowTimes ?? List<TheaterShowTimes>(),
    this.filteredTheatersShowTimes = filteredTheatersShowTimes ?? List<TheaterShowTimes>();

  String toFullString(bool applyFilters) {
    var lines = List<String>();

    // Movie name
    lines.add("Séances pour '${movie.title}'");

    // For each theater
    for (var theaterShowTimes in getTheatersShowTimesDisplay(applyFilters == true)) {
      // Separator
      lines.add('');

      // Theater's name
      lines.add(theaterShowTimes.theater.name);

      // For each room
      for (var roomsShowTimes in theaterShowTimes.roomsShowTimes) {
        var roomShowTimes = roomsShowTimes.showTimesDisplay;
        var header = "[${roomsShowTimes.tags.join(' ')}] ";

        // for each ShowTimes
        for (var showTimes in roomShowTimes)
          lines.add(header + showTimes.where((s) => s != null).join(' '));
      }
    }

    // Return formatted string
    return lines.join('\n');
  }

  factory MovieShowTimes.fromJson(Map<String, dynamic> json) => _$MovieShowTimesFromJson(json);
  Map<String, dynamic> toJson(instance) => _$MovieShowTimesToJson(this);
}

@JsonSerializable()
class TheaterShowTimes {
  final Theater theater;
  final List<RoomShowTimes> roomsShowTimes;

  TheaterShowTimes(this.theater, {Iterable<RoomShowTimes> showTimes}) :
    this.roomsShowTimes = showTimes ?? List<RoomShowTimes>();

  String _showTimesSummary;
  String get showTimesSummary {
    if (_showTimesSummary == null) {
      var now = WebServices.mockedNow;
      var nextWednesday = now.getNextWednesday();

      // Get all date with a show, from [now], without duplicates, sorted.
      var daysWithShow = roomsShowTimes
        .expand((roomShowTime) => roomShowTime.showTimesRaw)
        .where((dateTime) => dateTime.isAfter(now))     //TODO use https://github.com/jogboms/time.dart (for all project)
        .map((dateTime) => dateTime.toDate)
        .toSet()    //OPTI not needed for the first return, move after (but will add a .toList) ?
        .toList(growable: false)
      ..sort();  //OPTI already sorted ?

      // If there are no date before next wednesday
      if (daysWithShow.first.isAfter(nextWednesday))
        return 'Prochaine séance le ${daysWithShow.first.toWeekdayString(withDay: true, withMonth: true)}';

      // Get all dates with a show before next wednesday
      var currentWeekShowTimes = daysWithShow.where((date) => date.isBefore(nextWednesday));

      // Format string & cache data
      _showTimesSummary = currentWeekShowTimes.toShortWeekdaysString(now);
    }

    return _showTimesSummary;
  }

  TheaterShowTimes copyWith({List<RoomShowTimes> roomsShowTimes}) => TheaterShowTimes(
    theater,
    showTimes: roomsShowTimes ?? this.roomsShowTimes,
  );

  factory TheaterShowTimes.fromJson(Map<String, dynamic> json) => _$TheaterShowTimesFromJson(json);
  Map<String, dynamic> toJson(instance) => _$TheaterShowTimesToJson(this);
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
    if (is3D)
      '3D',
    if (isIMAX)
      'IMAX',
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
      var date = showTime.toDate;
      var time = showTime.toTime;

      var dateShowTimes = datesShowTimes.putIfAbsent(date, () => Set<Time>());
      dateShowTimes.add(time);
    }

    // List of coupled Dates and Times
    var showTimesList = List<ShowTimes>();

    // Group dates that have the exact same times
    for (var dateShowTimesEntry in datesShowTimes.entries) {
      // Get day list with exact same times
      // TODO force grouping if missing times are passed (Exemple : we are wednesday 11h, ignore showtime before 11h when grouping)
      var showTimes = showTimesList.firstWhere((showTimes) => dateShowTimesEntry.value.containsSame(showTimes.times), orElse: () => null);
      if (showTimes != null)
        showTimes.dates.add(dateShowTimesEntry.key);
      else
        showTimesList.add(ShowTimes(Set.from([dateShowTimesEntry.key]), dateShowTimesEntry.value));
    }

    // Build the header
    var timesHeader = datesShowTimes.values
        .expand((times) => times)
        .toSet()
        .toList(growable: false)
      ..sort();

    var columnCount = 1 + timesHeader.length;

    // Build the double list of formatted strings
    var lines = List<List<String>>(showTimesList.length);
    for (var y = 0; y < showTimesList.length; y++) {
      var showTime = showTimesList[y];
      var cells = List<String>(columnCount);
      cells[0] = showTime.datesDisplay;

      for (var x = 1; x < columnCount; x ++) {
        var timeHeader = timesHeader[x - 1];
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
  Map<String, dynamic> toJson(instance) => _$RoomShowTimesToJson(this);
}

class ShowTimes {
  final Set<Date> dates;
  final Set<Time> times;

  ShowTimes(this.dates, this.times);

  String get datesDisplay => dates.toShortWeekdaysString(WebServices.mockedNow);
  String get timesDisplay => times.map((time) => time.toString()).join('  ');
}