import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DistanceIndicatorWidget extends StatelessWidget {
  final Position? currentPosition;
  final LatLng targetLocation;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color textColor;
  final double elevation;
  final String? unit;

  const DistanceIndicatorWidget({
    super.key,
    this.currentPosition,
    required this.targetLocation,
    this.margin,
    this.borderRadius = 8.0,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.elevation = 2.0,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return const SizedBox.shrink();
    }

    final distance = _calculateDistance();
    if (distance == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8.0),
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            _formatDistance(distance),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  double? _calculateDistance() {
    try {
      return Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDistance(double distanceInMeters) {
    final unit = this.unit ?? 'm';
    
    if (unit == 'km' || distanceInMeters >= 1000) {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    }
  }
} 