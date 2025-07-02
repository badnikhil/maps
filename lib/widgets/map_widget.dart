import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final Position? currentPosition;
  final Function(LatLng, bool)? onPositionChanged;
  final Function(MapEvent)? onMapEvent;
  final MapController mapController;
  final String? tileUrl;
  final List<String>? subdomains;
  final bool showCurrentLocationMarker;
  final bool enableInteraction;
  final void Function(TapPosition, LatLng)? onTap;

  const MapWidget({
    super.key,
    required this.center,
    required this.zoom,
    this.currentPosition,
    this.onPositionChanged,
    this.onMapEvent,
    required this.mapController,
    this.tileUrl,
    this.subdomains,
    this.showCurrentLocationMarker = true,
    this.enableInteraction = true,
    this.onTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != oldWidget.center) {
      widget.mapController.move(widget.center, widget.zoom);
    } else if (widget.zoom != oldWidget.zoom) {
      widget.mapController.move(widget.mapController.camera.center, widget.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && widget.onPositionChanged != null) {
            widget.onPositionChanged!(position.center, hasGesture);
          }
        },
        onMapEvent: widget.onMapEvent,
        onTap: widget.onTap,
        interactionOptions: InteractionOptions(
          flags: widget.enableInteraction ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        _buildTileLayer(),
        if (widget.showCurrentLocationMarker && widget.currentPosition != null)
          _buildCurrentLocationMarker(),
      ],
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: widget.tileUrl ?? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      subdomains: widget.subdomains ?? const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.example.maps',
      retinaMode: true,
    );
  }

  Widget _buildCurrentLocationMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          width: 32,
          height: 32,
          child: _buildCurrentLocationDot(),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationDot() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
} 