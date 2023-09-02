import 'dart:collection';
import 'dart:math';

import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
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
    return WillPopScope(
      onWillPop: () async {
        if (bloc.isSearchVisible.value == true) {
          _cancelSearch();
          return false;
        }
        return true;
      },
      child: ClearFocusBackground(
        child: Scaffold(    // Needed for background color
          resizeToAvoidBottomInset: false,
          body: FetchBuilder.basic<MoviesShowTimes>(
            controller: bloc.fetchController,
            fetchAtInit: false,
            task: bloc.fetch,
            builder: (context, moviesShowtimesData) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: BehaviorSubjectBuilder<bool>(
                    subject: bloc.isSearchVisible,
                    builder: (context, snapshot) {
                      final isSearchVisible = snapshot.data!;

                      // Normal AppBar
                      if (!isSearchVisible) {
                        return BehaviorSubjectBuilder<Date?>(
                          subject: bloc.dayFilter,
                          builder: (context, snapshot) {
                            final dayFilter = snapshot.data;
                            return AppBar(
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
                                      }(),
                                      style: Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  } (),

                                  // Period
                                  AppResources.spacerTiny,
                                  Text(
                                    dayFilter != null ? 'Le ${dayFilter.toDayString()}' : moviesShowtimesData.periodDisplay,
                                    style: Theme.of(context).textTheme.caption?.copyWith(color: AppResources.colorGrey),
                                  ),
                                ],
                              ),
                              actions: [
                                IconButton(
                                  icon: const Icon(CineTimeIcons.pencil),
                                  onPressed: _goToTheatersPage,
                                ),
                                IconButton(
                                  icon: const Icon(CineTimeIcons.search),
                                  onPressed: () => bloc.isSearchVisible.add(true),
                                ),
                                BehaviorSubjectBuilder<MovieSortType>(
                                  subject: bloc.sortType,
                                  builder: (context, snapshot) {
                                    final sortType = snapshot.data!;
                                    return _SortButton(
                                      sortValue: sortType,
                                      onSortChanged: bloc.sortType.addDistinct,
                                      dayFilterValue: dayFilter,
                                      dayFilterFrom: moviesShowtimesData.fetchedFrom.toDate,
                                      dayFilterTo: moviesShowtimesData.fetchedTo.toDate,
                                      daysWithShow: moviesShowtimesData.daysWithShow,
                                      onDayFilterChanged: bloc.dayFilter.addDistinct,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }

                      // Search bar
                      else {
                        return AppBar(
                          title: TextField(
                            controller: bloc.searchController,
                            decoration: InputDecoration(
                              hintText: 'Filtrer par titre, acteurs, ...',
                              iconColor: Colors.white,
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: _cancelSearch,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: bloc.searchController.clear,
                              ),
                            ),
                            autofocus: true,
                            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
                            textInputAction: TextInputAction.search,
                          ),
                        );
                      }
                    },
                  ),
                ),
                body: Column(
                  children: [
                    // Content
                    Expanded(
                      child: () {
                        if (moviesShowtimesData.moviesShowTimes.isEmpty)
                          return const IconMessage(
                            icon: Icons.theaters,
                            message: 'Aucune séance',
                          );

                        return BehaviorSubjectBuilder<_FilterSortData>(
                          subject: bloc.filterSortData,
                          builder: (context, snapshot) {
                            return _FilteredMovieListView(
                              key: ObjectKey(moviesShowtimesData),    // Force complete rebuild on data refresh
                              moviesShowTimes: moviesShowtimesData.moviesShowTimes,
                              showTheaterName: moviesShowtimesData.theaters.length > 1,
                              filterSort: snapshot.data!,
                            );
                          },
                        );
                      } (),
                    ),

                    // Bottom data
                    if (moviesShowtimesData.ghostShowTimes.isNotEmpty)
                      _GhostShowtimesCard(moviesShowtimesData.ghostShowTimes),

                  ],
                )
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _goToTheatersPage() async {
    // Go to TheatersPage
    await navigateTo(context, (_) => const TheatersPage(), returnAfterPageTransition: false);

    // Update UI
    bloc.refresh(userAsked: true);
  }

  void _cancelSearch() {
    bloc.isSearchVisible.add(false);
    bloc.searchController.clear();
  }
}

class _SortButton extends StatelessWidget {
  static const _typesStrings = {
    MovieSortType.rating: 'Note',
    MovieSortType.releaseDate: 'Date de sortie',
    MovieSortType.duration: 'Durée',
  };

  const _SortButton({
    Key? key,
    required this.sortValue,
    required this.onSortChanged,
    required this.dayFilterValue,
    required this.dayFilterFrom,
    required this.dayFilterTo,
    required this.daysWithShow,
    required this.onDayFilterChanged,
  }) : super(key: key);

  /// Current sort value
  final MovieSortType sortValue;

  /// Called when sort method is tapped
  final ValueChanged<MovieSortType> onSortChanged;


  /// Current day filter value
  final Date? dayFilterValue;

  /// Date from which to display day filters
  final Date dayFilterFrom;

  /// Date to which to display day filters, excluded
  final Date dayFilterTo;

  /// Days where at least one show exists
  final Set<Date> daysWithShow;

  /// Called when day filter is tapped
  /// Pass a null value when tap on the current selection (for unselect behavior)
  final ValueChanged<Date?> onDayFilterChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        if (value is MovieSortType) {
          // Ignore if same value
          if (value != sortValue) onSortChanged(value);
        } else if (value is Date) {
          // Unselected date if selected value is tapped
          onDayFilterChanged(value == dayFilterValue ? null : value);
        } else {
          throw UnimplementedError('Unhandled type');
        }
      },
      itemBuilder: (context) {
        final textStyle = context.textTheme.subtitle1;
        TextStyle? buildTextStyle(bool isSelected, {Color? color}) {
          return textStyle?.copyWith(color: isSelected ? Theme.of(context).primaryColor : color);
        }

        return [
          // Sort
          ...MovieSortType.values.map((value) {
            return PopupMenuItem<MovieSortType>(
              value: value,
              textStyle: buildTextStyle(value == sortValue),
              child: Text(_typesStrings[value]!),
            );
          }),

          // Divider
          const PopupMenuDivider(),

          // Day filter
          ...() {
            final days = <Date>[];
            var day = dayFilterFrom;
            while (day.isBefore(dayFilterTo)) {
              days.add(day);
              day = day.addDays(1);
            }

            return days.map((day) {
              return PopupMenuItem<Date>(
                value: day,
                textStyle: buildTextStyle(day == dayFilterValue, color: daysWithShow.contains(day) ? null : textStyle?.color?.withOpacity(0.5)),
                child: Text(day.toDayString().capitalized),
              );
            });
          } (),
        ];
      },
    );
  }
}

class _FilteredMovieListView extends StatefulWidget {
  const _FilteredMovieListView({
    Key? key,
    required this.moviesShowTimes,
    required this.showTheaterName,
    required this.filterSort,
  }) : super(key: key);

  final List<MovieShowTimes> moviesShowTimes;
  final bool showTheaterName;
  final _FilterSortData filterSort;

  @override
  _FilteredMovieListViewState createState() => _FilteredMovieListViewState();
}

class _FilteredMovieListViewState extends State<_FilteredMovieListView> {
  List<MovieShowTimes> filteredMoviesShowTimes = [];

  @override
  void initState() {
    super.initState();
    applyFilter();
    applySort();
  }

  void applySort() {
    filteredMoviesShowTimes.sort((mst1, mst2) => mst1.compareTo(mst2, widget.filterSort.sortType));
  }

  void applyFilter() {
    filteredMoviesShowTimes = () {
      final textFilter = widget.filterSort.textFilter;
      final dayFilter = widget.filterSort.dayFilter;
      if (textFilter.isEmpty && dayFilter == null) return widget.moviesShowTimes;
      return widget.moviesShowTimes.where((mst) {
        return (textFilter.isEmpty || mst.movie.matchSearch(textFilter))
            && (dayFilter == null || mst.theatersShowTimes.any((tst) => tst.daysWithShow.contains(dayFilter)));
      }).toList(growable: false);
    } ();
  }

  @override
  Widget build(BuildContext context) {
    if (filteredMoviesShowTimes.isEmpty)
      return EmptySearchResultMessage.noResult;

    return ListView.builder(
      itemCount: filteredMoviesShowTimes.length,
      itemExtent: 100 * max(MediaQuery.of(context).textScaleFactor, 1.0),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final movieShowTimes = filteredMoviesShowTimes[index];
        return MovieCard(
          key: ObjectKey(movieShowTimes),
          movieShowTimes: movieShowTimes,
          showTheaterName: widget.showTheaterName,
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant _FilteredMovieListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterSort.dayFilter != oldWidget.filterSort.dayFilter || widget.filterSort.textFilter != oldWidget.filterSort.textFilter) {
      applyFilter();
    }
    if (widget.filterSort.sortType != oldWidget.filterSort.sortType) {
      applySort();
    }
  }
}

class _FilterSortData {
  const _FilterSortData({required this.sortType, this.dayFilter, this.textFilter = ''});

  final MovieSortType sortType;
  final Date? dayFilter;
  final String textFilter;

  _FilterSortData copyWith({MovieSortType? sortType, ValueGetter<Date?>? dayFilter, String? textFilter}) => _FilterSortData(
    sortType: sortType ?? this.sortType,
    dayFilter: dayFilter != null ? dayFilter() : this.dayFilter,      // ValueGetter needed to properly handle null values
    textFilter: textFilter ?? this.textFilter,
  );
}

class _GhostShowtimesCard extends StatelessWidget {
  const _GhostShowtimesCard(this.ghostShowTimes, {Key? key}) : super(key: key);

  final List<TheaterShowTimes> ghostShowTimes;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.caption;
    final textStyleGrey = textStyle?.copyWith(color: AppResources.colorGrey);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: 'Certaines séances ne sont pas affichées par manque de données sur le film',
            triggerMode: TooltipTriggerMode.tap,
            child: Row(
              children: [
                Text(
                  'Séances sans données ',
                  style: textStyle,
                ),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                ),
              ],
            ),
          ),
          AppResources.spacerTiny,
          ...ghostShowTimes.map((theaterShowTimes) {
            return Row(
              children: [
                Text(
                  '${theaterShowTimes.theater.name} : ',
                  style: textStyleGrey,
                ),
                Expanded(
                  child: Text(
                    theaterShowTimes.showTimes.map((showtime) => AppResources.formatterDateTime.format(showtime.dateTime)).join(', '),
                    style: textStyleGrey,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}


class MoviesPageBloc with Disposable {
  MoviesPageBloc() {
    // Initial fetch, after widget is initialised
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());

    // Init filter
    filterSortData.add(_FilterSortData(sortType: sortType.value!));

    // Refresh on sort change
    sortType.skip(1).listen((value) {
      filterSortData.add(filterSortData.value!.copyWith(sortType: value));
      StorageService.saveMovieSorting(value);   // No need to await
      AnalyticsService.trackEvent('Sort order', {
        'theatersId': _theaters.toIdListString(),
        'theaterCount': _theaters.length,
        'sortType': describeEnum(value),
      });
    });

    // Refresh on day filter change
    dayFilter.listen((value) => filterSortData.add(filterSortData.value!.copyWith(dayFilter: () => value)));

    // Listen for search changes
    searchController.addListener(() => filterSortData.add(filterSortData.value!.copyWith(textFilter: searchController.text)));

    // Analytics
    isSearchVisible.listen((value) {
      if (value) {
        AnalyticsService.trackEvent('Filter movies');
      }
    });
  }

  UnmodifiableSetView<Theater> _theaters = UnmodifiableSetView(const {});
  final fetchController = FetchBuilderController<Never, MoviesShowTimes>();

  final sortType = BehaviorSubject.seeded(StorageService.readMovieSorting() ?? MovieSortType.rating);
  final dayFilter = BehaviorSubject<Date?>();
  final isSearchVisible = BehaviorSubject.seeded(false);
  final searchController = TextEditingController();
  final filterSortData = BehaviorSubject<_FilterSortData>();

  Future<MoviesShowTimes> fetch() async {
    // Fetch data
    final moviesShowTimes = await AppService.api.getMoviesList(_theaters.toList(growable: false)..sort());

    // Analytics
    AnalyticsService.trackEvent('Movie list displayed', {
      'resultCount': moviesShowTimes.moviesShowTimes.length,
      'theaterCount': _theaters.length,
      'theatersId': _theaters.toIdListString(),
    });

    // Return data
    return moviesShowTimes;
  }

  void refresh({bool userAsked = false}) {
    // Compare new list with current one
    if (AppService.instance.selectedTheaters.isEqualTo(_theaters))
      return;

    // Analytics
    if (userAsked)
      AnalyticsService.trackEvent('Theater selected', {
        'count': AppService.instance.selectedTheaters.length - _theaters.length,
      });

    // Copy selected theater to a local list
    _theaters = UnmodifiableSetView(Set.from(AppService.instance.selectedTheaters));

    // Refresh data
    fetchController.refresh();
  }

  @override
  void dispose() {
    sortType.close();
    dayFilter.close();
    isSearchVisible.close();
    searchController.dispose();
    filterSortData.close();
    super.dispose();
  }
}