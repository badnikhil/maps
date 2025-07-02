import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../core/bloc/location_bloc.dart';
import '../core/bloc/location_event.dart';
import '../core/bloc/location_state.dart';
import '../core/services/location_service.dart';
import '../widgets/map_widget.dart';
import '../widgets/location_search_widget.dart';
import '../widgets/map_controls_widget.dart';
import '../widgets/address_display_widget.dart';
import '../widgets/distance_indicator_widget.dart';

class LocationPickerScreen extends StatefulWidget {
  final Function(String address, double lat, double lng)? onLocationSelected;
  final String title;
  final String confirmButtonText;
  final Color primaryColor;
  final bool showDistanceIndicator;
  final bool showSearchBar;
  final bool showMapControls;

  const LocationPickerScreen({
    super.key,
    this.onLocationSelected,
    this.title = 'Select Location',
    this.confirmButtonText = 'Confirm Location',
    this.primaryColor = const Color(0xFF00B761),
    this.showDistanceIndicator = true,
    this.showSearchBar = true,
    this.showMapControls = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  final bool _isCheckingServiceability = false;
  bool? _isServiceable;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Update delivery location in backend
  Future<void> _updateDeliveryLocation(String address, double lat, double lng) async {
    try {
      // Simulate API call to update delivery location
      print(' Updating delivery location in backend...');
      
    } catch (e) {
      print(' Failed to update delivery location: $e');
      rethrow;
    }
  }

  /// Check if location is serviceable - replace with your backend call
 bool _checkLocationServiceability(String address, double lat, double lng)  {
    try {
      print(_isServiceable! ? ' Serviceable' : ' Not serviceable');
     return true;
      
    } catch (e) {
      
      print(' Error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationBloc(LocationService())
        ..add(RequestLocationPermission()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            // Check serviceability when address changes
            if (state.hasAddress && 
                state.address != null && 
                !_isCheckingServiceability && 
                _isServiceable == null) {
              _checkLocationServiceability(
                state.address!,
                state.mapCenter.latitude,
                state.mapCenter.longitude,
              );
            }
          },
          child: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
            return Stack(
              children: [
                // Map background
                SizedBox.expand(
                  child: MapWidget(
                    center: state.mapCenter,
                    zoom: state.zoom,
                    currentPosition: state.currentPosition,
                    mapController: _mapController,
                    onMapEvent: (event) => _onMapEvent(event, context, state),
                    onTap: (tapPosition, latLng) {
                      context.read<LocationBloc>().add(UpdateMapPosition(latLng));
                    },
                  ),
                ),
                
                // Delivery target pin (center)
                _buildTargetPin(),
                
                // Search bar
                if (widget.showSearchBar)
                  Positioned(
                    top: 48,
                    left: 0,
                    right: 0,
                    child: LocationSearchWidget(
                      onLocationSelected: (location) {
                        widget.onLocationSelected?.call(
                          location.address,
                          location.coordinates.latitude,
                          location.coordinates.longitude,
                        );
                      },
                    ),
                  ),
                
                // Map controls
                if (widget.showMapControls)
                  MapControlsWidget(),
                
                // Address display and distance indicator
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Distance indicator
                      if (widget.showDistanceIndicator)
                        DistanceIndicatorWidget(
                          currentPosition: state.currentPosition,
                          targetLocation: state.mapCenter,
                        ),
                      
                      // Serviceability indicator
                      if (state.hasAddress && !state.isLoading)
                        _buildServiceabilityIndicator(),
                      
                      // Address display
                      AddressDisplayWidget(),
                    ],
                  ),
                ),
                
                // Confirm button
                _buildConfirmButton(state),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildTargetPin() {
    return IgnorePointer(
      child: Center(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Blue shadow at the base
            Positioned(
              top: 38,
              child: Container(
                width: 28,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Black pin
            const Icon(
              Icons.place,
              size: 48,
              color: Colors.black,
            ),
            // Small white inner circle
            Positioned(
              top: 14,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(LocationState state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: state.hasAddress && !state.isLoading && state.error == null
                  ? () async {
                      try {
                        // Check if location is serviceable first
                        bool isServiceable = await _checkLocationServiceability(
                          state.address!,
                          state.mapCenter.latitude,
                          state.mapCenter.longitude,
                        );
                        
                        if (!isServiceable) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Sorry, delivery is not available to this location'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          return;
                        }
                        
                        // Location is serviceable, proceed with confirmation
                        print('✅ Proceeding with location confirmation...');
                        
                        // Update delivery location in backend
                        await _updateDeliveryLocation(
                          state.address!,
                          state.mapCenter.latitude,
                          state.mapCenter.longitude,
                        );
                        
                        // Call the callback if provided
                        widget.onLocationSelected?.call(
                          state.address!,
                          state.mapCenter.latitude,
                          state.mapCenter.longitude,
                        );
                        
                        // Navigate back with result
                        if (mounted) {
                          Navigator.of(context).pop({
                            'address': state.address,
                            'latitude': state.mapCenter.latitude,
                            'longitude': state.mapCenter.longitude,
                            'serviceable': true,
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to process location: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.confirmButtonText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceabilityIndicator() {
    if (_isCheckingServiceability) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Checking delivery availability...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_isServiceable == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isServiceable! ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isServiceable! ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _isServiceable! ? 'Delivery available' : 'Delivery not available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapEvent(MapEvent event, BuildContext context, LocationState state) {
    if (event is MapEventMoveEnd || event is MapEventMoveStart) {
      final newCenter = _mapController.camera.center;
      final newZoom = _mapController.camera.zoom;
      if (newCenter != state.mapCenter || newZoom != state.zoom) {
        context.read<LocationBloc>().add(UpdateMapPosition(newCenter, zoom: newZoom));
      }
    }
  }
} 