// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/api_providers/api_provider.dart';
import 'package:cinetime/services/app_http_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';

/// Allocine API provider implementation for France.
class AllocineApiProvider implements ApiProvider {
  AllocineApiProvider(this._client);

  final ApiClient _client;

  @override
  ApiProviderType get type => ApiProviderType.allocine;

  //#region URLs
  static const String _movieBaseUrl = 'https://www.all' + 'ocine.fr/film/fich' + 'efilm';

  @override
  String getMoviePageUrl(ApiId movieId) => '${_movieBaseUrl}_gen_cfilm=$movieId.html';

  @override
  String getMovieUsersRatingUrl(ApiId movieId) => '$_movieBaseUrl-$movieId/critiques/spectateurs/';

  @override
  String getMoviePressRatingUrl(ApiId movieId) => '$_movieBaseUrl-$movieId/critiques/presse/';

  @override
  String? getImageUrl(String? path, {bool isThumbnail = false}) {
    if (path?.isNotEmpty != true) return null;
    return 'https://images.all' + 'ocine.fr/' + (isThumbnail ? 'r_200_200' : '') + path!;
  }
  //#endregion

  //#region API constants

  /// Shows started for more than this duration are filtered out.
  static const _maxStartedShowtimeDuration = Duration(hours: 1);
  //#endregion

  //#region Requests
  @override
  Future<List<Theater>> searchTheaters(String query) async {
    // Send request
    query = Uri.encodeQueryComponent(query);   // Encode query, so char like '?' are correctly encoded
    final responseJson = await _client.send<JsonObject>(HttpMethod.get, 'https://www.all' + 'ocine.fr/_/autocomplete/mobile/theater/$query');

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

  @override
  Future<List<Theater>> searchTheatersGeo(double latitude, double longitude) async {
    // Send request
    final responseJson = await _sendGraphQL<JsonObject>(
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

  @override
  Future<MoviesShowTimes> getMoviesList(List<Theater> theaters, { bool useCache = true }) async {
    // Prepare period
    final from = AppService.now.toDate;    // Truncate date to midnight, so it match request date (that is truncated).
    final to = from.add(const Duration(days: 21));     // Fetch next 21 days

    // Build movieShowTimes list
    final moviesShowTimesMap = <Movie, MovieShowTimes>{};

    // Prepare ghost showtimes map
    final ghostShowTimesMap = <Theater, List<ShowTime>>{};

    // For each theater
    for (final theater in theaters) {
      // Send request
      var responseJson = await _sendGraphQL<JsonObject>(
        query: r'query MovieShowtimes($id: String!, $after: String, $count: Int, $from: DateTime!, $to: DateTime!, $hasPreview: Boolean, $order: [ShowtimeSorting], $country: CountryCode) { movieShowtimeList(theater: $id, from: $from, to: $to, after: $after, first: $count, hasPreview: $hasPreview, order: $order) { totalCount pageInfo { hasNextPage endCursor } edges { node { showtimes { startsAt projection diffusionVersion data { ticketing { urls provider } } } movie { id title languages credits(department: DIRECTION, first: 3) { edges { node { person { firstName lastName } } } } cast(first: 5) { edges { node { actor { firstName lastName } voiceActor { firstName lastName } originalVoiceActor { firstName lastName } } } } releases(type: [RELEASED], country: $country) { releaseDate { date } } genres runTime videos(externalVideo: false, first: 1) { id internalId } stats { userRating { score(base: 5) } pressReview { score(base: 5) } } poster { url } } } } } }',
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
          AnalyticsService.trackEvent('Ghost showtimes', {
            'theater': theater.name,
            'showTimesCount': showTimes.length,
            'firstShowTime': showTimes.first.dateTime.toIso8601String(),
          });

          // In that case, collect ghost showtimes in a separate map
          ghostShowTimesMap.putIfAbsent(theater, () => []).addAll(showTimes);

          // And skip movie processing
          continue;
        }

        // Build Movie info
        final String movieId = movieJson['id'];
        var movie = moviesShowTimesMap.keys.firstWhereOrNull((m) => m.id.id == movieId);

        if (movie == null) {
          final JsonList? releasesJson = movieJson['releases'];
          final JsonList? genresJson = movieJson['genres'];
          final String? posterUrl = movieJson['poster']?['url'];
          final JsonList? videosJson = movieJson['videos'];
          final String? trailerId = videosJson?.firstOrNull?['id'];
          final JsonObject statisticsJson = movieJson['stats'] ?? {};
          final JsonList? languagesJson = movieJson['languages'];

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

          String? buildDurationFromApi(String? durationApi) {
            if (isStringNullOrEmpty(durationApi)) return null;

            List<String> parts = durationApi!.split(':');
            if (parts.length != 3) return null;

            final hours = int.tryParse(parts[0]);
            if (hours == null) return null;

            final minutes = int.tryParse(parts[1]);
            if (minutes == null) return null;

            return '${hours}h${minutes.toTwoDigitsString()}';
          }

          final releaseDates = releasesJson?.map((r) => dateFromString(r['releaseDate']?['date'])).nonNulls;
          final releaseDate = (releaseDates == null || releaseDates.isEmpty) ? null : releaseDates.reduce((a, b) => a.isBefore(b) ? a : b);

          movie = Movie(
            id: ApiId.fromEncoded(movieId),
            title: movieJson['title'],
            languages: languagesJson?.map((languageCode) => _movieLanguageMap[languageCode]).joinNotEmpty(', '),
            directors: personsFromJson(movieJson['credits']?['edges']),
            actors: personsFromJson(movieJson['cast']?['edges']),
            releaseDate: releaseDate,
            durationDisplay: buildDurationFromApi(movieJson['runTime']),
            genres: genresJson?.map((genreApi) => _movieGenresMap[genreApi]).joinNotEmpty(', '),
            poster: _getPathFromUrl(posterUrl),
            trailerId: isStringNullOrEmpty(trailerId) ? null : ApiId.fromEncoded(trailerId!),
            usersRating: (statisticsJson['userRating']?['score'] as num?)?.toDouble(),
            pressRating: (statisticsJson['pressReview']?['score'] as num?)?.toDouble(),
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

  @override
  Future<MovieInfo> getMovieInfo(ApiId movieId) async {
    // Send request
    final responseJson = await _sendGraphQL<JsonObject>(
      query: r'query MovieMoreInfoQuery($id: String, $country: CountryCode) { movie(id: $id) { __typename id internalId title originalTitle genres type poster { __typename id internalId url } synopsis(long: true) mainRelease { __typename type } movieOperation: operation { __typename target { __typename main { __typename code } data } } countries { __typename id name localizedName } releases(type: [RELEASED], country: $country) { __typename releaseDate { __typename date } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id name } } certificate { __typename label } } dvdReleases: releases(type: [DVD_RELEASE], country: $country) { __typename releaseDate { __typename date } } blueRayReleases: releases(type: [BLU_RAY_RELEASE], country: $country) { __typename releaseDate { __typename date } } VODReleases: releases(type: [VOD_RELEASE], country: $country) { __typename releaseDate { __typename date } } releaseFlags { __typename ...ReleaseUpcomingFragment } data { __typename productionYear budget } format { __typename color audio } languages boxOfficeFR: boxOffice(type: ENTRY, country: FRANCE, period: WEEK) { __typename range { __typename startsAt endsAt } value cumulative } boxOfficeUS: boxOffice(type: PROFIT, country: USA, period: WEEK) { __typename range { __typename startsAt endsAt } value cumulative } relatedTags { __typename internalId name } } } fragment ReleaseUpcomingFragment on ReleaseFlags { __typename release { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } upcoming { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } }',
      variables: {
        'id': movieId.encodedId,
        'country': 'FRANCE'
      },
    );

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

  @override
  Future<Uri?> getVideoUri(ApiId videoId) async {
    // Send request
    JsonObject? responseJson = await _sendGraphQL<JsonObject>(
      query: r'query Video($id: String!, $country: CountryCode) { video(id: $id) { __typename id internalId title type duration language publication { __typename startsAt } relatedEntities { __typename ... on Movie { id title genres poster { __typename url } countries { __typename id name localizedName } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename internalId id countries { __typename id } } } } } releases(type: [RELEASED, SVOD_RELEASE], country: $country) { __typename releaseDate { __typename date } certificate { __typename label } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id internalId name } } } releaseFlags { __typename ...ReleaseUpcomingFragment } credits(department: DIRECTION, first: 5) { __typename edges { __typename node { __typename person { __typename id firstName lastName countries { __typename id } } position { __typename name } } } } data { __typename productionYear } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } editorialReviews { __typename rating } relatedTags { __typename id internalId name scope } } ... on Series { ...VideoSeries } ... on Season { internalId series { __typename ...VideoSeries } } ... on Episode { internalId season { __typename series { __typename ...VideoSeries } } } } files { __typename quality height url size } snapshot { __typename id url } } } fragment ReleaseUpcomingFragment on ReleaseFlags { __typename release { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } upcoming { __typename svod { __typename original exclusive amazonPrime appletv canalplay disney filmotv globoplay mycanal netflix ocs salto sfrPlay adn } } } fragment VideoSeries on Series { __typename id title genres poster { __typename url } countries { __typename id name localizedName } cast(first: 5) { __typename edges { __typename node { __typename actor { __typename id internalId countries { __typename id } } } } } direction: credits(department: DIRECTION) { __typename edges { __typename node { __typename position { __typename name } person { __typename id firstName lastName countries { __typename id } } } } } releaseFlags { __typename ...ReleaseUpcomingFragment } releases(country: $country) { __typename releaseDate { __typename date } companies(activity: [DISTRIBUTION_COMPANIES]) { __typename company { __typename id name } } } stats { __typename userRating { __typename score(base: 5) } pressReview { __typename score(base: 5) } } relatedTags { __typename id internalId scope } }',
      variables: {
        'id': videoId.encodedId,
        'country': 'FRANCE'
      },
    );

    // Process result
    responseJson = responseJson['data']?['video'];
    final JsonList? videosJson = responseJson?['files'];
    if (videosJson == null) {
      AnalyticsService.trackEvent('Empty video', {
        'videoId': videoId.id,
        'videoTitle': responseJson?['title'],
      });
      return null;
    }
    if (videosJson.length == 1) return MovieVideo.fromJson(videosJson.first).uri;

    // Find highest quality video, but not greater than 720p
    final videos = videosJson.map((json) => MovieVideo.fromJson(json)).toList();
    videos.sort((v1, v2) => v1.height.compareTo(v2.height));
    var bestVideo = videos.firstWhereOrNull((video) => video.height > 700);
    bestVideo ??= videos.last;
    return bestVideo.uri;
  }
  //#endregion

  //#region GraphQL helpers
  /// Send a graphQL request
  Future<T> _sendGraphQL<T>({required String query, required JsonObject variables, bool useCache = true }) async {
    return _client.sendGraphQL<T>(query: query, variables: variables, useCache: useCache);
  }

  static String _dateToString(DateTime date) => ApiClient.dateToString(date);

  static String? _getPathFromUrl(String? url) => ApiClient.getPathFromUrl(url);
  //#endregion
}

//#region Allocine-specific data maps
const _movieGenresMap = {
  'ACTION': 'Action',
  'ADVENTURE': 'Aventure',
  'ANIMATION': 'Animation',
  'BIOPIC': 'Biopic',
  'BOLLYWOOD': 'Bollywood',
  'CARTOON': 'Dessin animé',
  'CLASSIC': 'Classique',
  'COMEDY': 'Comédie',
  'COMEDY_DRAMA': 'Comédie dramatique',
  'CONCERT': 'Concert',
  'DETECTIVE': 'Policier',
  'DIVERS': 'Divers',
  'DOCUMENTARY': 'Documentaire',
  'DRAMA': 'Drame',
  'EROTIC': 'Érotique',
  'EXPERIMENTAL': 'Expérimental',
  'FAMILY': 'Famille',
  'FANTASY': 'Fantaisie',
  'HISTORICAL': 'Historique',
  'HISTORICAL_EPIC': 'Épique',
  'HORROR': 'Horreur',
  'JUDICIAL': 'Judiciaire',
  'KOREAN_DRAMA': 'Drama',
  'MARTIAL_ARTS': 'Arts Martiaux',
  'MEDICAL': 'Médical',
  'MOBISODE': 'Programme court',
  'MOVIE_NIGHT': 'Nuit du cinéma',
  'MUSIC': 'Musique',
  'MUSICAL': 'Comédie musicale',
  'OPERA': 'Opéra',
  'ROMANCE': 'Romance',
  'SCIENCE_FICTION': 'Science-fiction',
  'PERFORMANCE': 'Performance',
  'SOAP': 'Drame',
  'SPORT_EVENT': 'Sport',
  'SPY': 'Espion',
  'THRILLER': 'Thriller',
  'WARMOVIE': 'Film de guerre',
  'WEB_SERIES': 'Série web',
  'WESTERN': 'Western',
};

/// Map of language codes to their French display names
const _movieLanguageMap = {
  'ABORIGINAL_LANGUAGE': 'Langue aborigène',
  'AFRICAN_DIALECT': 'Dialecte africain',
  'AFRIKAANS': 'Afrikaans',
  'ALBANIAN': 'Albanais',
  'ALGERIAN': 'Algérien',
  'AMHARIC': 'Amharique',
  'ARABIC': 'Arabe',
  'ARAMAIC': 'Araméen',
  'ARMENIAN': 'Arménien',
  'AZERI': 'Azéri',
  'BAMBARA': 'Bambara',
  'BENGALI': 'Bengali',
  'BOSNIAN': 'Bosnien',
  'BRITON': 'Breton',
  'BULGARIAN': 'Bulgare',
  'BURMESE': 'Birman',
  'CANTONESE': 'Cantonais',
  'CATALAN': 'Catalan',
  'CHINESE': 'Chinois',
  'CREOLE': 'Créole',
  'CZECH': 'Tchèque',
  'DANISH': 'Danois',
  'DUTCH': 'Néerlandais',
  'ENGLISH': 'Anglais',
  'ESTONIAN': 'Estonien',
  'EUSKERA': 'Basque',
  'FARSI': 'Persan (Farsi)',
  'FILIPINO': 'Filipino',
  'FINNISH': 'Finnois',
  'FLEMISH': 'Flamand',
  'FRENCH': Movie.frenchLanguage,
  'GAELIC': 'Gaélique',
  'GALLEGO': 'Galicien',
  'GEORGIAN': 'Géorgien',
  'GERMAN': 'Allemand',
  'GREEK': 'Grec',
  'GUARANI': 'Guarani',
  'HEBREW': 'Hébreu',
  'HINDI': 'Hindi',
  'HOKKIEN': 'Hokkien',
  'HUNGARIAN': 'Hongrois',
  'ICELANDIC': 'Islandais',
  'INDONESIAN': 'Indonésien',
  'INUKTITUT': 'Inuktitut',
  'ITALIAN': 'Italien',
  'JAPANESE': 'Japonais',
  'KANNADA': 'Kannada',
  'KAZAKH': 'Kazakh',
  'KHMER': 'Khmer',
  'KIRGIZIAN': 'Kirghize',
  'KLINGON': 'Klingon',
  'KOREAN': 'Coréen',
  'KURDISH': 'Kurde',
  'LATIN': 'Latin',
  'LATVIAN': 'Letton',
  'LINGALA': 'Lingala',
  'LITHUANIAN': 'Lituanien',
  'MACEDONIAN': 'Macédonien',
  'MALAGASY': 'Malgache',
  'MALAY': 'Malais',
  'MALAYALAM': 'Malayalam',
  'MANDARIN': 'Mandarin',
  'MARATHI': 'Marathi',
  'MAYA': 'Maya',
  'MONGOLESE': 'Mongol',
  'NORWEGIAN': 'Norvégien',
  'OTHER': 'Autre',
  'PASHTO': 'Pachto',
  'PERSIAN': 'Persan',
  'POLISH': 'Polonais',
  'PORTUGUESE': 'Portugais',
  'PUNJABI': 'Pendjabi',
  'ROMANIAN': 'Roumain',
  'ROMANY': 'Romani',
  'RUSSIAN': 'Russe',
  'SERB': 'Serbe',
  'SERBO_CROAT': 'Serbo-croate',
  'SIGN_LANGUAGE': 'Langue des signes',
  'SILENT': 'Muet',
  'SLOVAK': 'Slovaque',
  'SLOVENIAN': 'Slovène',
  'SOMALI': 'Somali',
  'SOTHO': 'Sotho',
  'SPANISH': 'Espagnol',
  'SWAHILI': 'Swahili',
  'SWEDISH': 'Suédois',
  'SWISS_GERMAN': 'Suisse allemand',
  'TADZHIK': 'Tadjik',
  'TAMIL': 'Tamoul',
  'THAI': 'Thaï',
  'TELUGU': 'Télougou',
  'TIBETAN': 'Tibétain',
  'TURKISH': 'Turc',
  'UKRAINIAN': 'Ukrainien',
  'UNDETERMINED_LANGUAGE': 'Langue indéterminée',
  'URDU': 'Ourdou',
  'VALENCIANO': 'Valencien',
  'VIETNAMESE': 'Vietnamien',
  'WOLOF': 'Wolof',
  'YIDDISH': 'Yiddish',
  'ZANSKARI': 'Zanskari',
  'ZULU': 'Zoulou',
};
//#endregion
