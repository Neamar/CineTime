import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:cinetime/widgets/update_app_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rxdart/rxdart.dart';

class FetchBuilder<T, R> extends StatefulWidget {
  /// Basic [FetchBuilder] constructor.
  /// Because constructor or factory must be of type <T, R>, we must use a static method instead.
  static FetchBuilder<Never, R> basic<R>({
    Key? key,
    FetchBuilderController<Never, R?>? controller,
    required AsyncTask<R> task,
    bool fetchAtInit = true,
    WidgetBuilder? fetchingBuilder,
    DataWidgetBuilder<R>? builder,
    AsyncValueChanged<R>? onSuccess,
    bool isDense = false,
    bool fade = true,
  }) => FetchBuilder.withParam(
    key: key,
    controller: controller,
    task: (_) => task(),
    fetchAtInit: fetchAtInit,
    fetchingBuilder: fetchingBuilder,
    builder: builder,
    onSuccess: onSuccess,
    isDense: isDense,
    fade: fade,
  );

  /// A [FetchBuilder] where [controller.refresh()] takes a parameter that will be passed to [task].
  const FetchBuilder.withParam({
    super.key,
    this.controller,
    required this.task,
    this.fetchAtInit = true,
    this.fetchingBuilder,
    this.builder,
    this.onSuccess,
    this.isDense = false,
    this.fade = true,
  });

  /// Task that fetch and return the data, with optional parameter
  /// If task throws, it will be properly handled (message displayed + report error)
  final ParameterizedAsyncTask<T, R> task;

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
  State<FetchBuilder<T, R>> createState() => _FetchBuilderState<T, R>();
}

class _FetchBuilderState<T, R> extends State<FetchBuilder<T, R>> {
  final data = BehaviorSubject<_DataWrapper<R>?>();

  @override
  void initState() {
    super.initState();
    widget.controller?._mountState(this);
    if (widget.fetchAtInit) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BehaviorSubjectBuilder<_DataWrapper<R>?>(
      subject: data,
      builder: (context, snapshot) {
        final child = () {
          if (snapshot.hasError) {
            return _ErrorWidget(
              error: snapshot.error as FetchException,
              onRetry: (snapshot.error as FetchException).retry,
              isDense: widget.isDense,
            );
          } else if (!snapshot.hasData) {
            return widget.fetchingBuilder?.call(context) ?? SpinKitFadingCube(
              color: Theme.of(context).primaryColor,
              size: 25.0,
            );
          } else {
            return widget.builder?.call(context, snapshot.data!.data) ?? const SizedBox();
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
    bool isTaskValid() => mounted && taskId == _lastFetchTaskId;

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
        data.add(_DataWrapper(result));
        return result;
      }
    } catch (e, s) {
      // Report error first
      reportError(e, s); // Do not await

      // Update UI
      if (isTaskValid()) {
        data.addError(FetchException(e, () => _fetch(param: param)));
        if (mounted) showError(context, e);
      }
    }
    return null;
  }

  Future<R?> refresh([T? param]) => _fetch(param: param, clearDataFirst: true);

  @override
  void dispose() {
    widget.controller?._unmountState(this);
    data.close();
    super.dispose();
  }
}

/// Small data wrapper, that allow data to be null when himself isn't.
/// Allow to properly handle loading state when data may be null.
class _DataWrapper<T> {
  const _DataWrapper(this.data);

  final T data;
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.error, required this.onRetry, this.isDense = false});

  final FetchException error;
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
            Tooltip(
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              message: error.innerException.toString().replaceAll('all' + 'ocine', '***'),
              child: Icon(
                Icons.error_outline,
                color: AppResources.colorRed,
                size: isDense ? null : 40,
              ),
            ),

            // Caption
            AppResources.spacerTiny,
            const Text('Impossible de récupérer les données'),

            // Retry
            if (isDense)...[
              AppResources.spacerTiny,
              const Icon(Icons.refresh),
            ]
            else
              TextButton(
                onPressed: onRetry,
                child: const Text('Re-essayer'),
              ),

            // Update app
            if (!isDense)...[
              AppResources.spacerMedium,
              const UpdateAppWidget(),
            ],
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

/// A controller for an FetchBuilder.
///
/// One support one widget per controller.
/// If multiple widget are using the same controller, only the last one will work.
class FetchBuilderController<T, R> {
  _FetchBuilderState<T, R>? _state;

  void _mountState(_FetchBuilderState<T, R> state) {
    _state = state;
  }

  void _unmountState(_FetchBuilderState<T, R> state) {
    /// When a widget is rebuilt with another key,
    /// the state of the new widget is first initialised,
    /// then the state of the old widget is disposed.
    /// So we need to unmount state only if it hasn't changed since.
    if (_state == state)
      _state = null;
  }

  Future<R?> refresh([T? param]) => _state!.refresh(param);
}
