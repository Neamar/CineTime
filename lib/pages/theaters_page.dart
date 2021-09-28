import 'package:cinetime/models/theater.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'theater_search_page.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: _goToSearchPage,
        child: const Icon(Icons.add),
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
                key: ValueKey(theater.id.id + bloc.refreshID.toString()),
                theater: theater,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _goToSearchPage() async {
    await navigateTo(context, (_) => TheaterSearchPage(), returnAfterPageTransition: false);
    bloc.refresh();
  }
}


class TheatersPageBloc with Disposable {
  TheatersPageBloc() {
    refresh();
  }

  /// Used to properly refresh widgets
  int refreshID = 0;

  /// List of theaters
  final theaters = BehaviorSubject<List<Theater>>();

  refresh() {
    refreshID++;
    theaters.add(Set.of([
      ...AppService.instance.selectedTheaters,
      ...AppService.instance.favoriteTheaters,
    ]).toList());
  }

  @override
  void dispose() {
    theaters.close();
    super.dispose();
  }
}