import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class MapHint extends StatelessWidget {
  const MapHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
