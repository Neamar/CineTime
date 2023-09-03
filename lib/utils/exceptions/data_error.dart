/// An exception that is thrown when there is an error with the provided data.
/// Usually not a critical error, handled by UI, but it is useful to report it.
class DataError implements Exception {
  const DataError([this.message = '']);

  final String message;

  @override
  String toString() => message;
}
