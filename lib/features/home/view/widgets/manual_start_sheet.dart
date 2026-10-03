import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';
import 'point_row.dart';
import 'sheet_parts.dart';
import 'start_marker.dart';

/// Guides the user through picking a start (A) and destination (B) on the map
/// when device location is unavailable.
class ManualStartSheet extends StatelessWidget {
  const ManualStartSheet({
    super.key,
    required this.start,
    required this.onChangeStart,
    required this.onUseMyLocation,
  });

  final LatLng? start;
  final VoidCallback onChangeStart;
  final VoidCallback onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    final picked = start;
    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: picked == null ? 'MANUAL START · STEP 1 OF 2' : 'MANUAL START · STEP 2 OF 2',
          title: picked == null
              ? 'Long-press the map to set your start point'
              : 'Now long-press to set the destination',
          subtitle: picked == null
              ? 'Your location isn\'t available, so pick where the route should begin.'
              : 'The route will be calculated from your start point (A).',
          color: AppColors.success,
          icon: picked == null ? Icons.trip_origin_rounded : Icons.flag_rounded,
        ),
        if (picked != null) ...[
          const SizedBox(height: 16),
          PointRow(
            leading: const StartMarker(diameter: 22),
            label: 'From: Start point',
            point: picked,
            filled: true,
            trailing: SheetTextButton(label: 'Change', onPressed: onChangeStart),
          ),
        ],
        const SizedBox(height: 12),
        SheetTextButton(label: 'Try using my location again', onPressed: onUseMyLocation),
      ],
    );
  }
}
