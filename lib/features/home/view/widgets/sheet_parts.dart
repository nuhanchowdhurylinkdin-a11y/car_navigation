import 'package:flutter/material.dart';

import '../../../../core/utils/constants/colors.dart';

class SheetPanel extends StatelessWidget {
  const SheetPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.color,
    this.icon,
    this.loading = false,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Color color;
  final IconData? icon;
  final bool loading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: color),
                )
              : Icon(icon, size: 26, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class SheetTextButton extends StatelessWidget {
  const SheetTextButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
