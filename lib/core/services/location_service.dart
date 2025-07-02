import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String nominatimEndpoint = 'https://nominatim.openstreetmap.org/search';
  LocationService();

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    return true;
  }

  /// Get current location
  Future<Position> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw Exception('Unable to get current location');
    }
  }

  /// Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return _formatAddress(place);
      }
      throw Exception('Address not found');
    } catch (e) {
      throw Exception('Address not found');
    }
  }

  /// Search locations by query using Nominatim
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      final uri = Uri.parse(nominatimEndpoint).replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '8',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'YourAppName/1.0 (your@email.com)'
      });
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<LocationModel>((item) {
          final lat = double.tryParse(item['lat'] ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon'] ?? '') ?? 0.0;
          final displayName = item['display_name'] ?? '';
          return LocationModel(
            coordinates: LatLng(lat, lon),
            address: displayName,
            placeId: item['osm_id']?.toString(),
            additionalData: item,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get detailed location information
  Future<LocationModel> getLocationDetails(LatLng coordinates) async {
    try {
      String address = await getAddressFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      return LocationModel(
        coordinates: coordinates,
        address: address,
      );
    } catch (e) {
      throw Exception('Address not found');
    }
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street?.isNotEmpty == true) {
      addressParts.add(place.street!);
    }
    if (place.subLocality?.isNotEmpty == true) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality?.isNotEmpty == true) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      addressParts.add(place.administrativeArea!);
    }

    return addressParts.join(', ');
  }
} 