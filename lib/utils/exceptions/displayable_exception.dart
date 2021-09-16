/// An exception that may be directly displayed to the user
class DisplayableException implements Exception {
  final String message;

  const DisplayableException(this.message);

  @override
  String toString() => message;
}
