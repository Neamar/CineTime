// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/detailed_exception.dart';
import 'package:cinetime/utils/exceptions/http_response_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sleek_http_client/sleek_http_client.dart' hide HttpResponseException, JsonList, JsonObject;

import 'api_client.dart';
import 'cache_interceptor.dart';

/// API client for Belgium
class BelgiumApiClient extends ApiClient {
  //#region Vars
  BelgiumApiClient() : _client = SleekHttpClient(
    client: SentryHttpClient(
      failedRequestStatusCodes: [SentryStatusCode.range(400, 599)],
    ),
    authorityGetter: () => _authority,
    errorBuilder: HttpResponseException.new,
    interceptors: [
      if (CacheInterceptor.enabled) CacheInterceptor(
        keyBuilder: _getCacheKeyFromRequest,
        shouldCache: (request) => request.url.host != _videoAuthority,    // Video manifest url carries a signed token of unknown lifetime
      ),
      const _IncompletePageInterceptor(),
      LoggingInterceptor(logger: debugPrint),
    ],
  );

  static const _authority = 'cine' + 'bel.dh' + 'net.be';

  /// Trailers are hosted on a third-party video platform
  static const _videoDomain = 'dail' + 'ymotion.com';
  static const _videoAuthority = 'www.' + _videoDomain;
  static const _videoOrigin = 'https://geo.' + _videoDomain;

  final SleekHttpClient _client;

  /// Build a unique key based on the request, used for cache.
  /// Pages have no date in their url but their content depends on the current day, so the date is part of the key (cache is refreshed daily).
  static String _getCacheKeyFromRequest(http.BaseRequest request) => '${request.url}|${AppService.now.toDate}';

  @override
  ApiId decodeStoredId(String encoded) => BelgiumApiId(encoded);
  //#endregion

  @override
  bool get supportsGeoSearch => false;

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
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) => throw UnsupportedError('Geo-search is not supported for Belgium');

  @override
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters) async {
    final from = AppService.now.toDate;
    final to = from.add(const Duration(days: 7));

    final moviesShowTimesMap = <String, MovieShowTimes>{};
    final ghostShowTimesMap = <Theater, List<ShowTime>>{};

    for (final theater in theaters) {
      final encodedName = Uri.encodeComponent(theater.name);
      final htmlContent = await _client.send<String>(HttpMethod.get, '/cinema/${theater.id.id}/$encodedName');

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
    // (can be split into several paragraphs)
    var synopsisElements = document.querySelectorAll('.synopsis p');
    if (synopsisElements.isEmpty) synopsisElements = document.querySelectorAll('[itemprop="description"]');
    String? synopsis = synopsisElements
        .map((element) => element.text.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .join('\n\n');
    if (synopsis.isEmpty) synopsis = null;

    // Certificate (age rating image alt text)
    final certificateElement = document.querySelector('li.movieAudience img');
    String? certificate = certificateElement?.attributes['alt']?.trim();
    if (certificate?.isEmpty == true) certificate = null;

    // Release date
    final releaseDate = _parseDateDayMonthYear(document.querySelector('.releaseDate a')?.text.trim());

    // Genres (label is singular when there is only one genre)
    final genresElement = document.querySelectorAll('.movieInfosGroup > div')
        .firstWhereOrNull((element) => const {'Genre', 'Genres'}.contains(element.querySelector('strong')?.text.trim()));
    String? genres = genresElement?.querySelectorAll('li')
        .map((element) => element.text.trim())
        .where((genre) => genre.isNotEmpty)
        .join(', ');
    if (genres?.isEmpty == true) genres = null;

    // Press rating (average of all press sources, there can be up to 3)
    final pressRatings = document.querySelectorAll('.pressCritic .criticItem')
        .map((element) => _parseRating(element.text))
        .nonNulls
        .toList();
    final pressRating = pressRatings.isEmpty ? null : pressRatings.sum / pressRatings.length;

    // Trailer (video platform embed, e.g. ".../player/<playerId>.html?video=<videoId>")
    final trailerSrc = document.querySelector('#movieVideos iframe[src*="$_videoDomain"]')?.attributes['src'];
    final trailerVideoId = trailerSrc != null ? Uri.tryParse(trailerSrc)?.queryParameters['video'] : null;

    return MovieInfo(
      synopsis: synopsis,
      certificate: certificate,
      releaseDate: releaseDate,
      genres: genres,
      pressRating: pressRating,
      trailerId: trailerVideoId?.isNotEmpty == true ? BelgiumApiId(trailerVideoId!) : null,
    );
  }

  @override
  Future<VideoData?> getVideoData(ApiId videoId) async {
    // Ask the video platform for the stream manifest (HLS), the same way its embedded player does.
    // The manifest url can't be built from the video id: it carries a signed `sec` token
    // (`...m3u8?sec=...`, 403 without it) that is only delivered by this call, and whose lifetime is unknown.
    // That's why we only store the video id (see MovieInfo.trailerId) and request a fresh url right when the video is played.
    final responseJson = await _client.send<JsonObject>(
      HttpMethod.get,
      '/player/metadata/video/${videoId.id}',
      authority: _videoAuthority,
    );

    final JsonList? autoQualitiesJson = responseJson['qualities']?['auto'];
    final String? url = autoQualitiesJson?.firstOrNull?['url'];
    final uri = url != null ? Uri.tryParse(url) : null;
    if (uri == null) return null;

    // The manifest is rejected (403) without the Origin of the official player
    return VideoData(uri, headers: const {'Origin': _videoOrigin});
  }

  @override
  Future<DateTime?> getShowEndTime(DateTime startAt, Duration? movieDuration, Uri ticketingUri) async => null;
  //#endregion

  //#region URL helpers
  static const _movieBaseUrl = 'https://' + _authority + '/film';

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
  String showTimeAudioSubtitlesToDisplayString(ShowTimeSpec spec) {
    String label = spec.audioVersion.code;
    if (spec.subtitles.isNotEmpty) {
      label += ' st ${spec.subtitles.map((s) => s.code).join('/')}';
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
    String? originalTitle;
    final titleElement = movieBlock.querySelector('h4.sshd');
    if (titleElement != null) {
      title = titleElement.nodes
          .where((n) => n is html_dom.Text || (n is html_dom.Element && !n.classes.contains('originalTitle')))
          .map((n) => n.text?.trim() ?? '')
          .join(' ')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');

      originalTitle = titleElement.querySelector('span.originalTitle')?.text.trim();
      if (originalTitle != null && originalTitle.startsWith('(') && originalTitle.endsWith(')')) {
        originalTitle = originalTitle.substring(1, originalTitle.length - 1).trim();
      }
      if (originalTitle?.isEmpty == true) originalTitle = null;
    }
    if (title.isEmpty) return;

    final posterSrc = movieBlock.querySelector('li.moviePoster img')?.attributes['src'];
    final posterUrl = posterSrc == null || posterSrc.endsWith('/poster/small/default.png')    // Site's own placeholder, let the app display its own
        ? null
        : posterSrc.replaceFirst('/poster/small/', '/poster/full/');      // Use full-size poster
    final durationDisplay = _extractDuration(movieBlock);
    final (directors, actors) = _parsePersonList(movieBlock.querySelector('div.moviePersonList p'));
    final (country, countryCode, releaseYear) = _parseCountryAndYear(movieBlock);
    final usersRating = _parseRating(movieBlock.querySelector('li.ratingAverage img')?.attributes['alt']);    // e.g. "80 sur 100", only present for the few movies with enough votes

    final showTimes = _extractShowTimes(movieBlock);
    removeStartedShowTimes(showTimes);
    if (showTimes.isEmpty) return;

    final movie = Movie(
      id: BelgiumApiId(movieId),
      title: title,
      originalTitle: originalTitle,
      poster: posterUrl,
      durationDisplay: durationDisplay,
      directors: directors,
      actors: actors,
      country: country,
      countryCode: countryCode,
      releaseYear: releaseYear,
      usersRating: usersRating,
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

  /// Parse director(s) and actor(s) from the `div.moviePersonList > p` element.
  ///
  /// Content looks like:
  /// ```html
  /// <p>
  ///     de
  ///     <a href="/personne/30511/Pierre_Coffin">Pierre Coffin</a>
  ///     avec
  ///     <a href="/personne/22811/Amy_Sedaris">Amy Sedaris</a>,
  ///     <a href="...">...</a>
  ///     …
  /// </p>
  /// ```
  /// Names appearing before the "avec" marker are directors, names after are actors.
  (String?, String?) _parsePersonList(html_dom.Element? element) {
    if (element == null) return (null, null);

    final directors = <String>[];
    final actors = <String>[];
    var inActorsSection = false;

    for (final node in element.nodes) {
      if (node is html_dom.Text) {
        if (RegExp(r'\bavec\b').hasMatch(node.text)) inActorsSection = true;
      } else if (node is html_dom.Element && node.localName == 'a') {
        final name = node.text.trim();
        if (name.isEmpty) continue;
        (inActorsSection ? actors : directors).add(name);
      }
    }

    return (
      directors.isEmpty ? null : directors.join(', '),
      actors.isEmpty ? null : actors.join(', '),
    );
  }

  /// Parse country, countryCode and release year from the `.scheduleMovieInfos` list.
  ///
  /// The relevant `<li>` looks like:
  /// ```html
  /// <li>
  ///     <abbr title="États-Unis">US</abbr>
  ///     -
  ///     2026
  /// </li>
  /// ```
  /// The country can be missing, in which case the `<li>` is just "- 2025" (or "-" when the year is missing too).
  (String?, String?, String?) _parseCountryAndYear(html_dom.Element movieBlock) {
    for (final li in movieBlock.querySelectorAll('.scheduleMovieInfos ul > li')) {
      final abbr = li.querySelector('abbr');
      if (abbr == null) {
        final yearOnly = RegExp(r'^-\s*(\d{4})$').firstMatch(li.text.trim())?.group(1);
        if (yearOnly != null) return (null, null, yearOnly);
        continue;
      }

      final countryCode = abbr.text.trim();
      final country = abbr.attributes['title']?.trim();
      if (countryCode.isEmpty) continue;

      final yearMatch = RegExp(r'(\d{4})').firstMatch(li.text);
      final releaseYear = yearMatch?.group(1);

      return (
        country?.isEmpty == true ? null : country,
        countryCode,
        releaseYear,
      );
    }
    return (null, null, null);
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
      final audioClass = rowClasses.firstWhereOrNull((c) => c.startsWith('audio'));
      final audioVersion = switch (audioClass) {
        'audioVO' => ShowAudioVersion.original,
        'audioVF' => ShowAudioVersion.french,
        'audioNV' => ShowAudioVersion.dutch,
        'audioDF' => ShowAudioVersion.german,
        _ => () {
          reportError(UnimplementedError('Unknown audio version "$audioClass"'), StackTrace.current);
          return ShowAudioVersion.original;
        } (),
      };

      final technologies = <String>{};
      final videoClass = rowClasses.firstWhereOrNull((c) => c.startsWith('video'));
      if (videoClass != null && videoClass != 'video2D') technologies.add(videoClass.replaceFirst('video', ''));

      final tds = row.querySelectorAll('td');

      // Subtitles: 2nd <abbr> of the 1st <td> holds the subtitles info in its `title` attribute
      final subtitles = <ShowSubtitles>{};
      if (tds.isNotEmpty) {
        final subtitlesTitle = tds.first.querySelectorAll('abbr').elementAtOrNull(1)?.attributes['title'];
        if (subtitlesTitle != null) {
          if (subtitlesTitle.contains('français')) subtitles.add(ShowSubtitles.french);
          if (subtitlesTitle.contains('anglais')) subtitles.add(ShowSubtitles.english);
          if (subtitlesTitle.contains('néerlandais')) subtitles.add(ShowSubtitles.dutch);
          if (subtitlesTitle.isNotEmpty && subtitles.isEmpty) {
            reportError(UnimplementedError('Subtitles not handled: $subtitlesTitle'), StackTrace.current);
          }
        }
      }

      // Extra technology (IMAX, 4DX, ScreenX, LaserUltra, ...) shown as an icon in the 2nd-to-last <td>
      if (tds.length >= 2) {
        final techLabel = tds[tds.length - 2].querySelector('img')?.attributes['alt']?.trim();
        if (techLabel != null && techLabel.isNotEmpty) technologies.add(techLabel);
      }

      final spec = ShowTimeSpec(
        audioVersion: audioVersion,
        subtitles: subtitles,
        technology: _formatTechnology(technologies),
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

  /// Build a display-ready technology string from the technologies found on a schedule row, with "3D" always placed last (e.g. "IMAX 3D", "4DX 3D").
  /// Returns `null` when there is none (standard 2D).
  static String? _formatTechnology(Set<String> technologies) {
    if (technologies.isEmpty) return null;
    return [...technologies.where((t) => t != '3D'), if (technologies.contains('3D')) '3D'].join(' ');
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

  /// Parse a "dd/MM/yyyy" date string.
  DateTime? _parseDateDayMonthYear(String? text) {
    if (text == null) return null;
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  /// Parse a rating fraction ("7.5/10" or "80 sur 100") and normalize it to a five-point scale.
  double? _parseRating(String? text) {
    if (text == null) return null;
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:/|sur)\s*(\d+(?:[.,]\d+)?)').firstMatch(text);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final scale = double.tryParse(match.group(2)!.replaceAll(',', '.'));
    if (value == null || scale == null || scale <= 0 || value < 0 || value > scale) return null;
    return value / scale * 5;
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

/// The site sometimes returns an HTTP 200 with an empty page (no `#mainContent`), typically under load.
/// Without this check it would be parsed as "no movie", and cached for the whole day.
/// Placed after [CacheInterceptor], so the exception prevents the response from being cached.
class _IncompletePageInterceptor implements HttpInterceptor {
  const _IncompletePageInterceptor();

  @override
  Future<http.Response> intercept(http.BaseRequest request, HttpInterceptorChain chain) async {
    final response = await chain.proceed(request);

    // Only HTML pages of the site (not the JSON of the video host)
    if (request.url.host == BelgiumApiClient._authority && !response.body.contains('id="mainContent"')) {
      throw DetailedException(
        'Réponse incomplète du serveur, veuillez réessayer',
        details: '[${request.method}] ${request.url} (${response.body.length} chars)',
      );
    }

    return response;
  }
}

/// Belgium specific [ApiId]. This source doesn't need any encoding: [encodedId] is simply [id].
class BelgiumApiId extends ApiId {
  BelgiumApiId(String id) : super(id, id);
}
