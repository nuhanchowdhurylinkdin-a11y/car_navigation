import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class DestinationMarker extends StatelessWidget {
  const DestinationMarker({super.key});

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on,
      size: size,
      color: AppColors.error,
      shadows: [
        Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
      ],
    );
  }
}
