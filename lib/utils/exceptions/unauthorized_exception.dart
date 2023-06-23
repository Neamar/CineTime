class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = '']);

  final String message;

  @override
  String toString() => message;
}
