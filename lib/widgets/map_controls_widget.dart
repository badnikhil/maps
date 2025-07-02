import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/bloc/location_bloc.dart';
import '../core/bloc/location_event.dart';

class MapControlsWidget extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final double buttonSize;
  final double spacing;
  final Color backgroundColor;
  final Color iconColor;
  final double elevation;
  final bool showZoomControls;
  final bool showLocateButton;

  const MapControlsWidget({
    super.key,
    this.margin,
    this.buttonSize = 40.0,
    this.spacing = 12.0,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.elevation = 3.0,
    this.showZoomControls = true,
    this.showLocateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: margin?.resolve(TextDirection.ltr).right ?? 16.0,
      top: margin?.resolve(TextDirection.ltr).top ?? 180.0,
      child: Column(
        children: [
          if (showZoomControls) ...[
            _buildZoomButton(
              context,
              icon: Icons.add,
              onPressed: () => context.read<LocationBloc>().add(const ZoomMap(1)),
            ),
            SizedBox(height: spacing),
            _buildZoomButton(
              context,
              icon: Icons.remove,
              onPressed: () => context.read<LocationBloc>().add(const ZoomMap(-1)),
            ),
            SizedBox(height: spacing),
          ],
          if (showLocateButton)
            _buildLocateButton(context),
        ],
      ),
    );
  }

  Widget _buildZoomButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      heroTag: 'zoom_${icon.codePoint}',
      mini: true,
      backgroundColor: backgroundColor,
      elevation: elevation,
      onPressed: onPressed,
      child: Icon(icon, color: iconColor),
    );
  }

  Widget _buildLocateButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'locate_me',
      mini: true,
      backgroundColor: backgroundColor,
      elevation: elevation,
      onPressed: () {
        context.read<LocationBloc>().add(LocateMe());
      },
      child: Icon(Icons.my_location, color: iconColor),
    );
  }
} 