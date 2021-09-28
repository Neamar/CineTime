import 'package:cinetime/models/theater.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/widgets/corner_border.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class TheatersPage extends StatefulWidget {
  const TheatersPage();

  @override
  _TheatersPageState createState() => _TheatersPageState();
}

class _TheatersPageState extends State<TheatersPage> with BlocProvider<TheatersPage, TheatersPageBloc> {
  @override
  initBloc() => TheatersPageBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes cinémas',
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {},
          ),
        ],
      ),
      body: BehaviorSubjectBuilder<List<Theater>>(
        subject: bloc.theaters,
        builder: (context, snapshot) {
          final theaters = snapshot.data!;
          return ListView.builder(
            itemExtent: 100,
            itemCount: theaters.length,
            itemBuilder: (context, index) {
              final theater = theaters[index];
              final isFavorite = bloc.isFavorite(theater);

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
                          Icon(
                            Icons.theaters,
                            size: 50,
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class TheatersPageBloc with Disposable {
  final theaters = BehaviorSubject<List<Theater>>();

  TheatersPageBloc() {
    final initialTheaters = Set.of([
      ...AppService.instance.selectedTheaters,
      ...AppService.instance.favoriteTheaters,
    ]);
    theaters.add(initialTheaters.toList());
  }

  bool isSelected(Theater theater) => AppService.instance.isSelected(theater);
  bool isFavorite(Theater theater) => AppService.instance.isFavorite(theater);

  void onSelected(Theater theater) {
    if (isSelected(theater))
      AppService.instance.unselectTheater(theater);
    else
      AppService.instance.selectTheater(theater);

    _refreshList();
  }

  void onFavoriteTap(Theater theater) {
    if (isFavorite(theater))
      AppService.instance.addToFavorites(theater);
    else
      AppService.instance.removeFromFavorites(theater);

    _refreshList();
  }

  _refreshList() => theaters.reAdd();

  @override
  void dispose() {
    theaters.close();
    super.dispose();
  }
}