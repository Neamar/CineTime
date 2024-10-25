// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/data_error.dart';
import 'package:cinetime/utils/exceptions/unauthorized_exception.dart';
import 'package:cinetime/utils/exceptions/connectivity_exception.dart';
import 'package:cinetime/utils/exceptions/http_response_exception.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_service.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = Iterable<dynamic>;

const _httpMethodGet = 'GET';
const _httpMethodPost = 'POST';

class ApiClient {
  //#region Vars
  /// Whether to use mocks or not
  static const useMocks = !kReleaseMode;

  /// Whether to use cache or not
  static const useCache = true;

  /// Mocked [DateTime.now()], to be consistent with mocked data
  static DateTime get mockedNow => useMocks ? DateTime(2021, 9, 13, 11, 55) : DateTime.now();

  /// API url
  static const _graphUrl = 'https://graph.all' + 'ocine.fr/v1/mobile/';

  /// Shows started for more than this duration are filtered out.
  static const _maxStartedShowtimeDuration = Duration(hours: 1);

  /// Request timeout duration
  static const _timeOutDuration = Duration(seconds: 30);

  /// Json mime type
  static const contentTypeJsonMimeType = 'application/json';
  static const contentTypeJson = '$contentTypeJsonMimeType; charset=utf-8';

  /// Whether to log headers also or not.
  static const _logHeaders = false;

  ApiClient() : _client = SentryHttpClient(
    failedRequestStatusCodes: [
      SentryStatusCode.range(400, 599),   // Report all errors
    ],
  );

  final http.Client _client;
  final _cacheManager = CacheManager(Config(
    'CtCache',
    stalePeriod: const Duration(days: 1),
  ));
  //#endregion

  //#region Requests
  /// Get theaters that match [query] (free text query)
  Future<List<Theater>> searchTheaters(String query) async {
    // Send request
    JsonObject? responseJson;
    if (useMocks) {
      responseJson = await _send<JsonObject>(_httpMethodGet, 'https://gist.githubusercontent.com/Nico04/be59b0f453dcc6c4efbb8bb659a7d96b/raw/4074465c4602086d45fd5d5a42b0238152f15a56/theaters-search.json');
    } else {
      query = Uri.encodeQueryComponent(query);   // Encode query, so char like '?' are correctly encoded
      responseJson = await _send<JsonObject>(_httpMethodGet, 'https://www.all' + 'ocine.fr/_/autocomplete/mobile/theater/$query');
    }

    // Process result
    final JsonList theatersJson = responseJson['results']!;
    return theatersJson.map((theaterJson) {
      final JsonObject theaterInfo = theaterJson['data']!;

      return Theater(
        id: ApiId(theaterInfo['id'], ApiId.typeTheater),
        name: theaterJson['label'],
        street: theaterInfo['address'],
        zipCode: theaterInfo['zip'],
        city: theaterInfo['city'],
      );
    }).toList(growable: false);
  }

  /// Get theaters around geo-position
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) async {
    // Send request
    JsonObject? responseJson;
    if (useMocks) {
      responseJson = await _send<JsonObject>(_httpMethodGet, 'https://gist.githubusercontent.com/Nico04/c09a01a9f62c8bc922549220415d4400/raw/3927fc7bf5e3b252baeba42f5c45a774f7f677a6/theaters-gps.json');
    } else {
      responseJson = await _sendGraphQL<JsonObject>(
        query: r'query TheatersList($after: String, $location: CoordinateType, $radius: Float, $card: [LoyaltyCard], $country: CountryCode) { theaterList(location: $location, radius: $radius, after: $after, loyaltyCard:$card, countries: [$country], order: [CLOSEST]) { __typename pageInfo { __typename hasNextPage endCursor } edges { __typename node { __typename ...TheaterFragment } } } } fragment TheaterFragment on Theater { __typename id internalId experience flags { __typename hasPreview hasBooking } poster { __typename id url } name coordinates { __typename distance(from: $location, ' + 'unit: "km") latitude longitude } theaterCircuits { __typename id internalId name } flags { __typename hasBooking } companies { __typename activity company { __typename id internalId name } } location { __typename address zip city country region } tags { __typename list } }',
        variables: {
          'location': {
            'lat': latitude,
            'lon': longitude,
          },
          'radius': 20000,
          'card': [],
          'country': 'FRANCE'
        },
      );
    }

    // Process result
    final JsonList theatersJson = responseJson['data']!['theaterList']!['edges']!;
    return theatersJson.map((theaterJson) {
      theaterJson = theaterJson['node']!;
      final JsonObject? address = theaterJson['location'];

      return Theater(
        id: ApiId.fromEncoded(theaterJson['id']),
        name: theaterJson['name'],
        street: address?['address'],
        zipCode: address?['zip'],
        city: address?['city'],
        distance: theaterJson['coordinates']?['distance']?.toDouble(),
      );
    }).toList(growable: false);
  }

  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters, { bool useCache = useCache }) async {
    // Prepare period
    final from = AppService.now.toDate;    // Truncate date to midnight, so it match request date (that is truncated).
    final to = from.add(const Duration(days: 8));     // Fetch next 7 days (seventh included)

    // Build movieShowTimes list
    final moviesShowTimesMap = <Movie, MovieShowTimes>{};

    // Prepare ghost showtimes map
    final ghostShowTimesMap = <Theater, List<ShowTime>>{};

    // For each theater
    for (final theater in theaters) {
      // Send request
      JsonObject? responseJson;
      if (useMocks) {
        const urls = [
          'https://gist.githubusercontent.com/Nico04/68c748a39f00e0180558673789cd5c40/raw/a7a548dd4e96060eaecefea892304b53ff0bacc0/showTimes1.json',
          'https://gist.githubusercontent.com/Nico04/81aa12b3c7078df19cbd32bb9b5b47cf/raw/7f08ed7153f685dd76c41fa0868f28ad28a0d522/showTimes2.json',
          'https://gist.githubusercontent.com/Nico04/d6886737ebe58291cd849bcf8119b73f/raw/60d0a79060c4a5f7f90a1ddc573e7440b43394e6/showTimes3.json',
          'https://gist.githubusercontent.com/Nico04/d25fed26e00ba90704c5cd97b8d0fd2a/raw/ebd2633c46d70b3be37acec1fdc3f16ccaf91edb/showTimes4.json',
        ];

        responseJson = await _send<JsonObject>(
          _httpMethodGet,
          urls.elementAt(theaters.toList(growable: false).indexOf(theater) % urls.length),
          useCache: useCache,
        );
      } else {
        responseJson = await _sendGraphQL<JsonObject>(
          /*** Notes
           * Each request can have a maximum complexity of 12000 points.
           * The [count] variable linearly increase the total request complexity point count.
           *
           * -- 1. Original query --
           * r'query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { theater(id: $id) { __typename id internalId name theaterCircuits { __typename id internalId name } flags { __typename hasBooking } companies { __typename company { __typename id internalId name } activity } } movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { __typename totalCount pageInfo { __typename hasNextPage endCursor } edges { __typename node { __typename showtimes { __typename id internalId startsAt isPreview projection techno diffusionVersion data { __typename ticketing { __typename urls type provider } } } movie { __typename id title languages credits(department: DIRECTION, first: 3) { __typename edges { __typename node { __typename person { __typename id internalId firstName lastName } } } } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename id internalId firstName lastName } voiceActor { __typename id internalId firstName lastName } originalVoiceActor { __typename id internalId firstName lastName } } } } releases(type: [RELEASED], country: $country) { __typename releaseDate { __typename date } } genres runTime videos(externalVideo: false, first: 1) { __typename id internalId } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } editorialReviews { __typename rating } poster { __typename url } } } } } }'
           *
           * Complexity: 21 + 203 * count
           * Example: for count = 100 : 20321 points
           *
           * -- 2. Lighter query (minimal fields, but all types kept) --
           * r'query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { __typename totalCount pageInfo { __typename hasNextPage endCursor } edges { __typename node { __typename showtimes { __typename startsAt projection diffusionVersion } movie { __typename id title credits(department: DIRECTION, first: 3) { __typename edges { __typename node { __typename person { __typename firstName lastName } } } } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename firstName lastName } voiceActor { __typename firstName lastName } originalVoiceActor { __typename firstName lastName } } } } releases(type: [RELEASED], country: $country) { __typename releaseDate { __typename date } } genres runTime videos(externalVideo: false, first: 1) { __typename id internalId } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } poster { __typename url } } } } } }'
           *
           * Complexity: 152 * count
           * Example: for count = 100 : 15200 points
           *
           * -- 3. Minimalist query --
           * 'query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { totalCount pageInfo { hasNextPage endCursor } edges { node { showtimes { startsAt projection diffusionVersion } movie { id title credits(department: DIRECTION, first: 3) { edges { node { person { firstName lastName } } } } cast(first: 5) { edges { node { actor { firstName lastName } voiceActor { firstName lastName } originalVoiceActor { firstName lastName } } } } releases(type: [RELEASED], country: $country) { releaseDate { date } } genres runTime videos(externalVideo: false, first: 1) { id internalId } stats { userRating { score(base: 5) } pressReview { score(base: 5) } } poster { url } } } } } }'
           *
           * Complexity: 97 * count
           * Example: for count = 200 : 19400 points
           *
           */
          query: r'query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { totalCount pageInfo { hasNextPage endCursor } edges { node { showtimes { startsAt projection diffusionVersion data { ticketing { urls provider } } } movie { id title credits(department: DIRECTION, first: 3) { edges { node { person { firstName lastName } } } } cast(first: 5) { edges { node { actor { firstName lastName } voiceActor { firstName lastName } originalVoiceActor { firstName lastName } } } } releases(type: [RELEASED], country: $country) { releaseDate { date } } genres runTime videos(externalVideo: false, first: 1) { id internalId } stats { userRating { score(base: 5) } pressReview { score(base: 5) } } poster { url } } } } } }',
          variables: {
            'id': theater.id.encodedId,
            'from': _dateToString(from),
            'to': _dateToString(to),
            'count': 100,
            'hasPreview': false,
            'order': [
              'PREVIEW',
              'REVERSE_RELEASE_DATE',
              'WEEKLY_POPULARITY'
            ],
            'country': 'FRANCE'
          },
          useCache: useCache,
        );
      }

      // Process response
      responseJson = responseJson['data']!;

      // Check data
      final JsonObject moviesShowTimesDataJson = responseJson!['movieShowtimeList']!;
      if (moviesShowTimesDataJson['pageInfo']['hasNextPage'] == true) {
        final totalCount = moviesShowTimesDataJson['totalCount'];
        reportError(UnimplementedError('MovieShowtimes has more results to be fetched for "${theater.name}" (totalCount: $totalCount)'), StackTrace.current);
      }

      // Get movie info
      final JsonList moviesShowTimesJson = moviesShowTimesDataJson['edges']!;
      for (JsonObject movieShowTimesJson in moviesShowTimesJson) {
        movieShowTimesJson = movieShowTimesJson['node']!;

        // Build ShowTimes
        final JsonList? showTimesJson = movieShowTimesJson['showtimes'];
        if (isIterableNullOrEmpty(showTimesJson))
          continue;

        const versionMap = {
          'ORIGINAL': ShowVersion.original,
          'DUBBED': ShowVersion.dubbed,
          'LOCAL': ShowVersion.local,
        };
        ShowFormat parseFormat(JsonList? json) {
          if (isIterableNullOrEmpty(json)) return ShowFormat.f2D;
          final flat = json!.join('|');
          if (flat.contains('IMAX'))
            return flat.contains('3D') ? ShowFormat.IMAX_3D : ShowFormat.IMAX;
          if (flat.contains('3D'))
            return ShowFormat.f3D;
          return ShowFormat.f2D;
        }

        final showTimes = showTimesJson!.map((showTimeJson) {
          return ShowTime(
            DateTime.parse(showTimeJson['startsAt']),
            spec: ShowTimeSpec(
              version: versionMap[showTimeJson['diffusionVersion']] ?? ShowVersion.original,
              format: parseFormat(showTimeJson['projection']),
            ),
            ticketingUrl: () {    // Needs to be in multiple steps to enforce [firstOrNull] extension static resolution
              final JsonList? ticketing = showTimeJson['data']?['ticketing'];
              if (ticketing == null) return null;
              final JsonList? urls = (ticketing.firstWhereOrNull((t) => t['provider'] == 'default') ?? ticketing.firstOrNull)?['urls'];
              return urls?.firstOrNull as String?;
            } (),
          );
        }).toList();

        // Filter passed shows
        showTimes.removeWhere((s) => s.dateTime.add(_maxStartedShowtimeDuration).isBefore(AppService.now));

        // Skip this movie if there are no valid showtimes (all passed)
        if (showTimes.isEmpty) continue;

        // Check movie info
        final JsonObject? movieJson = movieShowTimesJson['movie'];
        if (movieJson == null) {
          // This may happen when an event (usually a movie, but may be a special local show) doesn't have a proper page on API provider.
          // In that case, showTimes are still available (and ticketing links works), but movie info is empty.
          // On the official Android app, it is displayed as a "blank" movie session: we can add to calendar and book, but no movie info is displayed.
          // On the web site, session is just not displayed at all.
          reportError(DataError('Movie data is empty on theater "${theater.name}" for ${showTimes.length} showTimes (first is at ${showTimes.first.dateTime.toIso8601String()})'), StackTrace.current);

          // In that case, collect ghost showtimes in a separate map
          ghostShowTimesMap.putIfAbsent(theater, () => []).addAll(showTimes);

          // And skip movie processing
          continue;
        }

        // Build Movie info
        final String movieId = movieJson['id'];
        var movie = moviesShowTimesMap.keys.firstWhereOrNull((m) => m.id.id == movieId);

        if (movie == null) {
          final JsonList releasesJson = movieJson['releases'] ?? [];
          final JsonList genresJson = movieJson['genres'] ?? [];
          final String? posterUrl = movieJson['poster']?['url'];
          final JsonList videosJson = movieJson['videos'] ?? [];
          final String? trailerId = videosJson.firstOrNull?['id'];
          final JsonObject statisticsJson = movieJson['stats'] ?? {};

          String? personsFromJson(JsonList? personsJson) {
            if (personsJson == null) return null;
            return personsJson.map((json) {
              json = json['node'];
              final JsonObject? personJson = json['person'] ?? json['actor'] ?? json['voiceActor'] ?? json['originalVoiceActor'];
              return [
                personJson?['firstName'],
                personJson?['lastName'],
              ].joinNotEmpty(' ');
            }).joinNotEmpty(', ');
          }

          movie = Movie(
            id: ApiId.fromEncoded(movieId),
            title: movieJson['title'],
            directors: personsFromJson(movieJson['credits']?['edges']),
            actors: personsFromJson(movieJson['cast']?['edges']),
            releaseDate: dateFromString(releasesJson.firstOrNull?['releaseDate']?['date']),
            durationApi: movieJson['runTime'],
            genresApi: genresJson,
            poster: _getPathFromUrl(posterUrl),
            trailerId: isStringNullOrEmpty(trailerId) ? null : ApiId.fromEncoded(trailerId!),
            pressRating: (statisticsJson['pressReview']?['score'] as num?)?.toDouble(),
            userRating: (statisticsJson['userRating']?['score'] as num?)?.toDouble(),
          );
        }

        // Get or create MovieShowTimes
        final movieShowTimes = moviesShowTimesMap.putIfAbsent(movie, () => MovieShowTimes(movie!));

        // Update or create TheaterShowTimes
        var theaterShowTimes = movieShowTimes.theatersShowTimes.firstWhereOrNull((t) => t.theater == theater);
        if (theaterShowTimes == null) {
          theaterShowTimes = TheaterShowTimes(theater);
          movieShowTimes.theatersShowTimes.add(theaterShowTimes);
        }
        theaterShowTimes.showTimes.addAll(showTimes);
      }
    }

    // Return data
    return MoviesShowTimes(
      theaters: theaters,
      moviesShowTimes: moviesShowTimesMap.values.toList(growable: false),
      ghostShowTimes: ghostShowTimesMap.entries.map((e) => TheaterShowTimes(e.key, showTimes: e.value)).toList(growable: false),
      fetchedFrom: from,
      fetchedTo: to,
    );
  }

  /// Get detailed movie info
  /// Return synopsis and certificate
  Future<MovieInfo> getMovieInfo(ApiId movieId) async {
    // Send request
    JsonObject? responseJson;
    if (useMocks) {
      responseJson = await _send<JsonObject>(_httpMethodGet, 'https://gist.githubusercontent.com/Nico04/d31cd58a64f9d9fc17d6f9384d2d1d78/raw/ebc120d74a768572685b04d2945692de5f994b47/movie.json');
    } else {
      responseJson = await _sendGraphQL<JsonObject>(
        query: r'query MovieMoreInfoQuery($id: String, $country: CountryCode) { movie(id: $id) { __typename id internalId title originalTitle genres type poster { __typename id internalId url } synopsis(long: true) mainRelease { __typename type } movieOperation: operation { __typename target { __typename main { __typename code } data } } countries { __typename id name localizedName } releases(type: [RELEASED], country: $country) { __typename releaseDate { __typename date } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id name } } certificate { __typename label } } dvdReleases: releases(type: [DVD_RELEASE], country: $country) { __typename releaseDate { __typename date } } blueRayReleases: releases(type: [BLU_RAY_RELEASE], country: $country) { __typename releaseDate { __typename date } } VODReleases: releases(type: [VOD_RELEASE], country: $country) { __typename releaseDate { __typename date } } releaseFlags { __typename ...ReleaseUpcomingFragment } data { __typename productionYear budget } format { __typename color audio } languages boxOfficeFR: boxOffice(type: ENTRY, country: FRANCE, period: WEEK) { __typename range { __typename startsAt endsAt } value cumulative } boxOfficeUS: boxOffice(type: PROFIT, country: USA, period: WEEK) { __typename range { __typename startsAt endsAt } value cumulative } relatedTags { __typename internalId name } } } fragment ReleaseUpcomingFragment on ReleaseFlags { __typename release { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } upcoming { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } }',
        variables: {
          'id': movieId.encodedId,
          'country': 'FRANCE'
        },
      );
    }

    // Process data
    final JsonObject? movieJson = responseJson['data']?['movie'];

    // Synopsis
    String? synopsis = movieJson?['synopsis'];
    if (synopsis != null) synopsis = convertBasicHtmlTags(synopsis);

    // Certificate
    final JsonList releasesJson = movieJson?['releases'] ?? [];
    final String? certificate = releasesJson.firstOrNull?['certificate']?['label'];

    // Return data
    return MovieInfo(
      synopsis: synopsis,
      certificate: certificate,
    );
  }

  Future<String?> getVideoUrl(ApiId videoId) async {
    // Send request
    JsonObject? responseJson;
    if (useMocks) {
      responseJson = await _send<JsonObject>(_httpMethodGet, 'https://gist.githubusercontent.com/Nico04/799b8f245708ff679f6b9f3236919737/raw/c860d3b779feae230d333d0217f4900705a6559d/video.json');
    } else {
      responseJson = await _sendGraphQL<JsonObject>(
        query: r'query Video($id: String!, $country: CountryCode) { video(id: $id) { __typename id internalId title type duration language publication { __typename startsAt } relatedEntities { __typename ... on Movie { id title genres poster { __typename url } countries { __typename id name localizedName } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename internalId id countries { __typename id } } } } } releases(type: [RELEASED, SVOD_RELEASE], country: $country) { __typename releaseDate { __typename date } certificate { __typename label } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id internalId name } } } releaseFlags { __typename ...ReleaseUpcomingFragment } credits(department: DIRECTION, first: 5) { __typename edges { __typename node { __typename person { __typename id firstName lastName countries { __typename id } } position { __typename name } } } } data { __typename productionYear } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } editorialReviews { __typename rating } relatedTags { __typename id internalId name scope } } ... on Series { ...VideoSeries } ... on Season { internalId series { __typename ...VideoSeries } } ... on Episode { internalId season { __typename series { __typename ...VideoSeries } } } } files { __typename quality height url size } snapshot { __typename id url } } } fragment ReleaseUpcomingFragment on ReleaseFlags { __typename release { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } upcoming { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } } fragment VideoSeries on Series { __typename id title genres poster { __typename url } countries { __typename id name localizedName } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename id internalId countries { __typename id } } } } } direction: credits(department: DIRECTION) { __typename edges { __typename node { __typename position { __typename name } person { __typename id firstName lastName countries { __typename id } } } } } releaseFlags { __typename ...ReleaseUpcomingFragment } releases(country: $country) { __typename releaseDate { __typename date } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id name } } } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } relatedTags { __typename id internalId scope } }',
        variables: {
          'id': videoId.encodedId,
          'country': 'FRANCE'
        },
      );
    }

    // Process result
    responseJson = responseJson['data']?['video'];
    final JsonList? videosJson = responseJson?['files'];
    if (videosJson == null) {
      reportError(DataError('Video query result contains no files (title: ${responseJson?['title']} | videoId: ${videoId.id})'), StackTrace.current);
      return null;
    }
    if (videosJson.length == 1) return MovieVideo.fromJson(videosJson.first).url;

    // Find highest quality video, but not greater than 720p
    final videos = videosJson.map((json) => MovieVideo.fromJson(json)).toList();
    videos.sort((v1, v2) => v1.height.compareTo(v2.height));
    var bestVideo = videos.firstWhereOrNull((video) => video.height > 700);
    bestVideo ??= videos.last;
    return bestVideo.url;
  }

  /// Get the full url or an image from [path].
  /// if [isThumbnail] is true, image will be small. Otherwise it will return full size.
  static String? getImageUrl(String? path, {bool isThumbnail = false}) {
    if (path?.isNotEmpty != true) return null;
    return 'https://images.all' + 'ocine.fr/' + (isThumbnail ? 'r_200_200' : '') + path!;
  }

  /// Return the external url of the movie
  static String getMovieUrl(ApiId movieId) => 'https://www.all' + 'ocine.fr/film/fichefilm_gen_cfilm=${movieId.id}.html';
  //#endregion

  //#region Generics
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Return correctly formatted date
  static String _dateToString(DateTime date) => '${_dateFormat.format(date)}T00:00:00';

  /// Return the path part of an url
  static String? _getPathFromUrl(String? url) => url != null ? Uri.parse(url).path : null;

  /// Build a unique key based on the request, used for cache.
  static String _getCacheKeyFromRequest(http.Request request) {
    // If it's a GraphQL request
    if (request.url.toString() == _graphUrl) {
      return request.body.replaceAllMapped(RegExp(r'.+?query (.+?)\(.+",.+?variables":(.+)', dotAll: true), (match) => '${match.group(1)}${match.group(2)}');
    }

    // If it's a classic request
    else {
      return request.url.toString();
    }
  }

  /// Basic authToken cached value
  String? _authToken;

  /// Get an auth token for GraphQL request.
  /// Usually one per device.
  Future<String> _getAuthToken() async {
    // TEMP logic has completely changed, this is a temporary fix using a hardcoded value
    return 'fyLro_zsTKG8gP8m365k7r:APA91bH4aPzBejBUFIrPJSFH_iXa3P0xD6WkrM1oFbx_mSPuG1-R1A-fSRIKotgppimARubThI2R-0AoR78aGg5RkzsYSUuPMSNck-wpzR2zAI4oXZzykcTl6DpCcjF2rU2WOv8v1umK';

    // Is value cached ?
    if (_authToken == null) {
      // Read from local storage
      var authToken = StorageService.readAuthToken();

      // Ask for a auth token
      if (authToken == null) {
        // --- Get Firebase auth token ---
        // Build request
        const androidPackage = 'com.all' + 'ocine.androidapp';
        const headers1 = {
          HttpHeaders.userAgentHeader: 'Dalvik/2.1.0',
          'X-Android-Cert': 'B708782E3014076A' + '78BDD85B60F77FA797F7A021',
          'X-Android-Package': androidPackage,
          'x-firebase-client': 'H4sIAAAAAAAAAKtWykhNLCpJSk0sKV' + 'ayio7VUSpLLSrOzM9TslIyUqoFAFyivEQfAAAA',
          'x-goog-api-key': 'AIzaSyCqJ4WUpKj-XHx' + 'p2sJakwJN304fpWjq8r8',
        };

        final appId = _RandomFidGenerator.createRandomFid();
        const firebaseAppId = '1:84854' + '8993493:android:cadcaabc' + '242a1fc0';
        final body1 = {
          'fid': appId,
          'appId': firebaseAppId,
          'authVersion': 'FIS_v2',
          'sdkVersion': 'a:17.2.0'
        };

        // Send request
        final response1 = await _send<JsonObject>(_httpMethodPost, 'https://firebaseinstallations.googleapis.com/v1/projects/al' + 'locine-160' + '815/installations', headers: headers1, bodyJson: body1, useCache: false);
        final firebaseAuth = response1['authToken']['token'] as String;

        // --- Register device ---
        // Build request
        const headers2 = {
          HttpHeaders.authorizationHeader: 'Ai' + 'dLogin 4024960225' + '512858735:8027018111' + '184442980',
          HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
          HttpHeaders.userAgentHeader: 'Android-GCM/1.5',
        };

        const projectNumber = '84854' + '8993493';
        const appVer = '478';
        const firebaseHash = 'R1dAH9Ui7M-ynozn' + 'wBdw01tLxhI';
        final body2 = 'X-subtype=$projectNumber&sender=$projectNumber&X-app_ver=$appVer&X-osv=31&X-cliv=fcm-23.3.1&X-gmsv=225014047&X-appid=$appId&X-scope=*&X-Goog-Firebase-Installations-Auth=$firebaseAuth&X-gmp_app_id=$firebaseAppId&X-firebase-app-name-hash=$firebaseHash&X-app_ver_name=9.4.8&app=$androidPackage&device=40249602' + '25512858735&app_ver=$appVer&info=8z1YwDoyTHcWQKr' + 'i541rkWV1gDFLpRg&gcm_ver=225014047&plat=0&cert=b708782e3014076a7' + '8bdd85b60f77fa797f7a021&target_ver=33';

        // Send request
        final response2 = await _send<String>(_httpMethodPost, 'https://android.apis.google.com/c2dm/regi' + 'ster3', headers: headers2, stringBody: body2, useCache: false);

        // Check for errors (status code is always 200)
        if (response2.startsWith('Error=')) throw HttpException('Error while registering device: $response2');
        AnalyticsService.trackEvent('New auth token fetched');

        // Parse value
        authToken = response2.substring(6); // Remove var name

        // Save value
        unawaited(StorageService.saveAuthToken(authToken));
      }
      _authToken = authToken;
    }
    return _authToken!;
  }

  /// Delete all locally saved auth tokens
  Future<void> clearAuthToken() async {
    _authToken = null;
    await StorageService.deleteAuthToken();
  }

  /// Regex to detect invalid token error, so we can clear it and get a new one.
  /// Error message may vary, and case also.
  /// Seen examples :
  /// - {"error":"Invalid token."}
  /// - {"error":"Missing Token"}
  /// - {"error":"InvalidToken"}
  /// - {"error":"MissingToken"}
  /// - {"error":"The registration is not found."}
  static final _tokenErrorRegex = RegExp(r'(((Invalid)|(Missing)) ?Token)|(The registration is not found)', caseSensitive: false);

  /// Send a graphQL request
  /// If [enableAutoRetryOnUnauthorized] is true, it will auto retry if authToken is invalid (after getting a new one)
  Future<T> _sendGraphQL<T>({required String query, required JsonObject variables, bool useCache = useCache, bool enableAutoRetryOnUnauthorized = true }) async {
    // Headers
    final headers = {
      'a' + 'c-auth-token': await _getAuthToken(),
      'authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciO' + 'iJSUzI1NiJ9.eyJpYXQiOjE2NzU0NDEwNTksImV4cCI6MTgzMzU4MDc5OSwidXNlcm5hbWUiOiJhbm9ueW1vdXMiLCJhcHBsaWNhdGlvbl9uYW1lIjoibW9iaWxlIiwidX' + 'VpZCI6ImJmMDQ3YjgzLWQ0MzktNGM0My1iYWQ4LTBhNTc3MzFkZGM4OCIsInNjb3BlIjpudWxsfQ.s-_yFAY2wLi0ggRE_GKjuoH4A1lPBaf9iVhbzqUu_ityjVMe4R' + 'UdQHwlXqedQv3cinnLszpwfMPDg78qrQEn2vfoWe6_Af_pj0WRJV3mhrf4EpTnBFy-7NZoXDLNDtobi99XRUJpG-89kreZXzBZbMuuirVyn0XwHgDk8Pnatdh6uLWiQHSxXz9qeXgNT-R1FOS0aNlS604oAvQ_PJa1CC6qmLFtmjOZUhWul' + 'yBSUos1rhrf3BvEHM4G0XME_ocr_79PIOKWP5c4PrW-8hydQRDQmu-OAaMldsRc9Rgy_8UAYSn4n-AqiUAa1Ckdjz3UpVbA75pJJ6HsbiMZBpNb4nVanaPisL0LuyqcMp0I49iIZbOF0szHK0wZMcVmCuU3ZLTHcQsDWhVhMpA2SdMV6-vR-Vgw86nGCJZ89KQ_-mnvBxI6fPPinzhaTsvspfcnoggJLcZjqV_bRzwB6wn4MjCbI1jEkTSng0ebPZSHXqNx6EHriQ7LEAoMKmckYVVuvKGaYkriemY6SWGSeNTDNn9QPnh4BKAIhitRN0Anxs6vE1IQYUBcpFm7GSxjGi2_wzEy6g5iobEn2MR80wIWLP9k932c' + '7mcE69NSD4y5iyFYIwcdxfBvsrVoPWoEWLdSkwXjsGBgtBv3MA6jRTkFUlZH90V' + 'xcIsNz0BEnH6G240',
      'host': 'graph.all' + 'ocine.fr',
    };

    // Body
    final body = {
      'query': query,
      'variables': variables,
    };

    // Send request
    try {
      return await _send<T>(_httpMethodPost, _graphUrl, headers: headers, bodyJson: body, useCache: useCache);
    } catch(e) {
      // Unauthorized
      if (e is HttpResponseException && e.statusCode == 400 && _tokenErrorRegex.hasMatch(e.body)) {
        // Clear tokens (to get new ones next time)
        await clearAuthToken();

        // If allowed, retry
        if (enableAutoRetryOnUnauthorized) {
          return await _sendGraphQL(query: query, variables: variables, useCache: useCache, enableAutoRetryOnUnauthorized: false);
        }

        // If not allowed to retry, juts throw
        else {
          throw UnauthorizedException(e.toString());
        }
      }

      // In all other cases, just rethrow
      rethrow;
    }
  }

  /// Send a classic request
  Future<T> _send<T>(String method, String url, {Map<String, String>? headers, JsonObject? bodyJson, String? stringBody, bool useCache = useCache}) async {
    // Create request
    final request = http.Request(method, Uri.parse(url));

    // Set headers
    request.headers.addAll({
      HttpHeaders.acceptHeader: contentTypeJson,
      if (bodyJson != null) HttpHeaders.contentTypeHeader: contentTypeJson,
      'user-agent': 'androidapp/0.0.1',
    });
    if (headers != null)
      request.headers.addAll(headers);

    // Set body
    if (bodyJson != null)
      request.body = json.encode(bodyJson);
    else if (stringBody != null)
      request.body = stringBody;

    // Send request
    return await _sendRequest<T>(request, useCache: useCache);
  }

  /// Send a generic request
  Future<T> _sendRequest<T>(http.Request request, {bool useCache = useCache}) async {
    // Log
    _log(request: request);

    // Prepare cache key
    final cacheKey = _getCacheKeyFromRequest(request);

    // Get response
    final response = await () async {
      // If we can use cache
      if (useCache) {
        // Check cache
        final cachedResponseFile = await _cacheManager.getFileFromCache(cacheKey);

        // If cache is available
        if (cachedResponseFile != null) {
          // Read response from cached file
          final cachedResponse = await cachedResponseFile.file.readAsString();
          useCache = false;

          // Process response
          return http.Response(cachedResponse, 200,
            headers: {HttpHeaders.contentTypeHeader: contentTypeJson}, // Needed so content is decoded using utf-8
            request: http.Request('CACHE', Uri.parse(cachedResponseFile.file.path)),
          );
        }
      }

      // Check internet
      await throwIfNoInternet();

      // All in one Future to handle timeout
      try {
        return await(() async {
          //Send request
          final streamedResponse = await _client.send(request);

          //Wait for the full response
          return await http.Response.fromStream(streamedResponse);
        }()).timeout(_timeOutDuration);
      } on TimeoutException {
        throw const ConnectivityException(ConnectivityExceptionType.timeout);
      }
    } ();

    // Process response
    return _processResponse<T>(response, useCache ? cacheKey : null);
  }

  /// Process server's [response].
  /// Returns processed result as Json or String.
  /// Cache body if [cacheKey] is provided.
  T _processResponse<T>(http.Response response, String? cacheKey) {
    // Wrap response in a ResponseHandler to facilitate treatment
    final responseHandler = _ResponseHandler(response);

    // Logging
    _log(responseHandler: responseHandler);

    // Process response - Success
    if (responseHandler.isSuccess) {
      // Check for errors
      // A GraphQL request may return a 200 HTTP status code with errors
      if (responseHandler.isBodyJson) {
        final processedResponse = responseHandler.bodyJsonOrNull<JsonObject>();
        final errors = processedResponse?['errors'];
        if (errors != null) {
          throw HttpResponseException(response);
        }
      }

      // Store in cache
      if (cacheKey != null) {
        try {
          _cacheManager.putFile(cacheKey, response.bodyBytes);
          debugPrint('API (˅) [CACHED $cacheKey]');
        } catch (e, s) {
          reportError(e, s);
        }
      }

      // If raw string is asked
      if (T == String) {
        return responseHandler.bodyString as T;
      }

      // Json
      else if (T == JsonObject || T == JsonList) {
        return responseHandler.bodyJson<T>();
      }

      // If body doesn't need to be processed
      else if (isTypeUndefined<T>()) {
        return null as T;
      }

      // Unhandled types
      else {
        throw UnimplementedError('$T is not a supported type');
      }
    }

    // Process response - Error
    else {
      throw HttpResponseException(response);
    }
  }

  /// Log a request or a response
  /// Only provide either one, not both
  static void _log({http.BaseRequest? request, _ResponseHandler? responseHandler}) {
    if (kReleaseMode || request == null && responseHandler == null) return;
    const includeBody = true;

    // Common properties
    request = request ?? responseHandler!.response.request;
    final method = request?.method;
    final url = request?.url.toString();

    // Type specific
    String typeSymbol = '';
    String statusCode = '';
    String body = '';
    String? headers;

    // It's a response
    if (responseHandler != null) {
      final r = responseHandler.response;
      typeSymbol = '<';
      statusCode = r.statusCode != 200 ? '(${r.statusCode}) ' : '';
      if (includeBody) {
        if (responseHandler.isBodyJson) {
          body = responseHandler.bodyString.removeAllNewLines();
        } else {
          final sizeInKo = ((r.contentLength ?? 0) / 1024).round();
          if (sizeInKo <= 10) {
            body = responseHandler.bodyString.removeAllNewLines();
          } else {
            body = '$sizeInKo ko';
          }
        }
      }
      if (_logHeaders) {
        headers = r.headers.toString();
      }
    }

    // It's a request
    else if (request != null) {
      typeSymbol = '?';
      if (includeBody) {
        body = request is http.Request ? request.body : '';

        // Crop string if it's a GraphQL request body
        body = body.replaceAllMapped(RegExp(r'("query .+?\()(.+")(,.+?variables":)', dotAll: true), (match) => '${match.group(1)}...)${match.group(3)}');
      }
      if (_logHeaders) {
        headers = request.headers.toString();
      }
    }

    // Build log string
    debugPrint('API ($typeSymbol) $statusCode[$method $url] $body');
    if (headers != null) {
      debugPrint('API (${typeSymbol}H) $headers');
    }
  }

  static Future<void> throwIfNoInternet() async {
    if (await isOffline()) {
      debugPrint('API (✕) NO INTERNET');
      throw const ConnectivityException(ConnectivityExceptionType.noInternet);
    }
  }

  static Future<bool> isOffline() async => (await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);

  static Future<bool> isOnline() async => !(await isOffline());

  static bool isHttpSuccessCode (int httpStatusCode) => httpStatusCode >= 200 && httpStatusCode < 300;
  //#endregion
}

class _ResponseHandler {
  _ResponseHandler(this.response) :
    isSuccess = ApiClient.isHttpSuccessCode(response.statusCode),
    isBodyJson = ContentType.parse(response.headers[HttpHeaders.contentTypeHeader] ?? '').mimeType == ApiClient.contentTypeJsonMimeType;

  final http.Response response;

  final bool isSuccess;
  final bool isBodyJson;

  String? _bodyString;
  String get bodyString => _bodyString ?? (_bodyString = response.body);

  /// Decode body as JSON and cast as [T].
  /// May throw if unexpected format.
  T bodyJson<T>() {
    // Decode json
    final bodyJson = json.decode(bodyString);

    // cast
    return bodyJson as T;
  }

  /// Same as [bodyJson], but will return null if operation fails.
  T? bodyJsonOrNull<T>() {
    try {
      return bodyJson<T?>();
    } catch(e) {
      debugPrint('ResponseHandler.Error : Could not decode json : $e : $bodyString');
    }
    return null;
  }
}

class _RandomFidGenerator {
  static const int fidLength = 22;
  static const int fid4BitPrefix = 0x70; // Byte.parseByte("01110000", 2);
  static const int removePrefixMask = 0x0F; // Byte.parseByte("00001111", 2);

  static String createRandomFid() {
    final uuid = Random().nextInt(1 << 32);   // If we need a real UUID, we might want to use a package like uuid.
    final bytesFromUUID = getBytesFromUUID(uuid);
    final b2 = bytesFromUUID[0];
    bytesFromUUID[16] = b2;
    bytesFromUUID[0] = (b2 & removePrefixMask) | fid4BitPrefix;
    return encodeFidBase64UrlSafe(bytesFromUUID);
  }

  static List<int> getBytesFromUUID(int uuid) {
    final buffer = ByteData(17);
    buffer.setUint64(0, uuid);
    buffer.setUint64(8, uuid);
    return buffer.buffer.asUint8List();
  }

  static String encodeFidBase64UrlSafe(List<int> bytes) => base64Url.encode(bytes).substring(0, fidLength);
}
