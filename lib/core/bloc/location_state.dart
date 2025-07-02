import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

class LocationState {
  final bool isLoading;
  final String? error;
  final Position? currentPosition;
  final LatLng mapCenter;
  final double zoom;
  final String? address;
  final List<LocationModel> searchResults;
  final bool hasPermission;

  const LocationState({
    this.isLoading = false,
    this.error,
    this.currentPosition,
    this.mapCenter = const LatLng(0, 0),
    this.zoom = 15.0,
    this.address,
    this.searchResults = const [],
    this.hasPermission = false,
  });

  LocationState copyWith({
    bool? isLoading,
    String? error,
    Position? currentPosition,
    LatLng? mapCenter,
    double? zoom,
    String? address,
    List<LocationModel>? searchResults,
    bool? hasPermission,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPosition: currentPosition ?? this.currentPosition,
      mapCenter: mapCenter ?? this.mapCenter,
      zoom: zoom ?? this.zoom,
      address: address ?? this.address,
      searchResults: searchResults ?? this.searchResults,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  /// Get the effective center (current position if available, otherwise map center)
  LatLng get effectiveCenter {
    if (currentPosition != null) {
      return LatLng(currentPosition!.latitude, currentPosition!.longitude);
    }
    return mapCenter;
  }

  /// Check if location is valid
  bool get hasValidLocation => mapCenter.latitude != 0 && mapCenter.longitude != 0;

  /// Check if current position is available
  bool get hasCurrentPosition => currentPosition != null;

  /// Check if address is available
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Check if there are search results
  bool get hasSearchResults => searchResults.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.currentPosition == currentPosition &&
        other.mapCenter == mapCenter &&
        other.zoom == zoom &&
        other.address == address &&
        other.searchResults == searchResults &&
        other.hasPermission == hasPermission;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        error.hashCode ^
        currentPosition.hashCode ^
        mapCenter.hashCode ^
        zoom.hashCode ^
        address.hashCode ^
        searchResults.hashCode ^
        hasPermission.hashCode;
  }

  @override
  String toString() {
    return 'LocationState(isLoading: $isLoading, error: $error, currentPosition: $currentPosition, mapCenter: $mapCenter, zoom: $zoom, address: $address, searchResults: ${searchResults.length}, hasPermission: $hasPermission)';
  }
} 