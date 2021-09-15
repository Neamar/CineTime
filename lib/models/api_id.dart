import 'package:cinetime/utils/_utils.dart';
class ApiId {
  static const TypeTheater = 'Theater';

  ApiId(this.id, String type) : encodedId = '$type:$id'.toBase64();
  ApiId.fromEncoded(this.encodedId) : id = _decodeId(encodedId);

  /// Base64 encoded [code]
  /// Decoded examples : 'Movie:133392', 'Theater:C0026', 'Video:brand.video_legacy.AC.19589606'
  final String encodedId;

  /// API codes may be int or string.
  /// Examples : 133392 (movie), 'P0671' (theater)
  final String id;

  /// Decode an encoded id
  static String _decodeId(String id) {
    final decoded = id.decodeBase64();
    return decoded.substring(decoded.indexOf(':') + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ApiId &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

abstract class Identifiable {
  const Identifiable(this.id);

  final ApiId id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Identifiable &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}