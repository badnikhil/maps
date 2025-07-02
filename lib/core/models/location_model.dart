import 'package:latlong2/latlong.dart';

class LocationModel {
  final LatLng coordinates;
  final String address;
  final String? placeId;
  final Map<String, dynamic>? additionalData;

  const LocationModel({
    required this.coordinates,
    required this.address,
    this.placeId,
    this.additionalData,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      coordinates: LatLng(
        json['lat']?.toDouble() ?? 0.0,
        json['lng']?.toDouble() ?? 0.0,
      ),
      address: json['address'] ?? '',
      placeId: json['place_id'],
      additionalData: json['additional_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'address': address,
      'place_id': placeId,
      'additional_data': additionalData,
    };
  }

  LocationModel copyWith({
    LatLng? coordinates,
    String? address,
    String? placeId,
    Map<String, dynamic>? additionalData,
  }) {
    return LocationModel(
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.coordinates == coordinates &&
        other.address == address &&
        other.placeId == placeId;
  }

  @override
  int get hashCode {
    return coordinates.hashCode ^
        address.hashCode ^
        placeId.hashCode;
  }

  @override
  String toString() {
    return 'LocationModel(coordinates: $coordinates, address: $address, placeId: $placeId)';
  }
} 