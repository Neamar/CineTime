import 'displayable_exception.dart';

class DetailedException extends DisplayableException {
  const DetailedException(super.message, { this.details });

  final Object? details;

  /// Output maximum technical details. Usually for error reporting.
  @override
  String toString() {
    final detailsString = details?.toString();
    return message + (detailsString?.isNotEmpty == true ? '\n$detailsString' : '');
  }
}
