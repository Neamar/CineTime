import '_models.dart';

class Theater extends Identifiable {
  const Theater({
    required ApiId id,
    required this.name,
    this.poster,
    this.street,
    this.zipCode,
    this.city,
    this.distance,
  }) : super(id);

  final String name;
  final String? poster;    // Path to the image (not full url)
  final String? street;
  final String? zipCode;
  final String? city;

  final double? distance;  // Distance to user's position when searching, in km
  String? get distanceDisplay {
    if (distance == null)
      return null;

    if (distance! < 1)
      return '${(distance! * 1000).toInt()}m';

    return '${distance!.toStringAsFixed(1)}km';
  }

  String get fullAddress {
    final lines = <String?>[];
    if (street?.isNotEmpty == true)
      lines.add(street);

    final line2parts = <String?>[];
    if (zipCode?.isNotEmpty == true)
      line2parts.add(zipCode);
    if (city?.isNotEmpty == true)
      line2parts.add(city);

    final line2 = line2parts.join(' ');
    if (line2.isNotEmpty == true)
      lines.add(line2);

    return lines.join('\n');
  }

  factory Theater.fromJson(Map<String, dynamic> json) => Theater(
    id: ApiId.fromEncoded(json['id']),
    name: json['name'],
    poster: json['poster'],
    street: json['street'],
    zipCode: json['zipCode'],
    city: json['city'],
  );
  Map<String, dynamic> toJson() => {
    'id': id.encodedId,
    'name': name,
    'poster': poster,
    'street': street,
    'zipCode': zipCode,
    'city': city,
  };
}