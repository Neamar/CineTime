import 'package:cinetime/utils/_utils.dart';

/// HTTP method enum, mirroring `sleek_http_client`'s `HttpMethod`.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

/// Abstract HTTP client interface.
///
/// This interface is designed to be compatible with `sleek_http_client`'s
/// `SleekHttpClient` API, so that the concrete implementation can later be
/// swapped with minimal changes.
///
/// The type parameter [T] controls the return type:
/// - `JsonObject` (`Map<String, dynamic>`) — decoded JSON object
/// - `JsonList` (`Iterable<dynamic>`) — decoded JSON list
/// - `String` — raw response body
/// - `void` / omitted — body is ignored, returns null
abstract class AppHttpClient {
  /// Send an HTTP request.
  ///
  /// [method] is the HTTP method to use.
  /// [url] is the full URL to send the request to.
  /// [headers] are additional headers to include.
  /// [bodyJson] is the JSON body to send (encoded automatically).
  /// [useCache] controls whether to use cached responses.
  Future<T> send<T>(
    HttpMethod method,
    String url, {
    Map<String, String>? headers,
    JsonObject? bodyJson,
    String? stringBody,
    bool useCache = true,
  });
}
