import 'unreported_exception.dart';

class OperationCanceledException with UnreportedException {
  const OperationCanceledException({this.silent = false});

  /// Whether this exception should be displayed to the user or not
  final bool silent;
}
