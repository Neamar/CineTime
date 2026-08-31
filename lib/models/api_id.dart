/// Generic identifier for API entities (movies, theaters, videos...).
///
/// Each API provider (country) has its own id encoding scheme. Concrete
/// subclasses are implemented alongside their respective [ApiClient]
/// (e.g. `FranceApiId` in `api_client_fr.dart`, `BelgiumApiId` in `api_client_be.dart`),
/// which own the knowledge of how to build and decode their ids.
abstract class ApiId {
  const ApiId(this.id, this.encodedId);

  /// Unique identifier for the entity, as used by the owning API provider.
  final String id;

  /// Encoded form of [id], as used/persisted by the owning API provider.
  final String encodedId;

  @override
  String toString() => id;

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