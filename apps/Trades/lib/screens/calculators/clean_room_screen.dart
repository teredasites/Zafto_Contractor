import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Clean Room Calculator - Design System v2.6
/// ISO classification and air change requirements
class CleanRoomScreen extends ConsumerStatefulWidget {
  const CleanRoomScreen({super.key});
  @override
  ConsumerState<CleanRoomScreen> createState() => _CleanRoomScreenState();
}

class _CleanRoomScreenState extends ConsumerState<CleanRoomScreen> {
  double _roomLength = 30; // feet
  double _roomWidth = 20; // feet
  double _ceilingHeight = 10; // feet
  String _isoClass = 'iso_7';
  String _flowPattern = 'mixed';

  double? _airChanges;
  double? _cfmRequired;
  double? _hepaFilters;
  double? _roomVolume;
  String? _recommendation;

  // ISO class to air changes per hour (typical values)
  final Map<String, double> _isoAirChanges = {
    'iso_5': 400,  // Class 100
    'iso_6': 150,  // Class 1000
    'iso_7': 60,   // Class 10000
    'iso_8': 20,   // Class 100000
    'iso_9': 12,   // Controlled environment
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Room volume
    final roomVolume = _roomLength * _roomWidth * _ceilingHeight;

    // Air changes per hour based on ISO class
    final airChanges = _isoAirChanges[_isoClass] ?? 60;

    // CFM required = Volume × ACH / 60
    final cfmRequired = roomVolume * airChanges / 60;

    // HEPA filter count (2'×4' filters at 400 CFM each typical)
    final hepaFilters = cfmRequired / 400;

    String recommendation;
    recommendation = 'ISO ${_isoClass.split('_')[1]} clean room: ${airChanges.toStringAsFixed(0)} ACH required. ${cfmRequired.toStringAsFixed(0)} CFM total. ';

    switch (_isoClass) {
      case 'iso_5':
        recommendation += 'ISO 5 (Class 100): Pharmaceutical, semiconductor. Full HEPA ceiling coverage.';
        break;
      case 'iso_6':
        recommendation += 'ISO 6 (Class 1,000): Medical device, optics. 40-60% HEPA coverage.';
        break;
      case 'iso_7':
        recommendation += 'ISO 7 (Class 10,000): Hospital OR, electronics assembly. HEPA diffusers.';
        break;
      case 'iso_8':
        recommendation += 'ISO 8 (Class 100,000): General compounding, packaging. HEPA at supply.';
        break;
      case 'iso_9':
        recommendation += 'ISO 9: Controlled environment. Standard HVAC with HEPA.';
        break;
    }

    switch (_flowPattern) {
      case 'unidirectional':
        recommendation += ' Unidirectional (laminar): Ceiling-to-floor flow. Best for ISO 5-6. Full ceiling HEPA.';
        break;
      case 'mixed':
        recommendation += ' Non-unidirectional (turbulent): Adequate for ISO 7-9. HEPA diffusers with low-wall returns.';
        break;
    }

    // Ceiling coverage
    final ceilingArea = _roomLength * _roomWidth;
    final filterArea = hepaFilters * 8; // 2×4 ft each
    final coverage = (filterArea / ceilingArea) * 100;

    if (_flowPattern == 'unidirectional' && coverage < 80) {
      recommendation += ' WARNING: Unidirectional flow typically needs 80%+ ceiling coverage. Current: ${coverage.toStringAsFixed(0)}%.';
    }

    recommendation += ' Pressure: +0.03" to +0.05" WC relative to adjacent spaces. Monitor continuously.';

    if (_isoClass == 'iso_5' || _isoClass == 'iso_6') {
      recommendation += ' Gowning room required. Particle counting per ISO 14644-3.';
    }

    recommendation += ' HEPA: 99.97% @ 0.3 micron minimum. Consider ULPA for ISO 4-5.';

    setState(() {
      _airChanges = airChanges;
      _cfmRequired = cfmRequired;
      _hepaFilters = hepaFilters;
      _roomVolume = roomVolume;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomLength = 30;
      _roomWidth = 20;
      _ceilingHeight = 10;
      _isoClass = 'iso_7';
      _flowPattern = 'mixed';
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Clean Room', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ISO CLASSIFICATION'),
              const SizedBox(height: 12),
              _buildIsoClassSelector(colors),
              const SizedBox(height: 12),
              _buildFlowPatternSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM DIMENSIONS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Length', _roomLength, 10, 100, ' ft', (v) { setState(() => _roomLength = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Width', _roomWidth, 10, 60, ' ft', (v) { setState(() => _roomWidth = v); _calculate(); })),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactSlider(colors, 'Height', _ceilingHeight, 8, 14, ' ft', (v) { setState(() => _ceilingHeight = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'AIR HANDLING REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.sparkles, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('ISO 14644-1: Class 5=400 ACH, Class 7=60 ACH. HEPA 99.97% @ 0.3μm. Maintain positive pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildIsoClassSelector(ZaftoColors colors) {
    final classes = [('iso_5', 'ISO 5'), ('iso_6', 'ISO 6'), ('iso_7', 'ISO 7'), ('iso_8', 'ISO 8'), ('iso_9', 'ISO 9')];
    return Row(
      children: classes.map((c) {
        final selected = _isoClass == c.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _isoClass = c.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: c != classes.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(c.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlowPatternSelector(ZaftoColors colors) {
    final patterns = [('unidirectional', 'Unidirectional (Laminar)'), ('mixed', 'Non-Unidirectional')];
    return Row(
      children: patterns.map((p) {
        final selected = _flowPattern == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _flowPattern = p.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: p != patterns.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(p.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_cfmRequired == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_cfmRequired?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${_airChanges?.toStringAsFixed(0)} Air Changes/Hour', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('${_hepaFilters?.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
              Text('2×4 HEPA Filters (approx)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${_roomVolume?.toStringAsFixed(0)} ft³')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Floor Area', '${(_roomLength * _roomWidth).toStringAsFixed(0)} ft²')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Class', _isoClass.split('_')[1])),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
