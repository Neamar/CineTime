import 'detailed_exception.dart';
import 'package:http/http.dart' as http;
import 'package:sleek_http_client/sleek_http_client.dart' as sleek;

class HttpResponseException extends DetailedException implements sleek.HttpResponseException {
  HttpResponseException(this.response, [this.jsonBody]) : super(
    'Erreur serveur ${response.statusCode}',
    details: '[${response.request?.method}] ${response.request?.url}\n${response.body}',
  );

  @override
  final http.Response response;

  @override
  final dynamic jsonBody;

  @override
  int get statusCode => response.statusCode;

  String get body => response.body;
}
