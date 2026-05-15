import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/location_entry.dart';
import '../../provider/location_provider.dart';

class CurrentLocationCard extends StatefulWidget {
  const CurrentLocationCard({super.key});

  @override
  State<CurrentLocationCard> createState() => _CurrentLocationCardState();
}

class _CurrentLocationCardState extends State<CurrentLocationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final entry = provider.current;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (provider.isTracking)
                  FadeTransition(
                    opacity: _opacity,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (provider.isFetchingFg)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 8),
                    Text('Acquiring location…',
                        style: TextStyle(color: cs.onPrimaryContainer)),
                  ],
                ),
              )
            else if (entry == null)
              _EmptyState(color: cs.onPrimaryContainer)
            else
              _LocationDetails(entry: entry, colors: cs),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color color;
  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.location_off_rounded,
              color: color.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 8),
          Text(
            'No location data yet.\nTap Refresh to get a fix.',
            textAlign: TextAlign.center,
            style: TextStyle(color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final LocationEntry entry;
  final ColorScheme colors;
  const _LocationDetails({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    final ts =
        DateFormat('dd MMM yyyy · HH:mm:ss').format(entry.timestamp.toLocal());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _CoordTile(
                    label: 'Latitude', value: entry.latitude, colors: colors)),
            const SizedBox(width: 12),
            Expanded(
                child: _CoordTile(
                    label: 'Longitude',
                    value: entry.longitude,
                    colors: colors)),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            if (entry.accuracy != null)
              _MetaChip(
                icon: Icons.radar,
                label: '±${entry.accuracy!.toStringAsFixed(1)} m',
                colors: colors,
              ),
            if (entry.altitude != null) ...[
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.terrain,
                label: '${entry.altitude!.toStringAsFixed(1)} m alt',
                colors: colors,
              ),
            ],
            if (entry.speed != null && entry.speed! > 0.1) ...[
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.speed,
                label: '${(entry.speed! * 3.6).toStringAsFixed(1)} km/h',
                colors: colors,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 14, color: colors.onPrimaryContainer.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                ts,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ),
            _SourceBadge(source: entry.source),
          ],
        ),
      ],
    );
  }
}

class _CoordTile extends StatelessWidget {
  final String label;
  final double value;
  final ColorScheme colors;
  const _CoordTile(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onPrimaryContainer.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(6),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  const _MetaChip(
      {required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.onPrimaryContainer.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isBg = source == 'background';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isBg ? Colors.indigo.shade100 : Colors.teal.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBg ? 'Background' : 'Foreground',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isBg ? Colors.indigo.shade800 : Colors.teal.shade800,
        ),
      ),
    );
  }
}
