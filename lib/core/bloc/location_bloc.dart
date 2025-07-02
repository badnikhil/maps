import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  Timer? _debounceTimer;
  String _latestQuery = '';

  LocationBloc(this._locationService) : super(const LocationState()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<UpdateMapPosition>(_onUpdateMapPosition);
    on<SearchLocation>(_onSearchLocation);
    on<SelectSearchResult>(_onSelectSearchResult);
    on<RefreshAddress>(_onRefreshAddress);
    on<ZoomMap>(_onZoomMap);
    on<LocateMe>(_onLocateMe);
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      await _locationService.requestLocationPermission();
      emit(state.copyWith(isLoading: false, hasPermission: true));
      add(GetCurrentLocation());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasPermission: false,
      ));
    }
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      final position = await _locationService.getCurrentLocation();
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      emit(state.copyWith(
        isLoading: false,
        currentPosition: position,
        mapCenter: LatLng(position.latitude, position.longitude),
        address: address,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onUpdateMapPosition(
    UpdateMapPosition event,
    Emitter<LocationState> emit,
  ) {
    emit(state.copyWith(
      mapCenter: event.center,
      zoom: event.zoom ?? state.zoom,
    ));
    add(RefreshAddress());
  }

  Future<void> _onSearchLocation(
    SearchLocation event,
    Emitter<LocationState> emit,
  ) async {
    _debounceTimer?.cancel();
    final query = event.query.trim();
    _latestQuery = query;

    if (query.isEmpty) {
      emit(state.copyWith(searchResults: [], isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await _locationService.searchLocations(query);
      if (_latestQuery == query) {
        emit(state.copyWith(searchResults: results, isLoading: false));
      } else {
        // Ignore this result, a newer query is in progress
      }
    });
  }

  Future<void> _onSelectSearchResult(
    SelectSearchResult event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final locationDetails = await _locationService.getLocationDetails(
        event.location.coordinates,
      );
      
      emit(state.copyWith(
        isLoading: false,
        mapCenter: event.location.coordinates,
        address: locationDetails.address,
        searchResults: [],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshAddress(
    RefreshAddress event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final address = await _locationService.getAddressFromCoordinates(
        state.mapCenter.latitude,
        state.mapCenter.longitude,
      );
      
      emit(state.copyWith(
        isLoading: false,
        address: address,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onZoomMap(
    ZoomMap event,
    Emitter<LocationState> emit,
  ) {
    final newZoom = (state.zoom + event.delta).clamp(10.0, 18.0);
    emit(state.copyWith(zoom: newZoom));
  }

  Future<void> _onLocateMe(
    LocateMe event,
    Emitter<LocationState> emit,
  ) async {
    add(GetCurrentLocation());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
} 