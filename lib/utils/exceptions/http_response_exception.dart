import 'detailed_exception.dart';
import 'package:http/http.dart' as http;

class HttpResponseException extends DetailedException {
  HttpResponseException(this.response) : super(
    'Erreur serveur',
    details: '[${response.request?.method}] ${response.request?.url}\n${response.body}',
  );

  final http.Response response;
  int get statusCode => response.statusCode;
  String get body => response.body;
}
