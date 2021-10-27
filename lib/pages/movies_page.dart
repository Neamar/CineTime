import 'dart:collection';
import 'dart:math';

import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      body: FetchBuilder.simple<MoviesShowTimes>(
        controller: bloc.fetchController,
        fetchAtInit: false,
        task: bloc.fetch,
        builder: (context, moviesShowtimesData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              // Header
              Material(
                color: Theme.of(context).primaryColor,
                child: InkWell(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Spacer for alignment
                          Spacer(),

                          // Info
                          Column(
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
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
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

                          // Actions
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                CineTimeIcons.pencil,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: _goToTheatersPage,
                ),
              ),

              // Content
              Expanded(
                child: () {
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
              ),
            ],
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


class MoviesPageBloc with Disposable {
  MoviesPageBloc() {
    // Initial fetch, after widget is initialised
    WidgetsBinding.instance!.addPostFrameCallback((_) => refresh());
  }

  UnmodifiableSetView<Theater> _theaters = UnmodifiableSetView(const {});
  final fetchController = FetchBuilderController<Never, MoviesShowTimes>();

  Future<MoviesShowTimes> fetch() async {
    // Fetch data
    final moviesShowTimes = await AppService.api.getMoviesList(_theaters.toList(growable: false)..sort());

    // Sort
    moviesShowTimes.moviesShowTimes.sort();

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
}