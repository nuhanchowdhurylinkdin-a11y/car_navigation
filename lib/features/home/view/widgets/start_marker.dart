import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class StartMarker extends StatelessWidget {
  const StartMarker({super.key, this.diameter = size});

  static const double size = 34;

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: diameter * 0.09),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        'A',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: diameter * 0.42,
          height: 1,
        ),
      ),
    );
  }
}
