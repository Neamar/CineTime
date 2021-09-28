import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rxdart/rxdart.dart';

class FetchBuilder<T> extends StatefulWidget {
  const FetchBuilder({
    Key? key,
    this.controller,
    required this.task,
    this.fetchingBuilder,
    this.builder,
    this.onSuccess,
    this.isDense = false,
  }) : super(key: key);

  /// Task that fetch and return the data
  /// May throw
  final AsyncTask<T> task;

  /// Optional Widget to display while fetching
  final WidgetBuilder? fetchingBuilder;

  /// Child to display when data is available
  final DataWidgetBuilder<T>? builder;

  /// Called when [task] has completed with success
  final AsyncValueChanged<T>? onSuccess;

  /// A controller used to programmatically show the refresh indicator and call the [onRefresh] callback.
  final FetchBuilderController? controller;

  /// Whether this widget is in a low space environment
  /// Will affect default error widget density
  final bool isDense;

  @override
  _FetchBuilderState createState() => _FetchBuilderState<T>();
}

class _FetchBuilderState<T> extends State<FetchBuilder<T>> {
  final data = BehaviorSubject<T?>();

  @override
  void initState() {
    super.initState();
    _setControllerCallback();
    _fetch();
  }

  @override
  void didUpdateWidget(FetchBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller?._refreshCallback = null;
    _setControllerCallback();
  }

  @override
  Widget build(BuildContext context) {
    return BehaviorSubjectBuilder<T?>(
      subject: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorWidget(
            onRetry: _fetch,
            isDense: widget.isDense,
          );
        } else if (!snapshot.hasData) {
          return widget.fetchingBuilder?.call(context) ?? SpinKitFadingCube(
            color: Theme.of(context).primaryColor,
            size: 25.0,
          );
        } else {
          return widget.builder?.call(context, snapshot.data!) ?? const SizedBox();
        }
      }
    );
  }

  /// Store last started task id
  int _lastFetchTaskId = 0;

  Future<void> _fetch({bool? clearDataFirst}) async {
    // Save task id
    final taskId = ++_lastFetchTaskId;
    final isTaskValid = () => mounted && taskId == _lastFetchTaskId;

    // Skip if disposed
    if (!mounted) return;

    try {
      // Clear current data
      clearDataFirst ??= data.hasError == true;
      if (clearDataFirst) data.add(null);

      // Run task
      final result = await widget.task();

      // Call onSuccess
      if (isTaskValid())
        await widget.onSuccess?.call(result);

      // Update UI
      if (isTaskValid())
        data.add(result);
    } catch (e, s) {
      // Report error first
      reportError(e, s); // Do not await

      // Update UI
      if (isTaskValid()) {
        data.addError(e);
        showError(context, e);
      }
    }
  }

  void _setControllerCallback() {
    widget.controller?._refreshCallback = () => _fetch(clearDataFirst: true);
  }

  @override
  void dispose() {
    widget.controller?._refreshCallback = null;
    data.close();
    super.dispose();
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({Key? key, required this.onRetry, this.isDense = false}) : super(key: key);

  final bool isDense;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDense ? onRetry : null,
      child: Flex(
        mainAxisSize: MainAxisSize.min,
        direction: isDense ? Axis.horizontal : Axis.vertical,
        children: [
          // Icon
          Icon(
            Icons.error_outline,
            color: AppResources.colorRed,
            size: isDense ? null : 40,
          ),

          // Caption
          AppResources.spacerTiny,
          Text('Impossible de récupérer les données'),

          // Retry
          if (isDense)...[
            AppResources.spacerTiny,
            Icon(
              Icons.refresh,
            ),
          ]
          else
            TextButton(
              child: Text('Re-essayer'),
              onPressed: onRetry,
            ),
        ],
      ),
    );
  }
}

class FetchBuilderController {
  AsyncCallback? _refreshCallback;
  Future<void> refresh() {
    assert(_refreshCallback != null);
    return _refreshCallback!();
  }
}
