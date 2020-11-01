import 'package:json_annotation/json_annotation.dart';
import '_models.dart';

part 'theater.g.dart';

@JsonSerializable()
class Theater extends Identifiable {
  final String name;
  final String poster;    // Path to the image (not full url)
  final String street;
  final String zipCode;
  final String city;

  @JsonKey(ignore: true)
  final double distance;  // Distance to user's position when searching, in km
  String get distanceDisplay {
    if (distance == null)
      return null;

    if (distance < 1)
      return '${(distance * 1000).toInt()}m';

    return '${distance.toStringAsFixed(1)}km';
  }

  const Theater({
    String code,
    this.name,
    this.poster,
    this.street,
    this.zipCode,
    this.city,
    this.distance,
  }) : super(code);

  String get fullAddress {
    final lines = List<String>();
    if (street?.isNotEmpty == true)
      lines.add(street);

    final line2parts = List<String>();
    if (zipCode?.isNotEmpty == true)
      line2parts.add(zipCode);
    if (city?.isNotEmpty == true)
      line2parts.add(city);

    final line2 = line2parts.join(' ');
    if (line2?.isNotEmpty == true)
      lines.add(line2);

    return lines.join('\n');
  }

  factory Theater.fromJson(Map<String, dynamic> json) => _$TheaterFromJson(json);
  Map<String, dynamic> toJson() => _$TheaterToJson(this);
}