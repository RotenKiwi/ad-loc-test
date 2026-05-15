import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/location_provider.dart';
import '../widgets/current_location_card.dart';
import '../widgets/location_history.dart';
import '../widgets/tracking_controls.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
  }

  Future<void> _initialise() async {
    final provider = context.read<LocationProvider>();

    if (provider.permissionState == LocationPermissionState.unknown ||
        provider.permissionState == LocationPermissionState.denied) {
      await provider.requestPermissions();
    }

    if (mounted) await provider.refreshLocation();
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: cs.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Location Tracker',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor:
                    provider.isTracking ? Colors.green : Colors.grey,
                radius: 5,
              ),
              label: Text(
                provider.isTracking ? 'Live' : 'Off',
                style: const TextStyle(fontSize: 12),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: provider.isTracking
                  ? Colors.green.shade50
                  : cs.surfaceContainerHighest,
            ),
          ),
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.auto_delete_outlined),
            onPressed: provider.history.isEmpty
                ? null
                : () => _confirmClear(context, provider),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: provider.refreshLocation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: CurrentLocationCard()),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Divider(color: cs.outlineVariant),
              ),
            ),

            const SliverToBoxAdapter(child: TrackingControls()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'History',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.history.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Pull down to refresh',
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: LocationHistoryList()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
      BuildContext context, LocationProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This will permanently delete all recorded locations from this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) await provider.clearHistory();
  }
}
