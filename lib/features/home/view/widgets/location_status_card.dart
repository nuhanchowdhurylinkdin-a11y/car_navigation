import 'package:car_navigation/core/utils/constants/colors.dart';
import 'package:flutter/material.dart';

import '../../../location/controller/location_controller.dart';
import 'sheet_parts.dart';

class LocationStatusCard extends StatelessWidget {
  const LocationStatusCard({
    super.key,
    required this.status,
    required this.onUseMyLocation,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    this.onPickStartOnMap,
  });

  final LocationStatus status;
  final VoidCallback onUseMyLocation;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  final VoidCallback? onPickStartOnMap;

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(status);
    if (content == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SheetPanel(
      children: [
        SheetHeader(
          eyebrow: content.eyebrow,
          title: content.title,
          color: content.color,
          icon: content.icon,
          loading: content.loading,
        ),
        const SizedBox(height: 14),
        Text(
          content.body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        if (content.actionLabel != null) ...[
          const SizedBox(height: 20),
          SheetPrimaryButton(
            label: content.actionLabel!,
            icon: content.actionIcon ?? Icons.arrow_forward,
            onPressed: content.action,
          ),
        ],
        if (content.offersManualStart && onPickStartOnMap != null) ...[
          const SizedBox(height: 4),
          SheetTextButton(
            label: 'Pick start point on map instead',
            onPressed: onPickStartOnMap!,
          ),
        ],
        if (content.footer != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  content.footer!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  _SheetContent? _contentFor(LocationStatus status) => switch (status) {
        LocationStatus.idle => _SheetContent(
            eyebrow: 'LOCATION SETUP',
            icon: Icons.near_me_rounded,
            color: AppColors.primary,
            title: 'See routes from where you are',
            body: 'NavTest uses your location only while the app is open to draw '
                'a driving route to the place you pick. We never track you in the background.',
            actionLabel: 'Use my location',
            actionIcon: Icons.my_location,
            action: onUseMyLocation,
            offersManualStart: true,
            footer: 'Only your start and destination are sent to the routing server',
          ),
        LocationStatus.requestingPermission => const _SheetContent(
            eyebrow: 'PERMISSION',
            loading: true,
            color: AppColors.primary,
            title: 'Waiting for permission…',
            body: 'Choose "While using the app" to continue.',
          ),
        LocationStatus.locating => const _SheetContent(
            eyebrow: 'LOCATING',
            loading: true,
            color: AppColors.primary,
            title: 'Finding your location…',
            body: 'This usually takes a few seconds. '
                'It is faster outdoors or near a window.',
          ),
        LocationStatus.ready => null,
        LocationStatus.denied => _SheetContent(
            eyebrow: 'LOCATION ACCESS',
            icon: Icons.location_off_outlined,
            color: AppColors.warning,
            title: 'Location permission needed',
            body: 'Without your location we can\'t start the route from where you are.',
            actionLabel: 'Try again',
            actionIcon: Icons.refresh,
            action: onUseMyLocation,
            offersManualStart: true,
          ),
        LocationStatus.deniedForever => _SheetContent(
            eyebrow: 'PERMISSION BLOCKED',
            icon: Icons.location_disabled_rounded,
            color: AppColors.error,
            title: 'Location is blocked for NavTest',
            body: 'You chose \'Don\'t allow\'. Turn on location permission in '
                'App Settings → Permissions → Location.',
            actionLabel: 'Open App Settings',
            actionIcon: Icons.settings,
            action: onOpenAppSettings,
            offersManualStart: true,
          ),
        LocationStatus.serviceDisabled => _SheetContent(
            eyebrow: 'SYSTEM SETTINGS',
            icon: Icons.gps_off_rounded,
            color: AppColors.textSecondary,
            title: 'Your device location is turned off',
            body: 'Turn on Location in your phone settings to find where you are.',
            actionLabel: 'Turn on location',
            actionIcon: Icons.settings,
            action: onOpenLocationSettings,
            offersManualStart: true,
          ),
        LocationStatus.timeout => _SheetContent(
            eyebrow: 'GPS TIMEOUT',
            icon: Icons.timer_off_outlined,
            color: AppColors.warning,
            title: 'Couldn\'t get a GPS fix',
            body: 'We waited ${LocationController.fixTimeout.inSeconds} seconds '
                'without a signal. Try moving outdoors.',
            actionLabel: 'Retry',
            actionIcon: Icons.refresh,
            action: onUseMyLocation,
            offersManualStart: true,
          ),
        LocationStatus.unsupported => const _SheetContent(
            eyebrow: 'NOT SUPPORTED',
            icon: Icons.phonelink_erase_rounded,
            color: AppColors.textSecondary,
            title: 'Location not supported',
            body: 'Device location is not available on this platform yet.',
            offersManualStart: true,
          ),
        LocationStatus.error => _SheetContent(
            eyebrow: 'ERROR',
            icon: Icons.error_outline,
            color: AppColors.error,
            title: 'Something went wrong',
            body: 'We couldn\'t read your location.',
            actionLabel: 'Retry',
            actionIcon: Icons.refresh,
            action: onUseMyLocation,
            offersManualStart: true,
          ),
      };
}

class _SheetContent {
  const _SheetContent({
    required this.eyebrow,
    required this.color,
    required this.title,
    required this.body,
    this.icon,
    this.loading = false,
    this.actionLabel,
    this.actionIcon,
    this.action,
    this.offersManualStart = false,
    this.footer,
  });

  final String eyebrow;
  final Color color;
  final String title;
  final String body;
  final IconData? icon;
  final bool loading;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? action;
  final bool offersManualStart;
  final String? footer;
}
