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
              return TheaterCard(
                key: ObjectKey(theater),
                theater: theater,
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

  _refreshList() => theaters.reAdd();

  @override
  void dispose() {
    theaters.close();
    super.dispose();
  }
}