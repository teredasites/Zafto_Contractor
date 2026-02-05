import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Generator Sizing Calculator - Design System v2.6
class GeneratorSizingScreen extends ConsumerStatefulWidget {
  const GeneratorSizingScreen({super.key});
  @override
  ConsumerState<GeneratorSizingScreen> createState() => _GeneratorSizingScreenState();
}

class _LoadEntry { final String name; final int runningW; final int startingW; _LoadEntry({required this.name, required this.runningW, required this.startingW}); }
class _PresetLoad { final String name; final int runningW; final int startingW; const _PresetLoad({required this.name, required this.runningW, required this.startingW}); }

class _GeneratorSizingScreenState extends ConsumerState<GeneratorSizingScreen> {
  final List<_LoadEntry> _loads = [];

  static const List<_PresetLoad> _presets = [
    _PresetLoad(name: 'Refrigerator', runningW: 150, startingW: 450),
    _PresetLoad(name: 'Freezer', runningW: 100, startingW: 350),
    _PresetLoad(name: 'Sump Pump (1/2 HP)', runningW: 800, startingW: 2000),
    _PresetLoad(name: 'Well Pump (1/2 HP)', runningW: 750, startingW: 2000),
    _PresetLoad(name: 'Furnace Blower (1/2 HP)', runningW: 800, startingW: 2350),
    _PresetLoad(name: 'Window AC (10,000 BTU)', runningW: 1200, startingW: 3600),
    _PresetLoad(name: 'Central AC (3 ton)', runningW: 3800, startingW: 7200),
    _PresetLoad(name: 'Electric Water Heater', runningW: 4500, startingW: 4500),
    _PresetLoad(name: 'Microwave (1000W)', runningW: 1000, startingW: 1000),
    _PresetLoad(name: 'Coffee Maker', runningW: 1000, startingW: 1000),
    _PresetLoad(name: 'Electric Range (one element)', runningW: 2500, startingW: 2500),
    _PresetLoad(name: 'Lighting (10 bulbs LED)', runningW: 100, startingW: 100),
    _PresetLoad(name: 'TV / Entertainment', runningW: 300, startingW: 300),
    _PresetLoad(name: 'Computer / Router', runningW: 200, startingW: 200),
    _PresetLoad(name: 'Space Heater (1500W)', runningW: 1500, startingW: 1500),
    _PresetLoad(name: 'Circular Saw', runningW: 1400, startingW: 2400),
    _PresetLoad(name: 'Air Compressor (1 HP)', runningW: 1000, startingW: 3000),
  ];

  int get _totalRunningWatts => _loads.fold(0, (sum, l) => sum + l.runningW);
  int get _largestStartingWatts => _loads.isEmpty ? 0 : _loads.map((l) => l.startingW - l.runningW).reduce((a, b) => a > b ? a : b);
  int get _requiredWatts => _totalRunningWatts + _largestStartingWatts;
  double get _requiredKw => _requiredWatts / 1000;

  String get _recommendedSize {
    final kw = _requiredKw;
    if (kw <= 0) return '-';
    if (kw <= 3.5) return '5 kW'; if (kw <= 5.5) return '7.5 kW'; if (kw <= 8) return '10 kW';
    if (kw <= 11) return '12 kW'; if (kw <= 14) return '16 kW'; if (kw <= 18) return '20 kW';
    if (kw <= 20) return '22 kW'; if (kw <= 24) return '26 kW';
    return '${(kw * 1.25).ceil()} kW+';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Generator Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          _buildResultsCard(colors),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Connected Loads', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            Text('${_loads.length} items', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (_loads.isEmpty) _buildEmptyState(colors) else ..._loads.asMap().entries.map((entry) => _buildLoadTile(colors, entry.key, entry.value)),
          const SizedBox(height: 80),
        ])),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPresetSheet(colors),
        backgroundColor: colors.accentPrimary,
        icon: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
        label: Text('Add Load', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(_recommendedSize, style: TextStyle(color: colors.accentPrimary, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('Recommended Generator', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Total Running Load', '$_totalRunningWatts W', false),
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Largest Starting Surge', '+$_largestStartingWatts W', false),
            Divider(color: colors.borderSubtle, height: 16),
            _buildResultRow(colors, 'Required Capacity', '$_requiredWatts W', true),
          ]),
        ),
        const SizedBox(height: 12),
        Text('Sizing includes largest motor starting load.\nAdd 25% margin for future expansion.', textAlign: TextAlign.center, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(LucideIcons.powerOff, color: colors.textTertiary, size: 40),
        const SizedBox(height: 12),
        Text('No loads added', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tap "Add Load" to get started', style: TextStyle(color: colors.textTertiary.withValues(alpha: 0.6), fontSize: 12)),
      ]),
    );
  }

  Widget _buildLoadTile(ZaftoColors colors, int index, _LoadEntry load) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(load.name, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('Run: ${load.runningW}W • Start: ${load.startingW}W', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ])),
        IconButton(icon: Icon(LucideIcons.minusCircle, color: colors.accentError, size: 20), onPressed: () { HapticFeedback.lightImpact(); setState(() => _loads.removeAt(index)); }, visualDensity: VisualDensity.compact),
      ]),
    );
  }

  void _showAddPresetSheet(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (context, scrollController) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Add Load', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(child: ListView.builder(
            controller: scrollController,
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final preset = _presets[index];
              return ListTile(
                title: Text(preset.name, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                subtitle: Text('Running: ${preset.runningW}W • Starting: ${preset.startingW}W', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                trailing: Icon(LucideIcons.plusCircle, color: colors.accentPrimary),
                onTap: () { HapticFeedback.lightImpact(); setState(() => _loads.add(_LoadEntry(name: preset.name, runningW: preset.runningW, startingW: preset.startingW))); Navigator.pop(context); },
              );
            },
          )),
        ]),
      ),
    );
  }
}
