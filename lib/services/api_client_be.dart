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

  //#region Other
  @override
  String showTimeSpecToDisplayString(ShowTimeSpec spec) {
    String label = spec.audioVersion.code;
    if (spec.subtitles.isNotEmpty) {
      label += ' st ${spec.subtitles.map((s) => s.code).join('/')}';
    }

    if (spec.technologies.isNotEmpty) {
      label += ' ${spec.technologies.join(' ')}';
    }
    return label;

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

    final posterUrl = movieBlock.querySelector('li.moviePoster img')?.attributes['src']
        ?.replaceFirst('/poster/small/', '/poster/full/');      // Use full-size poster
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
      if (durationRegex.hasMatch(text)) {
        return text == '0h00' ? null : text;
      }
    }
    return null;
  }

  /// Parse showtimes from the schedule table.
  ///
  /// Each row looks like:
  /// ```html
  /// <tr class="audioVF video3D even">
  ///   <th scope="row"><span class="day">lundi</span><span class="date">31/08</span></th>
  ///   <td><abbr class="audioVersion VF" title="Version française">VF</abbr>&nbsp;<abbr title="Sous-titres français et néerlandais">S.t. fr/nl</abbr></td>
  ///   <td><abbr class="videoVersion v3D" title="3D">3D</abbr></td>
  ///   <td><img src="..." alt="4DX" title="4DX" /></td>
  ///   <td class="representation"><div class="hours"><span>13:45</span></div></td>
  /// </tr>
  /// ```
  /// The row's own class list reliably gives the audio version (`audioVO`/`audioVF`/`audioNV`/`audioDF`)
  /// and the base format (`video2D`/`video3D`), which is much more robust than parsing the nested `<abbr>` tags.
  /// Subtitles are given by the `title` of the 2nd `<abbr>` in the 1st `<td>` (no dedicated class exists for it).
  /// Extra technologies (IMAX, 4DX, ScreenX, LaserUltra, ...) appear as an `<img alt="...">` in the 3rd `<td>`.
  List<ShowTime> _extractShowTimes(html_dom.Element movieBlock) {
    final showTimes = <ShowTime>[];

    for (final row in movieBlock.querySelectorAll('.schedulesItem table tbody tr')) {
      final dateText = row.querySelector('th span.date')?.text.trim();
      if (dateText == null) continue;
      final date = _parseDateDayMonth(dateText);
      if (date == null) continue;

      // Audio version & base format (2D/3D) are reliably encoded in the row's own class list
      final rowClasses = row.classes;
      final audioVersion = switch (rowClasses.firstWhereOrNull((c) => c.startsWith('audio'))) {
        'audioVF' => ShowAudioVersion.french,
        'audioNV' => ShowAudioVersion.dutch,
        'audioDF' => ShowAudioVersion.german,
        _ => ShowAudioVersion.original,   // TODO use explicit VO + handle fallback ?
      };

      final technologies = <String>{};
      final videoClass = rowClasses.firstWhereOrNull((c) => c.startsWith('video'));
      if (videoClass != null && videoClass != 'video2D') technologies.add(videoClass.replaceFirst('video', ''));    // TODO use "videoVersion" class content instead ?

      final tds = row.querySelectorAll('td');

      // Subtitles: 2nd <abbr> of the 1st <td> holds the subtitles info in its `title` attribute
      final subtitles = <ShowSubtitles>{};
      if (tds.isNotEmpty) {
        final subtitlesTitle = tds.first.querySelectorAll('abbr').elementAtOrNull(1)?.attributes['title'];    // TODO use text content instead ("S.t. fr/nl")
        if (subtitlesTitle != null) {
          if (subtitlesTitle.contains('français')) subtitles.add(ShowSubtitles.french);
          if (subtitlesTitle.contains('néerlandais')) subtitles.add(ShowSubtitles.dutch);
        }
      }

      // Extra technology (IMAX, 4DX, ScreenX, LaserUltra, ...) shown as an icon in the 2nd-to-last <td>
      if (tds.length >= 2) {
        final techLabel = tds[tds.length - 2].querySelector('img')?.attributes['alt']?.trim();    // TODO use "title" instead
        if (techLabel != null && techLabel.isNotEmpty) technologies.add(techLabel);
      }

      final spec = ShowTimeSpec(
        audioVersion: audioVersion,
        subtitles: subtitles,
        technologies: technologies,
      );

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
