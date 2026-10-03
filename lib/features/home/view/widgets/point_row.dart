import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';

class PointRow extends StatelessWidget {
  const PointRow({
    super.key,
    required this.leading,
    required this.label,
    required this.point,
    required this.trailing,
    this.filled = false,
  });

  final Widget leading;
  final String label;
  final LatLng? point;
  final Widget trailing;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final target = point;
    return Container(
      padding: EdgeInsets.fromLTRB(filled ? 12 : 0, 4, 0, 4),
      decoration: filled
          ? BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12))
          : null,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if (target != null)
                    TextSpan(
                      text: '(${format(target)})',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  static String format(LatLng point) {
    final lat = '${point.latitude.abs().toStringAsFixed(4)}° ${point.latitude >= 0 ? 'N' : 'S'}';
    final lng = '${point.longitude.abs().toStringAsFixed(4)}° ${point.longitude >= 0 ? 'E' : 'W'}';
    return '$lat, $lng';
  }
}
