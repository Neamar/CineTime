import 'dart:math';

import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/analytics_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/widgets/dialogs/showtime_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:value_stream/value_stream.dart';

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
        child: Scaffold(    // Needed for themed background color & for FetchBuilder error widget display
          body: FetchBuilder.basic<MoviesShowTimes>(
            controller: bloc.fetchController,
            fetchAtInit: false,
            task: bloc.fetch,
            builder: (context, moviesShowtimesData) {
              return Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: DataStreamBuilder<bool>(
                    stream: bloc.isSearchVisible,
                    builder: (context, isSearchVisible) {
                      // Normal AppBar
                      if (!isSearchVisible) {
                        return DataStreamBuilder<Date?>(
                          stream: bloc.dayFilter,
                          builder: (context, dayFilter) {
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
                                      style: context.textTheme.bodyMedium?.copyWith(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  } (),

                                  // Period
                                  AppResources.spacerTiny,
                                  Text(
                                    dayFilter != null ? 'Le ${dayFilter.toDayString()}' : moviesShowtimesData.periodDisplay,
                                    style: context.textTheme.bodySmall?.copyWith(color: AppResources.colorGrey),
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
                                DataStreamBuilder<MovieSortType>(
                                  stream: bloc.sortType,
                                  builder: (context, sortType) {
                                    return _SortButton(
                                      sortValue: sortType,
                                      onSortChanged: (value) => bloc.sortType.add(value, skipSame: true),
                                      dayFilterValue: dayFilter,
                                      dayFilterFrom: moviesShowtimesData.fetchedFrom.toDate,
                                      dayFilterTo: moviesShowtimesData.fetchedTo.toDate,
                                      daysWithShow: moviesShowtimesData.daysWithShow,
                                      onDayFilterChanged: (value) => bloc.dayFilter.add(value, skipSame: true),
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
                            style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
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

                        return DataStreamBuilder<_FilterSortData>(
                          stream: bloc.filterSortData,
                          builder: (context, filterSortData) {
                            return _FilteredMovieListView(
                              key: ObjectKey(moviesShowtimesData),    // Force complete rebuild on data refresh
                              moviesShowTimes: moviesShowtimesData.moviesShowTimes,
                              showTheaterName: moviesShowtimesData.theaters.length > 1,
                              filterSort: filterSortData,
                            );
                          },
                        );
                      } (),
                    ),

                    // Bottom data
                    if (moviesShowtimesData.ghostShowTimes.isNotEmpty)
                      _GhostShowtimesCard(moviesShowtimesData.ghostShowTimes),

                  ],
                ),
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
  const _SortButton({
    required this.sortValue,
    required this.onSortChanged,
    required this.dayFilterValue,
    required this.dayFilterFrom,
    required this.dayFilterTo,
    required this.daysWithShow,
    required this.onDayFilterChanged,
  });

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
        final textStyle = context.textTheme.titleMedium;
        TextStyle? buildTextStyle(bool isSelected, {Color? color}) {
          return textStyle?.copyWith(color: isSelected ? Theme.of(context).primaryColor : color);
        }

        return [
          // Sort
          ...MovieSortType.values.map((value) {
            return PopupMenuItem<MovieSortType>(
              value: value,
              textStyle: buildTextStyle(value == sortValue),
              child: Text(value.label),
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
    super.key,
    required this.moviesShowTimes,
    required this.showTheaterName,
    required this.filterSort,
  });

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
        return MovieCard(
          key: ValueKey(index),
          moviesShowTimes: filteredMoviesShowTimes,
          movieIndex: index,
          showTheaterName: widget.showTheaterName,
          preferredRatingType: widget.filterSort.sortType.preferredRatingType,
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
  const _GhostShowtimesCard(this.ghostShowTimes);

  final List<TheaterShowTimes> ghostShowTimes;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Tooltip(
            message: 'Certaines séances ne sont pas affichées par manque de données sur le film.\nVous pouvez toujours cliquer sur une séance pour accéder à ses informations.',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 5),
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
                  style: textStyle,
                ),
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: textStyle,
                      children: theaterShowTimes.showTimes.map((showtime) {
                        return TextSpan(
                          text: AppResources.formatterDateTime.format(showtime.dateTime),
                          recognizer: TapGestureRecognizer()..onTap = () => ShowtimeDialog.open(
                            context: context,
                            theater: theaterShowTimes.theater,
                            showtime: showtime,
                          ),
                        );
                      }).toList()..insertBetween(const TextSpan(text: ', ')),
                    ),
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

    // Refresh on sort change
    sortType.listen((value) {
      filterSortData.add(filterSortData.value.copyWith(sortType: value));
      StorageService.saveMovieSorting(value);   // No need to await
      AnalyticsService.trackEvent('Sort order', {
        'theatersId': _theaters.toIdListString(),
        'theaterCount': _theaters.length,
        'sortType': value.name,
      });
    });

    // Refresh on day filter change
    dayFilter.listen((value) => filterSortData.add(filterSortData.value.copyWith(dayFilter: () => value)));

    // Listen for search changes
    searchController.addListener(() => filterSortData.add(filterSortData.value.copyWith(textFilter: searchController.text)));

    // Analytics
    isSearchVisible.listen((value) {
      if (value) {
        AnalyticsService.trackEvent('Filter movies');
      }
    });
  }

  UnmodifiableSetView<Theater> _theaters = UnmodifiableSetView(const {});
  final fetchController = FetchBuilderController<Never, MoviesShowTimes>();

  final sortType = DataStream(StorageService.readMovieSorting() ?? MovieSortType.usersRating);
  final dayFilter = DataStream<Date?>(null);
  final isSearchVisible = DataStream(false);
  final searchController = TextEditingController();
  late final filterSortData = DataStream<_FilterSortData>(_FilterSortData(sortType: sortType.value));

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