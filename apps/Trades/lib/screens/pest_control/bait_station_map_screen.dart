// ZAFTO Bait Station Map Screen
// Station locations, type, activity level, servicing
// Sprint NICHE1 — Pest control module

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';

class BaitStationMapScreen extends ConsumerStatefulWidget {
  final String? propertyId;

  const BaitStationMapScreen({super.key, this.propertyId});

  @override
  ConsumerState<BaitStationMapScreen> createState() => _BaitStationMapScreenState();
}

class _BaitStationMapScreenState extends ConsumerState<BaitStationMapScreen> {
  List<Map<String, dynamic>> _stations = [];
  bool _isLoading = true;
  String? _error;

  static const _stationTypes = ['rodent', 'ant', 'cockroach', 'termite', 'fly', 'multi_pest'];
  static const _activityLevels = ['none', 'low', 'moderate', 'high', 'critical'];
  static const _placementZones = ['interior', 'exterior', 'perimeter', 'attic', 'crawlspace', 'garage', 'basement', 'roof'];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      var query = supabase
          .from('bait_stations')
          .select()
          .isFilter('deleted_at', null)
          .order('station_number');

      if (widget.propertyId != null) {
        query = supabase
            .from('bait_stations')
            .select()
            .eq('property_id', widget.propertyId!)
            .isFilter('deleted_at', null)
            .order('station_number');
      }

      final data = await query;
      _stations = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStation() async {
    String stationType = 'rodent';
    String placementZone = 'exterior';
    final numberCtrl = TextEditingController(text: '${_stations.length + 1}');
    final locationCtrl = TextEditingController();
    final baitCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Bait Station'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: numberCtrl,
                    decoration: const InputDecoration(labelText: 'Station Number', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: stationType,
                    decoration: const InputDecoration(labelText: 'Station Type', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: _stationTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(_formatLabel(t))))
                        .toList(),
                    onChanged: (v) => setDialogState(() => stationType = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: placementZone,
                    decoration: const InputDecoration(labelText: 'Placement Zone', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: _placementZones
                        .map((z) => DropdownMenuItem(value: z, child: Text(_formatLabel(z))))
                        .toList(),
                    onChanged: (v) => setDialogState(() => placementZone = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Location Description', hintText: 'e.g., NE corner of garage', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: baitCtrl,
                    decoration: const InputDecoration(labelText: 'Bait Type', hintText: 'e.g., Contrac Blox', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx, {
                    'station_number': numberCtrl.text.trim(),
                    'station_type': stationType,
                    'placement_zone': placementZone,
                    'location_description': locationCtrl.text.trim(),
                    'bait_type': baitCtrl.text.trim(),
                    'activity_level': 'none',
                    'install_date': DateTime.now().toIso8601String().split('T')[0],
                  });
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final companyId = user?.appMetadata['company_id'] as String?;
      if (companyId == null) return;

      await supabase.from('bait_stations').insert({
        'company_id': companyId,
        if (widget.propertyId != null) 'property_id': widget.propertyId,
        ...result,
      });

      await _loadStations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _serviceStation(String stationId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('bait_stations').update({
        'last_serviced_at': DateTime.now().toUtc().toIso8601String(),
        'last_serviced_by': supabase.auth.currentUser?.id,
      }).eq('id', stationId);
      await _loadStations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatLabel(String value) {
    return value.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  Color _activityColor(String? level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in _stations) {
      final zone = s['placement_zone'] as String? ?? 'unknown';
      grouped.putIfAbsent(zone, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Bait Stations')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStation,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: colors.textSecondary)),
                      TextButton(onPressed: _loadStations, child: const Text('Retry')),
                    ],
                  ),
                )
              : _stations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin, size: 48, color: colors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No bait stations', style: TextStyle(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Tap + to add a station', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Stats
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.bgInset,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statCol(colors, '${_stations.length}', 'Total'),
                              _statCol(colors,
                                  '${_stations.where((s) => s['activity_level'] == 'none').length}', 'Clear'),
                              _statCol(colors,
                                  '${_stations.where((s) => s['activity_level'] != 'none').length}', 'Active'),
                            ],
                          ),
                        ),

                        // Grouped by zone
                        ...grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              _sectionHeader(colors, _formatLabel(entry.key).toUpperCase()),
                              const SizedBox(height: 8),
                              ...entry.value.map((s) => _buildStationCard(colors, s)),
                            ],
                          );
                        }),

                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildStationCard(ZaftoColors colors, Map<String, dynamic> station) {
    final activity = station['activity_level'] as String? ?? 'none';
    final lastServiced = station['last_serviced_at'] as String?;

    return Card(
      color: colors.bgInset,
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _activityColor(activity).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${station['station_number'] ?? ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _activityColor(activity)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatLabel(station['station_type'] as String? ?? '')} Station',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
                  ),
                  if (station['location_description'] != null)
                    Text(station['location_description'] as String,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: _activityColor(activity), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(_formatLabel(activity),
                          style: TextStyle(fontSize: 10, color: _activityColor(activity), fontWeight: FontWeight.w600)),
                      if (lastServiced != null) ...[
                        const SizedBox(width: 8),
                        Text('Serviced: ${_formatDate(lastServiced)}',
                            style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _serviceStation(station['id'] as String),
              child: const Text('Service', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.month}/${dt.day}';
  }

  Widget _statCol(ZaftoColors colors, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: colors.textTertiary));
  }
}
