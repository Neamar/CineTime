// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/http_response_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sleek_http_client/sleek_http_client.dart' hide HttpResponseException;

import 'api_client.dart';

/// API client for Belgium
class BelgiumApiClient extends ApiClient {
  //#region Vars
  BelgiumApiClient() : _client = SleekHttpClient(
    client: SentryHttpClient(
      failedRequestStatusCodes: [SentryStatusCode.range(400, 599)],
    ),
    authorityGetter: () => _authority,
    errorBuilder: HttpResponseException.new,
    interceptors: [   // TODO add caching
      LoggingInterceptor(logger: debugPrint),
    ],
  );

  static const _authority = 'cin' + 'ebel.dhnet.be';

  /// Shows started for more than this duration are filtered out.
  static const _maxStartedShowtimeDuration = Duration(hours: 1);    // TODO put in common with FR

  final SleekHttpClient _client;

  @override
  ApiId decodeStoredId(String encoded) => BelgiumApiId(encoded);
  //#endregion

  //#region Requests
  @override
  Future<List<Theater>> searchTheaters(String query) async {
    final htmlContent = await _client.send<String>(HttpMethod.get, '/recherche', queryParameters: {
      'query': query,
      'type': 'theater',
    });

    final document = html_parser.parse(htmlContent);
    final theaters = <Theater>[];

    for (final block in document.querySelectorAll('div.theaterSnippet[id^="theater"]')) {
      final rawId = block.attributes['id'] ?? '';
      final theaterId = RegExp(r'^theater(\d+)$').firstMatch(rawId)?.group(1);
      if (theaterId == null) continue;

      final name = block.querySelector('a.snippetTitle')?.text.trim() ?? '';
      if (name.isEmpty) continue;

      final (street, zipCode, city) = _parseAddress(block.querySelector('p.adress'));

      theaters.add(Theater(
        id: BelgiumApiId(theaterId),
        name: name,
        street: street,
        zipCode: zipCode,
        city: city,
      ));
    }

    return theaters;
  }

  @override
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) async {    // TODO disable this behavior for this country (hide button)
    // Source doesn't support geo-search; return all theaters
    return searchTheaters('');
  }

  @override
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters) async {
    final from = AppService.now.toDate;
    final to = from.add(const Duration(days: 7));

    final moviesShowTimesMap = <String, MovieShowTimes>{};
    final ghostShowTimesMap = <Theater, List<ShowTime>>{};

    for (final theater in theaters) {
      final encodedName = Uri.encodeComponent(theater.name);
      final htmlContent = await _client.send<String>(HttpMethod.get, '/fr/cinema/${theater.id.id}/$encodedName');

      final document = html_parser.parse(htmlContent);
      _parseMoviesFromCinemaPage(document, theater, moviesShowTimesMap, ghostShowTimesMap);
    }

    return MoviesShowTimes(
      theaters: theaters,
      moviesShowTimes: moviesShowTimesMap.values.toList(growable: false),
      ghostShowTimes: ghostShowTimesMap.entries.map((e) => TheaterShowTimes(e.key, showTimes: e.value)).toList(growable: false),
      fetchedFrom: from,
      fetchedTo: to,
    );
  }

  @override
  Future<MovieInfo> getMovieInfo(ApiId movieId) async {
    final htmlContent = await _client.send<String>(HttpMethod.get, '/film/${movieId.id}');

    final document = html_parser.parse(htmlContent);

    // Synopsis
    final synopsisElement = document.querySelector('.synopsis, [itemprop="description"]');
    String? synopsis = synopsisElement?.text.trim();
    if (synopsis?.isEmpty == true) synopsis = null;

    // Certificate (age rating image alt text)
    final certificateElement = document.querySelector('li.movieAudience img');
    String? certificate = certificateElement?.attributes['alt']?.trim();
    if (certificate?.isEmpty == true) certificate = null;

    return MovieInfo(
      synopsis: synopsis,
      certificate: certificate,
    );
  }

  @override
  Future<Uri?> getVideoUri(ApiId videoId) async => null;

  @override
  Future<DateTime?> getShowEndTime(DateTime startAt, Duration? movieDuration, Uri ticketingUri) async => null;
  //#endregion

  //#region URL helpers
  static const _movieBaseUrl = 'https://cine' + 'bel.dhnet.be/film';

  @override
  String moviePageUrl(String movieId) => '$_movieBaseUrl/$movieId';

  @override
  String movieUsersRatingUrl(String movieId) => '$_movieBaseUrl/$movieId';

  @override
  String moviePressRatingUrl(String movieId) => '$_movieBaseUrl/$movieId';

  @override
  String? getImageUrl(String? path, {bool isThumbnail = false}) {
    if (path?.isNotEmpty != true) return null;
    if (path!.startsWith('http')) return path;
    return 'https://$_authority$path';
  }
  //#endregion

  //#region HTML Parsing
  void _parseMoviesFromCinemaPage(
    html_dom.Document document,
    Theater theater,
    Map<String, MovieShowTimes> moviesShowTimesMap,
    Map<Theater, List<ShowTime>> ghostShowTimesMap,
  ) {
    final movieBlocks = document.querySelectorAll('div.subSection[id^="movie"]');
    for (final movieBlock in movieBlocks) {
      _parseMovieBlock(movieBlock, theater, moviesShowTimesMap);
    }
  }

  void _parseMovieBlock(
    html_dom.Element movieBlock,
    Theater theater,
    Map<String, MovieShowTimes> moviesShowTimesMap,
  ) {
    // Extract movie ID from block's id attribute (e.g. "movie1027625")
    final blockId = movieBlock.attributes['id'] ?? '';
    final movieId = RegExp(r'^movie(\d+)$').firstMatch(blockId)?.group(1);
    if (movieId == null) return;

    // Extract title from h4.sshd — use only direct text nodes, skip .originalTitle span
    String title = '';
    final titleElement = movieBlock.querySelector('h4.sshd');
    if (titleElement != null) {
      title = titleElement.nodes
          .where((n) => n is html_dom.Text || (n is html_dom.Element && !n.classes.contains('originalTitle')))
          .map((n) => n.text?.trim() ?? '')
          .join(' ')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
    }
    if (title.isEmpty) return;

    final posterUrl = movieBlock.querySelector('li.moviePoster img')?.attributes['src'];
    final durationDisplay = _extractDuration(movieBlock);

    final showTimes = _extractShowTimes(movieBlock);
    showTimes.removeWhere((s) => s.dateTime.add(_maxStartedShowtimeDuration).isBefore(AppService.now));
    if (showTimes.isEmpty) return;

    final movie = Movie(
      id: BelgiumApiId(movieId),
      title: title,
      poster: posterUrl,
      durationDisplay: durationDisplay,
    );

    final movieShowTimes = moviesShowTimesMap.putIfAbsent(movieId, () => MovieShowTimes(movie));

    var theaterShowTimes = movieShowTimes.theatersShowTimes.firstWhereOrNull((t) => t.theater == theater);
    if (theaterShowTimes == null) {
      theaterShowTimes = TheaterShowTimes(theater);
      movieShowTimes.theatersShowTimes.add(theaterShowTimes);
    }
    theaterShowTimes.showTimes.addAll(showTimes);
  }

  String? _extractDuration(html_dom.Element movieBlock) {
    final durationRegex = RegExp(r'^\d+h\d{2}$');
    for (final li in movieBlock.querySelectorAll('.scheduleMovieInfos ul > li')) {
      final text = li.text.trim();
      if (durationRegex.hasMatch(text)) return text;
    }
    return null;
  }

  /// Parse showtimes from the schedule table.
  /// Rows: tr.audioVO.video2D etc., date in th span.date (dd/MM),
  /// version in td abbr.audioVersion, times in td.representation div.hours span.
  List<ShowTime> _extractShowTimes(html_dom.Element movieBlock) {
    final showTimes = <ShowTime>[];

    for (final row in movieBlock.querySelectorAll('.schedulesItem table tbody tr')) {
      final dateText = row.querySelector('th span.date')?.text.trim();
      if (dateText == null) continue;
      final date = _parseDateDayMonth(dateText);
      if (date == null) continue;

      final version = _parseAudioVersion(row.querySelector('td abbr.audioVersion'));
      final format = _parseVideoFormat(row);
      final spec = ShowTimeSpec(version: version, format: format);

      for (final timeSpan in row.querySelectorAll('td.representation div.hours span')) {
        final time = _parseTime(timeSpan.text.trim());
        if (time == null) continue;
        final dateTime = DateTime(date.year, date.month, date.day, time.$1, time.$2);
        showTimes.add(ShowTime(dateTime, spec: spec));
      }
    }

    return showTimes;
  }

  /// Parse address parts from a `p.adress` element.
  /// Returns (street, zipCode, city).
  (String?, String?, String?) _parseAddress(html_dom.Element? element) {
    if (element == null) return (null, null, null);

    // Split on <br> by collecting text nodes
    final parts = element.nodes
        .whereType<html_dom.Text>()
        .map((n) => n.text.trim().replaceAll('\u00a0', ' '))
        .where((s) => s.isNotEmpty && !s.startsWith('Téléphone'))
        .toList();

    final street = parts.isNotEmpty ? parts[0] : null;

    // Second part is "zipCode city" (e.g. "2030 Antwerpen")
    String? zipCode, city;
    if (parts.length > 1) {
      final zipCity = parts[1].split(' ');
      if (zipCity.length >= 2) {
        zipCode = zipCity.first;
        city = zipCity.skip(1).join(' ');
      }
    }

    return (street, zipCode, city);
  }

  /// Parse "dd/MM" date string, adjusting year if needed.
  DateTime? _parseDateDayMonth(String text) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day == null || month == null) return null;

    final now = AppService.now;
    var year = now.year;
    // If date would be more than 60 days in the past, it's next year
    if (DateTime(year, month, day).isBefore(now.subtract(const Duration(days: 60)))) year++;

    return DateTime(year, month, day);
  }

  ShowVersion _parseAudioVersion(html_dom.Element? element) {
    if (element == null) return ShowVersion.original;
    final classes = element.className.toLowerCase();
    if (classes.contains(' vf')) return ShowVersion.dubbed;
    // VO, NV (Dutch), DF (German) → treated as original
    return ShowVersion.original;
  }

  ShowFormat _parseVideoFormat(html_dom.Element row) {
    final rowClass = row.className.toLowerCase();
    if (rowClass.contains('video3d')) {
      if (rowClass.contains('imax')) return ShowFormat.IMAX_3D;
      return ShowFormat.f3D;
    }
    if (rowClass.contains('imax')) return ShowFormat.IMAX;
    return ShowFormat.f2D;
  }

  /// Parse "HH:MM" or "H:MM" time string, returns (hour, minute) or null.
  (int, int)? _parseTime(String text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }
  //#endregion
}

/// Belgium specific [ApiId]. This source doesn't need any encoding: [encodedId] is simply [id].
class BelgiumApiId extends ApiId {
  BelgiumApiId(String id) : super(id, id);
}
