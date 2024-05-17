import 'package:cinetime/models/theater.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'theater_search_page.dart';

class TheatersPage extends StatefulWidget {
  const TheatersPage();

  @override
  State<TheatersPage> createState() => _TheatersPageState();
}

class _TheatersPageState extends State<TheatersPage> with BlocProvider<TheatersPage, TheatersPageBloc>, MultiSelectionMode<TheatersPage> {
  @override
  initBloc() => TheatersPageBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes cinémas',
        ),
        actions: <Widget>[
          MultiSelectionModeButton(
            onPressed: toggleSelectionMode,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToSearchPage,
        child: const Icon(CineTimeIcons.plus),
      ),
      body: BehaviorSubjectBuilder<List<Theater>>(
        subject: bloc.theaters,
        builder: (context, snapshot) {
          final theaters = snapshot.data!;
          return ListView.builder(
            itemExtent: TheaterCard.height,
            itemCount: theaters.length,
            itemBuilder: (context, index) {
              final theater = theaters[index];
              return TheaterCard(
                key: ValueKey(theater.id.id + bloc.refreshID.toString()),
                theater: theater,
                multiSelectionMode: multiSelectionMode,
                onLongPress: toggleSelectionMode,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _goToSearchPage() async {
    final singleSelectionMode = await navigateTo<bool>(context, (_) => const TheaterSearchPage());
    if (singleSelectionMode == true) {
      if (mounted) Navigator.pop(context);
    } else {
      autoUpdateSelectionMode();
      bloc.refresh();
    }
  }
}

class MultiSelectionModeButton extends StatelessWidget {
  const MultiSelectionModeButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sélection multiple',
      child: IconButton(
        icon: const Icon(CineTimeIcons.list),
        onPressed: onPressed,
      ),
    );
  }
}

mixin MultiSelectionMode<T extends StatefulWidget> on State<T> {
  bool multiSelectionMode = false;

  @override
  void initState() {
    super.initState();
    multiSelectionMode = AppService.instance.selectedTheaters.length >= 2;
  }

  void autoUpdateSelectionMode() {
    if (!multiSelectionMode && AppService.instance.selectedTheaters.length >= 2) {
      toggleSelectionMode();
    }
  }

  void toggleSelectionMode() {
    // Update UI
    setState(() {
      multiSelectionMode = !multiSelectionMode;
    });

    // Display a message
    showMessage(context, 'Sélection multiple de cinéma ${multiSelectionMode ? 'activée' : 'désactivée'}');
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
    theaters.add({
      ...AppService.instance.selectedTheaters,
      ...AppService.instance.favoriteTheaters,
    }.toList()..sort());
  }

  @override
  void dispose() {
    theaters.close();
    super.dispose();
  }
}