import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/location_entry.dart';
import '../../provider/location_provider.dart';

class LocationHistoryList extends StatelessWidget {
  const LocationHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<LocationProvider>().history;
    final cs = Theme.of(context).colorScheme;

    if (history.isEmpty) {
      return _EmptyHistory(color: cs.onSurfaceVariant);
    }

    final reversed = history.reversed.toList();

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reversed.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        return _HistoryTile(
          entry: reversed[index],
          index: history.length - index,
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final LocationEntry entry;
  final int index;

  const _HistoryTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = DateFormat('HH:mm:ss').format(entry.timestamp.toLocal());
    final date = DateFormat('dd MMM').format(entry.timestamp.toLocal());
    final isBg = entry.source == 'background';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isBg ? Colors.indigo.shade50 : Colors.teal.shade50,
        child: Icon(
          isBg ? Icons.cloud_done_outlined : Icons.person_pin_circle_outlined,
          size: 20,
          color: isBg ? Colors.indigo.shade700 : Colors.teal.shade700,
        ),
      ),
      title: Text(
        '${entry.latitude.toStringAsFixed(6)}, '
        '${entry.longitude.toStringAsFixed(6)}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 11, color: cs.onSurfaceVariant),
            const SizedBox(width: 3),
            Text(
              '$date · $time',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            if (entry.accuracy != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.radar, size: 11, color: cs.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                '±${entry.accuracy!.toStringAsFixed(0)} m',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
      trailing: Text(
        '#$index',
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final Color color;
  const _EmptyHistory({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 56, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No history yet',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking or refresh to record locations.',
            style: TextStyle(
              color: color.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
