import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/constants/colors.dart';
import '../../../directions/controller/route_controller.dart';
import '../../../directions/model/route_exception.dart';
import '../../../directions/model/route_path.dart';
import 'sheet_parts.dart';

class RouteSheet extends StatelessWidget {
  const RouteSheet({
    super.key,
    required this.status,
    required this.destination,
    required this.path,
    required this.error,
    required this.isSlow,
    required this.onRetry,
    required this.onClear,
    this.onStart,
  });

  final RouteStatus status;
  final LatLng? destination;
  final RoutePath? path;
  final RouteException? error;
  final bool isSlow;
  final VoidCallback onRetry;
  final VoidCallback onClear;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final route = path;
    final failure = error;
    return switch (status) {
      RouteStatus.loading => isSlow ? _slow(context) : _loading(context),
      RouteStatus.success when route != null => _ready(context, route),
      RouteStatus.error when failure != null => _error(context, failure),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _loading(BuildContext context) {
    return SheetPanel(
      progressColor: AppColors.primary,
      children: [
        const SheetHeader(
          title: 'Finding the best driving route…',
          subtitle: 'Asking the OSRM routing server',
          color: AppColors.primary,
          icon: Icons.alt_route_rounded,
        ),
        const SizedBox(height: 16),
        const _StatsSkeleton(),
        const SizedBox(height: 12),
        _DestinationRow(
          destination: destination,
          trailing: SheetTextButton(label: 'Cancel', onPressed: onClear),
        ),
      ],
    );
  }

  Widget _slow(BuildContext context) {
    return SheetPanel(
      progressColor: AppColors.warning,
      children: [
        const SheetHeader(
          title: 'Still working… the routing server is slow',
          subtitle: 'The free public routing server is taking longer than usual. Hang on a few more seconds.',
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 16),
        const _StatsSkeleton(),
        const SizedBox(height: 16),
        SheetSecondaryButton(label: 'Cancel', onPressed: onClear),
      ],
    );
  }

  Widget _ready(BuildContext context, RoutePath route) {
    return SheetPanel(
      children: [
        Row(
          children: [
            Expanded(child: _Stat(value: route.distanceLabel, label: 'DISTANCE')),
            Container(width: 1, height: 44, color: AppColors.tint),
            Expanded(child: _Stat(value: route.durationLabel, label: 'EST. TIME')),
          ],
        ),
        const SizedBox(height: 16),
        _DestinationRow(
          destination: destination,
          filled: true,
          trailing: SheetCloseButton(onPressed: onClear, tooltip: 'Clear destination'),
        ),
        if (onStart != null) ...[
          const SizedBox(height: 16),
          SheetPrimaryButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            onPressed: onStart,
            color: AppColors.accent,
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Long-press anywhere to change the destination.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _error(BuildContext context, RouteException failure) {
    final (icon, color, title, body) = switch (failure) {
      NoRouteException() => (
          Icons.wrong_location_outlined,
          AppColors.error,
          'No drivable route',
          'We couldn\'t find a road route to this point. Try a spot closer to a street.',
        ),
      RouteNetworkException() => (
          Icons.wifi_off_rounded,
          AppColors.error,
          'You\'re offline',
          'Check your internet connection and try again.',
        ),
      RouteTimeoutException() => (
          Icons.hourglass_empty_rounded,
          AppColors.warning,
          'Routing server didn\'t respond',
          'The free public routing server is busy. Please try again in a moment.',
        ),
      RouteServerException() => (
          Icons.cloud_off_rounded,
          AppColors.warning,
          'Couldn\'t get a route',
          'The routing server returned an error. Please try again.',
        ),
    };
    final detail = switch (failure) {
      NoRouteException(:final message) when message != const NoRouteException().message => message,
      _ => null,
    };
    final dismissInHeader = failure is NoRouteException || failure is RouteTimeoutException;

    return SheetPanel(
      children: [
        SheetHeader(
          title: title,
          subtitle: body,
          color: color,
          icon: icon,
          trailing: dismissInHeader
              ? SheetCloseButton(onPressed: onClear, tooltip: 'Clear destination')
              : null,
        ),
        if (detail != null) ...[
          const SizedBox(height: 14),
          SheetInfoChip(icon: Icons.info_outline_rounded, text: detail),
        ],
        const SizedBox(height: 20),
        switch (failure) {
          NoRouteException() => SheetPrimaryButton(
              label: 'Choose another point',
              icon: Icons.my_location_rounded,
              onPressed: onClear,
            ),
          RouteTimeoutException() => SheetPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          RouteNetworkException() || RouteServerException() => Row(
              children: [
                Expanded(child: SheetSecondaryButton(label: 'Dismiss', onPressed: onClear)),
                const SizedBox(width: 12),
                Expanded(
                  child: SheetPrimaryButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ),
              ],
            ),
        },
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.destination, required this.trailing, this.filled = false});

  final LatLng? destination;
  final Widget trailing;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = destination;
    return Container(
      padding: EdgeInsets.fromLTRB(filled ? 12 : 0, 4, 0, 4),
      decoration: filled
          ? BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12))
          : null,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'To: Selected pin ',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if (target != null)
                    TextSpan(
                      text: '(${_format(target)})',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  static String _format(LatLng point) {
    final lat = '${point.latitude.abs().toStringAsFixed(4)}° ${point.latitude >= 0 ? 'N' : 'S'}';
    final lng = '${point.longitude.abs().toStringAsFixed(4)}° ${point.longitude >= 0 ? 'E' : 'W'}';
    return '$lat, $lng';
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              children: [
                SkeletonBox(width: 88, height: 22),
                SizedBox(height: 8),
                SkeletonBox(width: 56, height: 10),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SkeletonBox(width: 88, height: 22),
                SizedBox(height: 8),
                SkeletonBox(width: 56, height: 10),
              ],
            ),
          ),
        ],
      ),
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
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
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
