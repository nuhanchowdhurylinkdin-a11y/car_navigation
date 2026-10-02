import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/map_constants.dart';

/// Required OpenStreetMap credit. Placed by the screen (not inside the map)
/// so it always sits above the bottom sheet and stays visible.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(MapConstants.osmCopyrightUrl)),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '© OpenStreetMap contributors',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
