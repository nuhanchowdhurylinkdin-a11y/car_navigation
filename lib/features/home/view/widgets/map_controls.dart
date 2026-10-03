import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.hasLocation,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Surface(
            radius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ControlButton(icon: Icons.add, tooltip: 'Zoom in', onPressed: onZoomIn),
                Container(width: 28, height: 1, color: AppColors.tint),
                _ControlButton(icon: Icons.remove, tooltip: 'Zoom out', onPressed: onZoomOut),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Surface(
            radius: 24,
            child: _ControlButton(
              icon: hasLocation ? Icons.my_location : Icons.location_searching,
              tooltip: 'My location',
              onPressed: onMyLocation,
              color: hasLocation ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 48,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
