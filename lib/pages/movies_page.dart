import 'dart:collection';
import 'dart:math';

import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
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
    return Scaffold(
      body: FetchBuilder<MoviesShowTimes>(
        controller: bloc.fetchController,
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
                              BehaviorSubjectBuilder<SplayTreeSet<Theater>>(   //OPTI because BehaviorSubjectBuilder of moviesShowTimes is above, and theses two streams are linked, this BehaviorSubjectBuilder is useless.
                                subject: bloc.theaters,
                                builder: (context, snapshot) {
                                  final theaters = snapshot.data;
                                  final theatersCount = theaters?.length ?? 0;
                                  return Text(
                                    () {
                                      if (theatersCount == 0) return 'Aucun cinéma sélectionné';
                                      if (theatersCount == 1) return 'Films pour ${theaters!.first.name}';
                                      return 'Films dans $theatersCount cinémas';
                                    } (),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
                                  );
                                },
                              ),

                              // Period
                              AppResources.spacerTiny,
                              Text(
                                'Entre le ${moviesShowtimesData.fetchedFrom.day} et le ${moviesShowtimesData.fetchedTo.day}',
                                style: Theme.of(context).textTheme.caption?.copyWith(color: AppResources.colorDarkGrey),
                              ),
                            ],
                          ),

                          // Actions
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () => bloc.goToTheatersPage(context),
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
                      return MovieCard(
                        key: ValueKey(index),
                        movieShowTimes: moviesShowtimesData.moviesShowTimes[index],
                        showTheaterName: bloc.theaters.value.length > 1,
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
}


class MoviesPageBloc with Disposable {
  final theaters = BehaviorSubject<SplayTreeSet<Theater>>();

  final fetchController = FetchBuilderController();

  MoviesPageBloc()  {
    // Init list
    theaters.add(SplayTreeSet.from(AppService.instance.selectedTheaters, (t1, t2) => t1.name.compareTo(t2.name)));

    // Update data when theaters list change
    theaters.listen((value) => fetchController.refresh());
  }

  Future<MoviesShowTimes> fetch() async {
    // Fetch data
    final moviesShowTimes = await AppService.api.getMoviesList(theaters.value);

    // Sort
    moviesShowTimes.moviesShowTimes.sort((mst1, mst2) => (mst2.movie.userRating ?? 0).compareTo(mst1.movie.userRating ?? 0));

    // Return data
    return moviesShowTimes;
  }

  void goToTheatersPage(BuildContext context) async {   // TODO move to widget
    // Go to TheatersPage
    var selectedTheaters = await navigateTo<Iterable<Theater>>(context, (_) => TheatersPage());
    if (selectedTheaters == null)
      return;

    // Add result to selection & Update UI
    theaters.add(theaters.value..clear()..addAll(selectedTheaters));
  }

  @override
  void dispose() {
    theaters.close();
    super.dispose();
  }
}