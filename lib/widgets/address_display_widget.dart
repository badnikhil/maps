import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/bloc/location_bloc.dart';
import '../core/bloc/location_event.dart';
import '../core/bloc/location_state.dart';

class AddressDisplayWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color textColor;
  final double elevation;
  final bool showRefreshButton;
  final String? loadingText;
  final String? errorText;
  final String? placeholderText;

  const AddressDisplayWidget({
    super.key,
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.elevation = 4.0,
    this.showRefreshButton = true,
    this.loadingText = 'Loading address...',
    this.errorText = 'Error loading address',
    this.placeholderText = 'Select a location',
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        return Container(
          margin: margin ?? const EdgeInsets.all(16.0),
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayText(state),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (showRefreshButton) _buildRefreshButton(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDisplayText(LocationState state) {
    if (state.isLoading) {
      return loadingText ?? 'Loading address...';
    }
    
    if (state.error != null) {
      return errorText ?? 'Error loading address';
    }
    
    if (state.hasAddress) {
      return state.address!;
    }
    
    return placeholderText ?? 'Select a location';
  }

  Widget _buildRefreshButton(BuildContext context, LocationState state) {
    return IconButton(
      icon: state.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 20),
      onPressed: state.isLoading ? null : () {
        context.read<LocationBloc>().add(RefreshAddress());
      },
    );
  }
} 