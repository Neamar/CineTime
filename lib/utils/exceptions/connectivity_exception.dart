import 'unreported_exception.dart';

enum ConnectivityExceptionType { noInternet, timeout }

class ConnectivityException with UnreportedException {
  final ConnectivityExceptionType type;

  const ConnectivityException(this.type);
}
