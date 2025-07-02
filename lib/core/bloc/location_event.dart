import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

abstract class LocationEvent {
  const LocationEvent();
}

class RequestLocationPermission extends LocationEvent {}

class GetCurrentLocation extends LocationEvent {}

class UpdateMapPosition extends LocationEvent {
  final LatLng center;
  final double? zoom;

  const UpdateMapPosition(this.center, {this.zoom});
}

class SearchLocation extends LocationEvent {
  final String query;

  const SearchLocation(this.query);
}

class SelectSearchResult extends LocationEvent {
  final LocationModel location;

  const SelectSearchResult(this.location);
}

class RefreshAddress extends LocationEvent {}

class ZoomMap extends LocationEvent {
  final double delta;

  const ZoomMap(this.delta);
}

class LocateMe extends LocationEvent {} 