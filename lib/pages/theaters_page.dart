import 'package:cinetime/helpers/tools.dart';
import 'package:cinetime/models/_models.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/services/storage_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

import '_pages.dart';

class TheatersPage extends StatefulWidget {
  final Iterable<Theater>? selectedTheaters;

  const TheatersPage({ this.selectedTheaters });

  @override
  _TheatersPageState createState() => _TheatersPageState();
}

class _TheatersPageState extends State<TheatersPage> {
  late TheatersPageBloc _bloc;

  @override
  void initState() {
    _bloc = TheatersPageBloc(widget.selectedTheaters);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Nom ou adresse',
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _bloc.onSearch,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _bloc.getGeoLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: BehaviorStreamBuilder<bool>(
          subject: _bloc.isBusySearching,
          builder: (context, isBusySnapshot) {

            // Is loading
            if (isBusySnapshot.data!)
              return CtProgressIndicator();

            // Is NOT loading
            return BehaviorStreamBuilder<List<Theater>>(
              subject: _bloc.theaters,
              builder: (context, snapshot) {

                // Error
                if (snapshot.hasError)
                  return IconMessage(
                    icon: IconMessage.iconError,
                    message: 'Impossible de récuperer les données',
                    tooltip: snapshot.error.toString(),
                    redIcon: true,
                  );

                // No data
                if (snapshot.data == null)
                  return IconMessage(
                    icon: FontAwesomeIcons.search,
                    message: 'Cherchez par nom ou par localisation',
                  );

                // Empty list
                if (snapshot.data!.isEmpty)
                  return IconMessage(
                    icon: IconMessage.iconSad,
                    message: 'Aucun résultat',
                  );

                // Has data
                var selectedCount = _bloc.selectedTheaters.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[

                    // Stat texts
                    Material(
                      color: Colors.deepPurpleAccent,
                      child: Row(
                        children: <Widget>[
                          _buildStatText(
                            text: plural(snapshot.data!.length, 'résultat'),
                            alignment: TextAlign.start,
                          ),
                          _buildStatText(
                            text: plural(selectedCount, 'selectionné'),
                            alignment: TextAlign.center,
                            onPressed: _bloc.onSelectAll
                          ),
                          _buildStatText(
                            text: plural(_bloc.favoriteTheaters!.theaters.length, 'favori'),
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
                          var isFavorite = _bloc.favoriteTheaters!.isFavorite(theater);

                          return Card(
                            key: ObjectKey(theater),
                            color: _bloc.isSelected(theater) ? Colors.lightBlueAccent : null,
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
                                  onTap: () => _bloc.onSelected(theater),
                                ),

                                // Star button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Material(
                                    color: isFavorite ? Colors.redAccent : Colors.white,
                                    shape: CornerBorder(),
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
                                        onTap: () => _bloc.onFavoriteTap(theater),
                                      ),
                                    ),
                                  ),
                                )
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
                      color: selectedCount > 0 ? Colors.redAccent : Colors.grey,
                      child: InkWell(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text('Ajouter les ${plural(selectedCount, 'cinéma')} aux filtres'),
                          )
                        ),
                        onTap:  selectedCount > 0 ?
                          () {
                            if (ModalRoute.of(context)!.isFirst)
                              navigateTo(context, () => MoviesPage(_bloc.selectedTheaters));
                            else
                              Navigator.of(context).pop(_bloc.selectedTheaters);
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

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}

class TheatersPageBloc with Disposable {
  final favoriteTheaters = FavoriteTheatersHandler.instance;
  final selectedTheaters = Set<Theater>();

  final theaters = BehaviorSubject<List<Theater>>();

  final isBusySearching = BehaviorSubject.seeded(false);

  TheatersPageBloc(Iterable<Theater>? selectedTheaters) {
    final initialTheaters = Set.of([
      if (selectedTheaters != null) ...selectedTheaters,
      ...favoriteTheaters!.theaters
    ]);
    theaters.add(initialTheaters.toList(growable: false));
  }

  Future<void> onSearch(String query) async {
    await _searchTheaters(
      () async {
        // Get Theater list from server
        return await AppService.api.searchTheaters(query);
      }
    );
  }

  Future<void> getGeoLocation() async {
    await _searchTheaters(
      () async {
        // Get geo-position
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 10));

        // Get local theaters
        final theaters = await AppService.api.searchTheatersGeo(position.latitude, position.longitude);

        return theaters;
      }
    );
  }

  Future<void> _searchTheaters(Future<List<Theater>> Function() task) async {
    if (isBusySearching.value == true)
      return;

    try {
      isBusySearching.add(true);

      // Get Theater list from server
      var result = await task();

      // Build Theater list
      theaters.add(result);
    }
    catch (e) {
      debugPrint('SearchPage.searchTheaters.Error : $e');

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
    if (favoriteTheaters!.isFavorite(theater))
      favoriteTheaters!.remove(theater);
    else
      favoriteTheaters!.add(theater);

    _refreshList();
  }

  void onSelectAll() {
    //Add all to selection
    if (selectedTheaters.length != theaters.value.length)
      selectedTheaters.addAll(theaters.value);

    //clear selection
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

/*
class SelectableItem<T> {
  final T item;
  bool isSelected = false;
  bool isFavorite = false;

  SelectableItem(this.item);
}*/