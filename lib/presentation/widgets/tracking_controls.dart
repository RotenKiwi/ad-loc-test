// lib/widgets/tracking_controls.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/location_provider.dart';
import '../../services/location_service.dart';

class TrackingControls extends StatelessWidget {
  const TrackingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.permissionState == LocationPermissionState.denied)
            _PermissionBanner(
              message: 'Location permission is required.',
              actionLabel: 'Grant',
              onAction: () => provider.requestPermissions(),
              icon: Icons.location_off,
              color: cs.errorContainer,
              textColor: cs.onErrorContainer,
            )
          else if (provider.permissionState ==
              LocationPermissionState.foregroundOnly)
            _PermissionBanner(
              message: Platform.isIOS
                  ? 'Enable "Always" location in Settings to allow background tracking.'
                  : 'Grant "Always" access to enable background tracking.',
              actionLabel: Platform.isIOS ? 'Open\nSettings' : 'Update',
              onAction: () async {
                if (Platform.isIOS) {
                  await LocationService.openSettings();
                  await Future.delayed(const Duration(seconds: 2));
                  provider.requestPermissions();
                } else {
                  provider.requestPermissions();
                }
              },
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFFF3CD),
              textColor: const Color(0xFF664D03),
            ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () => provider.toggleTracking(),
            icon: Icon(provider.isTracking
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outlined),
            label: Text(
              provider.isTracking
                  ? 'Stop Background Tracking'
                  : 'Start Background Tracking',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: provider.isTracking ? cs.error : cs.primary,
              foregroundColor: provider.isTracking ? cs.onError : cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed:
                provider.isFetchingFg ? null : () => provider.refreshLocation(),
            icon: provider.isFetchingFg
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(
              provider.isFetchingFg ? 'Fetching…' : 'Refresh Location Now',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: cs.outline),
            ),
          ),

          const SizedBox(height: 8),
          _StatusRow(provider: provider),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _PermissionBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(message, style: TextStyle(color: textColor, fontSize: 13)),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: textColor),
            child: Text(actionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final LocationProvider provider;
  const _StatusRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: cs.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                provider.error!,
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final statusText = provider.isTracking
        ? 'Background tracking active – updates every 60 s'
        : 'Background tracking inactive';
    final statusColor =
        provider.isTracking ? Colors.green.shade700 : cs.outline;
    final statusIcon = provider.isTracking
        ? Icons.check_circle_outline
        : Icons.circle_outlined;

    return Row(
      children: [
        Icon(statusIcon, size: 14, color: statusColor),
        const SizedBox(width: 6),
        Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
      ],
    );
  }
}
