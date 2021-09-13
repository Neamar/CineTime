class DetailedException implements Exception {
  // Technical message
  final String message;

  // Technical details (only exported in toStringVerbose())
  final Object? details;

  const DetailedException(this.message, {this.details});

  @override
  String toString() => message;

  /// Output maximum technical details. Usually for error reporting.
  String toStringVerbose() {
    final detailsString = ((details is DetailedException) ? (details as DetailedException).toStringVerbose() : details?.toString());
    return toString() + (detailsString?.isNotEmpty == true ? '\n$detailsString' : '');
  }
}
