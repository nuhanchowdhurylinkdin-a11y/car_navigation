import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../directions/utils/route_format.dart';
import '../../../navigation/logic/navigation_simulator.dart';
import 'sheet_parts.dart';

class NavigationSheet extends StatelessWidget {
  const NavigationSheet({
    super.key,
    required this.state,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.totalMeters,
    required this.routeSeconds,
    required this.progress,
    required this.multiplier,
    required this.onTogglePause,
    required this.onReset,
    required this.onMultiplierChanged,
    required this.onDriveAgain,
    required this.onNewDestination,
  });

  final NavigationState state;
  final double remainingMeters;
  final double remainingSeconds;
  final double totalMeters;
  final double routeSeconds;
  final double progress;
  final int multiplier;
  final VoidCallback onTogglePause;
  final VoidCallback onReset;
  final ValueChanged<int> onMultiplierChanged;
  final VoidCallback onDriveAgain;
  final VoidCallback onNewDestination;

  @override
  Widget build(BuildContext context) {
    return state == NavigationState.finished ? _arrived(context) : _driving(context);
  }

  Widget _driving(BuildContext context) {
    final paused = state == NavigationState.paused;
    final eta = DateTime.now().add(Duration(seconds: remainingSeconds.round()));
    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: paused ? 'PAUSED' : 'SIMULATED DRIVE',
          title: paused ? 'Drive paused' : 'Heading to destination',
          color: paused ? AppColors.warning : AppColors.accent,
          icon: paused ? Icons.pause_rounded : Icons.navigation_rounded,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _Stat(value: RouteFormat.distance(remainingMeters), label: 'REMAINING')),
            Expanded(child: _Stat(value: RouteFormat.duration(remainingSeconds), label: 'TIME LEFT')),
            Expanded(child: _Stat(value: DateFormat.jm().format(eta), label: 'ETA')),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            color: paused ? AppColors.warning : AppColors.accent,
            backgroundColor: AppColors.tint,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _RoundButton(
              icon: Icons.replay_rounded,
              tooltip: 'Reset',
              onPressed: onReset,
            ),
            const SizedBox(width: 12),
            _RoundButton(
              icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              tooltip: paused ? 'Resume' : 'Pause',
              onPressed: onTogglePause,
              filled: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SpeedSelector(value: multiplier, onChanged: onMultiplierChanged),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrived(BuildContext context) {
    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: 'ARRIVED',
          title: 'You\'ve arrived',
          subtitle: '${RouteFormat.distance(totalMeters)} in '
              '${RouteFormat.duration(routeSeconds)} (simulated)',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: SheetSecondaryButton(label: 'New destination', onPressed: onNewDestination)),
            const SizedBox(width: 12),
            Expanded(
              child: SheetPrimaryButton(
                label: 'Drive again',
                icon: Icons.replay_rounded,
                onPressed: onDriveAgain,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final size = filled ? 60.0 : 48.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.accent : AppColors.white,
        shape: CircleBorder(
          side: filled
              ? BorderSide.none
              : BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.35)),
        ),
        elevation: filled ? 3 : 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: filled ? 32 : 24,
              color: filled ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  const _SpeedSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final option in NavigationSimulator.multipliers)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == value ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '${option}x',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: option == value ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
