import 'package:cinetime/main.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/utils/exceptions/permission_exception.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class TheatersPage extends StatefulWidget {
  final Iterable<Theater>? selectedTheaters;

  const TheatersPage({ this.selectedTheaters });

  @override
  _TheatersPageState createState() => _TheatersPageState();
}

class _TheatersPageState extends State<TheatersPage> with BlocProvider<TheatersPage, TheatersPageBloc> {
  @override
  initBloc() => TheatersPageBloc(widget.selectedTheaters);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Nom ou adresse de cinéma',
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: bloc.onSearch,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: bloc.getGeoLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: BehaviorSubjectBuilder<bool>(
          subject: bloc.isBusySearching,
          builder: (context, isBusySnapshot) {

            // Is loading
            if (isBusySnapshot.data!)
              return CtProgressIndicator();

            // Is NOT loading
            return BehaviorSubjectBuilder<List<Theater>>(
              subject: bloc.theaters,
              builder: (context, snapshot) {

                // Error
                if (snapshot.hasError)
                  return IconMessage(
                    icon: IconMessage.iconError,
                    message: 'Impossible de récupérer les données',
                    tooltip: snapshot.error.toString(),
                    redIcon: true,
                  );

                // No data
                if (snapshot.data == null)
                  return IconMessage(
                    icon: FontAwesomeIcons.search,
                    message: 'Cherchez un cinéma par nom ou localisation',
                  );

                // Empty list
                if (snapshot.data!.isEmpty)
                  return IconMessage(
                    icon: IconMessage.iconSad,
                    message: 'Aucun résultat',
                  );

                // Has data
                final selectedCount = bloc.selectedTheaters.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[

                    // Stat texts
                    Material(
                      color: Colors.deepPurpleAccent,
                      child: Row(
                        children: <Widget>[
                          _buildStatText(
                            text: 'résultat'.plural(snapshot.data!.length),
                            alignment: TextAlign.start,
                          ),
                          _buildStatText(
                            text: 'sélectionné'.plural(selectedCount),
                            alignment: TextAlign.center,
                            onPressed: bloc.onSelectAll
                          ),
                          _buildStatText(
                            text: 'favori'.plural(bloc.favoriteTheaters!.theaters.length),
                            alignment: TextAlign.end,
                          ),
                        ],
                      ),
                    ),

                    // Theater list
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          var theater = snapshot.data![index];
                          var isFavorite = bloc.favoriteTheaters!.isFavorite(theater);

                          return Card(
                            key: ObjectKey(theater),
                            clipBehavior: Clip.antiAlias,
                            color: bloc.isSelected(theater) ? Colors.lightBlueAccent : null,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[

                                // Main content
                                InkWell(
                                  child: Row(
                                    children: <Widget>[

                                      // Image
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: CtCachedImage(
                                          path: theater.poster,
                                          isThumbnail: true,
                                        ),
                                      ),

                                      // Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Text(
                                                theater.name,
                                                style: Theme.of(context).textTheme.subtitle1,
                                              ),
                                              Spacer(),
                                              if (theater.distanceDisplay != null)
                                                Text(
                                                  theater.distanceDisplay!,
                                                  style: Theme.of(context).textTheme.bodyText2,
                                                ),
                                              Text(
                                                theater.fullAddress,
                                                style: Theme.of(context).textTheme.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => bloc.onSelected(theater),
                                ),

                                // Star button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Material(
                                    color: isFavorite ? Theme.of(context).primaryColor : Colors.white,
                                    shape: CornerBorder(CornerBorderPosition.topRight),
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: SizedBox.fromSize(
                                      size: Size.square(50),
                                      child: InkWell(
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Icon(
                                              isFavorite ? Icons.star : Icons.star_border,
                                              color: isFavorite ? Colors.white : Colors.black,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        onTap: () => bloc.onFavoriteTap(theater),
                                      ),
                                    ),
                                  ),
                                ),

                                // Delete button
                                /*Positioned(   // TODO remove ?
                                  bottom: 0,
                                  right: 0,
                                  child: Material(
                                    color: Colors.grey,
                                    shape: CornerBorder(CornerBorderPosition.bottomRight),
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: SizedBox.fromSize(
                                      size: Size.square(30),
                                      child: InkWell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: Icon(
                                              Icons.delete_forever,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        onTap: () => bloc.onDeleteTap(theater),
                                      ),
                                    ),
                                  ),
                                ),*/
                              ],
                            ),
                          );
                        },
                        itemCount: snapshot.data!.length,
                        itemExtent: 100,
                      ),
                    ),

                    // Validate button
                    Material(
                      color: selectedCount > 0 ? AppResources.colorLightRed : AppResources.colorDarkGrey,
                      child: InkWell(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text('Appliquer'),
                          )
                        ),
                        onTap:  selectedCount > 0
                          ? () {
                              if (selectedCount > TheatersPageBloc._max) {
                                showMessage(context, 'Maximum ${TheatersPageBloc._max}', isError: true);
                                return;
                              }
                              if (ModalRoute.of(context)!.isFirst) {
                                navigateTo(context, (_) => MoviesPage(bloc.selectedTheaters));
                              } else {
                                Navigator.of(context).pop(bloc.selectedTheaters);
                              }
                            }
                          : null,
                      ),
                    ),
                  ],
                );
              }
            );
          }
        )
      ),
    );
  }

  Widget _buildStatText({required String text, TextAlign? alignment, VoidCallback? onPressed}) {
    return Expanded(
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text,
            textAlign: alignment,
          ),
        ),
        onTap: onPressed,
      ),
    );
  }
}


class TheatersPageBloc with Disposable {
  static const _max = 5;
  final favoriteTheaters = FavoriteTheatersHandler.instance;
  final selectedTheaters = Set<Theater>();

  final theaters = BehaviorSubject<List<Theater>>();

  final isBusySearching = BehaviorSubject.seeded(false);

  TheatersPageBloc(Iterable<Theater>? selectedTheaters) {
    final initialTheaters = Set.of([
      if (selectedTheaters != null) ...selectedTheaters,
      ...favoriteTheaters!.theaters
    ]);
    if (initialTheaters.isNotEmpty) theaters.add(initialTheaters.toList());
    this.selectedTheaters.addAll(selectedTheaters ?? []);
  }

  Future<void> onSearch(String query) async {
    await _searchTheaters(
      () async {
        if (isStringNullOrEmpty(query)) return [];

        // Get Theater list from server
        return await AppService.api.searchTheaters(query);
      }
    );
  }

  Future<void> getGeoLocation() async {
    await _searchTheaters(
      () async {
        // Get geo-position
        geo.Position? position;
        try {
          position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.low, timeLimit: const Duration(seconds: 10));
        } catch(e) {
          if (e is geo.PermissionDeniedException || e is geo.LocationServiceDisabledException)
            throw PermissionDeniedException();
          rethrow;
        }

        // Get local theaters
        return await AppService.api.searchTheatersGeo(position.latitude, position.longitude);
      }
    );
  }

  // TODO migrate to FetchBuilder or AsyncTaskBuilder
  Future<void> _searchTheaters(Future<List<Theater>> Function() task) async {
    if (isBusySearching.value == true)
      return;

    try {
      isBusySearching.add(true);

      // Get Theater list from server
      final result = await task();

      // Build Theater list
      theaters.add(result);
    }
    catch (e, s) {
      // Report error first
      reportError(e, s); // Do not await

      if (!theaters.isClosed)
        theaters.addError(e);
    }
    finally {
      if (!isBusySearching.isClosed)
        isBusySearching.add(false);
    }
  }

  bool isSelected(Theater theater) => selectedTheaters.contains(theater);

  void onSelected(Theater theater) {
    if (isSelected(theater))
      selectedTheaters.remove(theater);
    else
      selectedTheaters.add(theater);

    _refreshList();
  }

  void onFavoriteTap(Theater theater) {
    if (favoriteTheaters!.isFavorite(theater)) {
      favoriteTheaters!.remove(theater);
    } else {
      if (favoriteTheaters!.length >= _max) {
        showMessage(App.navigatorContext, 'Maximum $_max', isError: true);
      } else {
        favoriteTheaters!.add(theater);
      }
    }

    _refreshList();
  }

  /*void onDeleteTap(Theater theater) {  // TODO remove ?
    if (favoriteTheaters!.isFavorite(theater))
      favoriteTheaters!.remove(theater);
    if (isSelected(theater))
      selectedTheaters.remove(theater);

    theaters.add(theaters.value..remove(theater));
  }*/

  void onSelectAll() {
    //Add all to selection
    if (selectedTheaters.length != theaters.value.length)
      selectedTheaters.addAll(theaters.value);

    //clear selection
    else
      selectedTheaters.clear();

    _refreshList();
  }

  _refreshList() => theaters.add(theaters.value);

  @override
  void dispose() {
    theaters.close();
    isBusySearching.close();
    super.dispose();
  }
}