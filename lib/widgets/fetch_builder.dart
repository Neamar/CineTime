import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rxdart/rxdart.dart';

typedef AsyncTask<T, R> = Future<R> Function(T? param);

class FetchBuilder<T, R> extends StatefulWidget {
  const FetchBuilder({
    Key? key,
    this.controller,
    required this.task,
    this.fetchAtInit = true,
    this.fetchingBuilder,
    this.builder,
    this.onSuccess,
    this.isDense = false,
    this.fade = true,
  }) : super(key: key);

  /// Task that fetch and return the data, with optional parameter
  /// If task throws, it will be properly handled (message displayed + report error)
  final AsyncTask<T, R> task;

  /// Whether to automatically start [task] when widget is initialised.
  final bool fetchAtInit;

  /// Optional Widget to display while fetching
  final WidgetBuilder? fetchingBuilder;

  /// Child to display when data is available
  final DataWidgetBuilder<R>? builder;

  /// Called when [task] has completed with success
  final AsyncValueChanged<R>? onSuccess;

  /// A controller used to programmatically show the refresh indicator and call the [onRefresh] callback.
  final FetchBuilderController<T, R?>? controller;

  /// Whether this widget is in a low space environment
  /// Will affect default error widget density
  final bool isDense;

  /// Whether to enable a fading transition
  final bool fade;

  @override
  _FetchBuilderState createState() => _FetchBuilderState<T, R>();
}

class _FetchBuilderState<T, R> extends State<FetchBuilder<T, R>> {
  final data = BehaviorSubject<R?>();

  @override
  void initState() {
    super.initState();
    _setControllerCallback();
    if (widget.fetchAtInit) _fetch();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller?._refreshCallback = null;
    _setControllerCallback();
  }

  @override
  Widget build(BuildContext context) {
    return BehaviorSubjectBuilder<R?>(
      subject: data,
      builder: (context, snapshot) {
        final child = () {
          if (snapshot.hasError) {
            return _ErrorWidget(
              onRetry: (snapshot.error as FetchException).retry,
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
        } ();

        if (widget.fade)
          return CtAnimatedSwitcher(
            child: child,
          );

        return child;
      }
    );
  }

  /// Store last started task id
  int _lastFetchTaskId = 0;

  Future<R?> _fetch({T? param, bool? clearDataFirst}) async {
    // Save task id
    final taskId = ++_lastFetchTaskId;
    final isTaskValid = () => mounted && taskId == _lastFetchTaskId;

    // Skip if disposed
    if (!mounted) return null;

    try {
      // Clear current data
      clearDataFirst ??= data.hasError == true;
      if (clearDataFirst) data.add(null);

      // Run task
      final result = await widget.task(param);

      // Call onSuccess
      if (isTaskValid())
        await widget.onSuccess?.call(result);

      // Update UI
      if (isTaskValid()) {
        data.add(result);
        return result;
      }
    } catch (e, s) {
      // Report error first
      reportError(e, s); // Do not await

      // Update UI
      if (isTaskValid()) {
        data.addError(FetchException(e, () => _fetch(param: param)));
        showError(context, e);
      }
    }
  }

  void _setControllerCallback() {
    widget.controller?._refreshCallback = (param) => _fetch(param: param, clearDataFirst: true);
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
    return Center(
      child: InkWell(
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
      ),
    );
  }
}

class FetchException {
  const FetchException(this.innerException, this.retry);

  final Object innerException;
  final VoidCallback retry;
}

class FetchBuilderController<T, R> {
  AsyncTask<T, R?>? _refreshCallback;
  Future<R?> refresh([T? param]) {
    assert(_refreshCallback != null);
    return _refreshCallback!(param);
  }
}
