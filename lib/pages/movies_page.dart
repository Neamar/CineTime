import 'dart:collection';
import 'dart:math';

import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage();

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> with BlocProvider<MoviesPage, MoviesPageBloc> {
  @override
  initBloc() => MoviesPageBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(    // Needed for background color
      body: FetchBuilder<MoviesShowTimes>(
        controller: bloc.fetchController,
        fetchAtInit: false,
        task: bloc.fetch,
        builder: (context, moviesShowtimesData) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Theater info
                  () {
                    final theaters = moviesShowtimesData.theaters;
                    final theatersCount = theaters.length;
                    return Text(
                      () {
                        if (theatersCount == 0) return 'Aucun cinéma sélectionné';
                        if (theatersCount == 1) return 'Films pour ${theaters.first.name}';
                        return 'Films dans $theatersCount cinémas';
                      } (),
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  } (),

                  // Period
                  AppResources.spacerTiny,
                  Text(
                    moviesShowtimesData.periodDisplay,
                    style: Theme.of(context).textTheme.caption?.copyWith(color: AppResources.colorDarkGrey),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    CineTimeIcons.pencil,
                  ),
                  onPressed: _goToTheatersPage,
                ),
                BehaviorSubjectBuilder<MovieSortType>(
                  subject: bloc.sortType,
                  builder: (context, snapshot) {
                    return _SortButton(
                      value: snapshot.data!,
                      onChanged: bloc.sortType.addDistinct,
                    );
                  },
                ),
              ],
            ),
            body: () {
              if (moviesShowtimesData.moviesShowTimes.isEmpty)
                return IconMessage(
                  icon: Icons.theaters,
                  message: 'Aucune séance',
                );

              return ListView.builder(
                itemCount: moviesShowtimesData.moviesShowTimes.length,
                itemExtent: 100 * max(MediaQuery.of(context).textScaleFactor, 1.0),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final movieShowTimes = moviesShowtimesData.moviesShowTimes[index];
                  return MovieCard(
                    key: ObjectKey(movieShowTimes),
                    movieShowTimes: movieShowTimes,
                    showTheaterName: moviesShowtimesData.theaters.length > 1,
                  );
                },
              );
            } (),
          );
        },
      ),
    );
  }

  Future<void> _goToTheatersPage() async {
    // Go to TheatersPage
    await navigateTo(context, (_) => TheatersPage(), returnAfterPageTransition: false);

    // Update UI
    bloc.refresh();
  }
}

class _SortButton extends StatelessWidget {
  static const _typesStrings = {
    MovieSortType.rating: 'Note',
    MovieSortType.releaseDate: 'Date de sortie',
    MovieSortType.duration: 'Durée',
  };

  const _SortButton({Key? key, required this.value, this.onChanged}) : super(key: key);

  final MovieSortType value;
  final ValueChanged<MovieSortType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MovieSortType>(
      icon: const Icon(Icons.sort),
      onSelected: onChanged,
      itemBuilder: (context) => MovieSortType.values.map((value) {
        return PopupMenuItem<MovieSortType>(
          value: value,
          textStyle: context.textTheme.subtitle1?.copyWith(color: this.value == value ? Theme.of(context).primaryColor : null),
          child: Text(
            _typesStrings[value]!,
          ),
        );
      }).toList(growable: false),
    );
  }
}


class MoviesPageBloc with Disposable {
  MoviesPageBloc() {
    // Initial fetch, after widget is initialised
    WidgetsBinding.instance!.addPostFrameCallback((_) => refresh());

    // Refresh on sort change
    sortType.listen((value) => fetchController.refresh());
  }

  UnmodifiableSetView<Theater> _theaters = UnmodifiableSetView(const {});
  final fetchController = FetchBuilderController();
  final sortType = BehaviorSubject.seeded(MovieSortType.rating);

  Future<MoviesShowTimes> fetch() async {
    // Fetch data
    final moviesShowTimes = await AppService.api.getMoviesList(_theaters.toList(growable: false)..sort());

    // Sort
    moviesShowTimes.moviesShowTimes.sort((mst1, mst2) => mst1.compareTo(mst2, sortType.value));

    // Return data
    return moviesShowTimes;
  }

  void refresh() {
    // Compare new list with current one
    if (AppService.instance.selectedTheaters.isEqualTo(_theaters))
      return;

    // Copy selected theater to a local list
    _theaters = UnmodifiableSetView(Set.from(AppService.instance.selectedTheaters));

    // Refresh data
    fetchController.refresh();
  }

  @override
  void dispose() {
    sortType.close();
    super.dispose();
  }
}