import 'dart:collection';
import 'dart:math';

import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage([this.selectedTheaters]);

  final Iterable<Theater>? selectedTheaters;

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> with BlocProvider<MoviesPage, MoviesPageBloc> {
  final _scrollController = ScrollController();

  @override
  initBloc() => MoviesPageBloc(widget.selectedTheaters);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          // Header
          Material(
            color: Colors.red,
            child: InkWell(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: BehaviorSubjectBuilder<SplayTreeSet<Theater>>(
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
                      );
                    },
                  ),
                ),
              ),
              onTap: () => bloc.goToTheatersPage(context),
            ),
          ),

          // Content
          Expanded(
            child: FetchBuilder<List<MovieShowTimes>>(
              controller: bloc.fetchController,
              task: bloc.fetch,
              builder: (context, moviesShowtimes) {
                if (moviesShowtimes.isEmpty)
                  return IconMessage(
                    icon: Icons.theaters,
                    message: 'Aucune séance',
                  );

                return ListView.builder(
                  itemCount: moviesShowtimes.length,
                  itemExtent: 100 * max(MediaQuery.of(context).textScaleFactor, 1.0),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return MovieTile(
                      key: ValueKey(index),
                      movieShowTimes: moviesShowtimes[index],
                      showTheaterName: bloc.theaters.value.length > 1,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class MoviesPageBloc with Disposable {
  final theaters = BehaviorSubject<SplayTreeSet<Theater>>();
  final favoriteTheaters = FavoriteTheatersHandler.instance;

  final fetchController = FetchBuilderController();

  MoviesPageBloc(Iterable<Theater>? selectedTheaters)  {
    // Init list with the favorites
    theaters.add(SplayTreeSet.from(selectedTheaters ?? favoriteTheaters!.theaters, (t1, t2) => t1.name.compareTo(t2.name)));

    // Update data when theaters list change
    theaters.listen((value) => fetchController.refresh());
  }

  Future<List<MovieShowTimes>> fetch() async {
    // Fetch data
    final moviesShowTimesData = await AppService.api.getMoviesList(theaters.value);

    // Sort
    final displayList = moviesShowTimesData.moviesShowTimes!;
    displayList.sort((mst1, mst2) => (mst2.movie.userRating ?? 0).compareTo(mst1.movie.userRating ?? 0));

    // Return data
    return displayList;
  }

  void goToTheatersPage(BuildContext context) async {
    // Go to TheatersPage
    var selectedTheaters = await navigateTo<Iterable<Theater>>(context, (_) => TheatersPage(selectedTheaters: theaters.value));
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