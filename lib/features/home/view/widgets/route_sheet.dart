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
      RouteStatus.loading => _loading(context),
      RouteStatus.success when route != null => _ready(context, route),
      RouteStatus.error when failure != null => _error(context, failure),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _loading(BuildContext context) {
    final theme = Theme.of(context);
    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: isSlow ? 'SLOW SERVER' : 'ROUTING',
          title: 'Finding the best driving route…',
          color: isSlow ? AppColors.warning : AppColors.primary,
          loading: true,
          trailing: _closeButton(),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 4,
            color: isSlow ? AppColors.warning : AppColors.primary,
            backgroundColor: AppColors.tint,
          ),
        ),
        if (isSlow) ...[
          const SizedBox(height: 12),
          Text(
            'Still working… the free public routing server is slow right now.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _ready(BuildContext context, RoutePath route) {
    final theme = Theme.of(context);
    final target = destination;
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
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  target == null
                      ? 'Dropped pin'
                      : 'Dropped pin · ${target.latitude.toStringAsFixed(4)}, '
                          '${target.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _closeButton(),
            ],
          ),
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
          const SizedBox(height: 10),
          Text(
            'Long-press anywhere to change the destination.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _error(BuildContext context, RouteException failure) {
    final theme = Theme.of(context);
    final (icon, color, eyebrow, title) = switch (failure) {
      NoRouteException() => (Icons.wrong_location_outlined, AppColors.error, 'NO ROUTE', 'No drivable route'),
      RouteNetworkException() => (Icons.wifi_off_rounded, AppColors.error, 'OFFLINE', 'You\'re offline'),
      RouteTimeoutException() => (Icons.hourglass_empty_rounded, AppColors.warning, 'TIMEOUT', 'Routing server didn\'t respond'),
      RouteServerException() => (Icons.cloud_off_rounded, AppColors.warning, 'SERVER ERROR', 'Couldn\'t get a route'),
    };
    final body = switch (failure) {
      NoRouteException() => 'We couldn\'t find a road route to this point. Try a spot closer to a street.',
      RouteNetworkException() => 'Check your internet connection and try again.',
      RouteTimeoutException() => 'The free public routing server is busy. Please try again in a moment.',
      RouteServerException() => failure.message,
    };
    final isNoRoute = failure is NoRouteException;

    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: eyebrow,
          title: title,
          color: color,
          icon: icon,
          trailing: _closeButton(),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 20),
        if (isNoRoute)
          SheetPrimaryButton(label: 'Choose another point', icon: Icons.touch_app_outlined, onPressed: onClear)
        else ...[
          SheetPrimaryButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
          const SizedBox(height: 4),
          SheetTextButton(label: 'Dismiss', onPressed: onClear),
        ],
      ],
    );
  }

  Widget _closeButton() => IconButton(
        onPressed: onClear,
        tooltip: 'Clear destination',
        icon: const Icon(Icons.close, color: AppColors.textSecondary),
      );
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
