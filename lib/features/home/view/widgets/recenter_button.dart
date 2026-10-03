import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class RecenterButton extends StatelessWidget {
  const RecenterButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.navigation_rounded, size: 18),
        label: const Text('Recenter'),
      ),
    );
  }
}
