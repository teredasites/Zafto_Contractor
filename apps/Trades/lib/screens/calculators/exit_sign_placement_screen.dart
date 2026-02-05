import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Exit Sign Placement Calculator - Design System v2.6
/// IBC 1013, NEC 700 - Code-required exit sign locations
class ExitSignPlacementScreen extends ConsumerStatefulWidget {
  const ExitSignPlacementScreen({super.key});
  @override
  ConsumerState<ExitSignPlacementScreen> createState() => _ExitSignPlacementScreenState();
}

class _ExitSignPlacementScreenState extends ConsumerState<ExitSignPlacementScreen> {
  int _exitDoors = 2;
  int _corridorChanges = 3;
  int _stairwellDoors = 2;
  int _elevators = 1;
  double _maxViewingDistance = 100;

  int? _exitDoorSigns;
  int? _directionalSigns;
  int? _stairwellSigns;
  int? _elevatorSigns;
  int? _totalSigns;
  double? _totalLoad;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Exit Sign Placement', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING FEATURES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Exit Doors', value: _exitDoors.toDouble(), min: 1, max: 10, unit: '', onChanged: (v) { setState(() => _exitDoors = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Corridor Direction Changes', value: _corridorChanges.toDouble(), min: 0, max: 20, unit: '', onChanged: (v) { setState(() => _corridorChanges = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Stairwell Doors', value: _stairwellDoors.toDouble(), min: 0, max: 10, unit: '', onChanged: (v) { setState(() => _stairwellDoors = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Elevators', value: _elevators.toDouble(), min: 0, max: 6, unit: '', onChanged: (v) { setState(() => _elevators = v.round()); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Max Viewing Distance', value: _maxViewingDistance, min: 50, max: 150, unit: ' ft', onChanged: (v) { setState(() => _maxViewingDistance = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'EXIT SIGN REQUIREMENTS'),
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
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('IBC 1013 - Exit signs visible from any point in egress', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_totalSigns ?? 0}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('exit signs minimum', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildLocationRow(colors, 'At exit doors', _exitDoorSigns ?? 0, 'Required at each exit'),
        _buildLocationRow(colors, 'Directional (corridors)', _directionalSigns ?? 0, 'At turns, intersections'),
        _buildLocationRow(colors, 'At stairwell doors', _stairwellSigns ?? 0, 'Both sides of door'),
        _buildLocationRow(colors, 'Near elevators', _elevatorSigns ?? 0, '"EXIT" and "No elevator" signs'),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Total exit signs', '${_totalSigns ?? 0}', highlight: true),
        _buildCalcRow(colors, 'Estimated load', '${_totalLoad?.toStringAsFixed(0) ?? '0'} watts'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PLACEMENT RULES', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildRuleItem(colors, 'Min 6" letters, 3/4" stroke'),
            _buildRuleItem(colors, 'Mounted 6\'8" - 7\' AFF typically'),
            _buildRuleItem(colors, 'Visible from ${_maxViewingDistance.toStringAsFixed(0)} ft max'),
            _buildRuleItem(colors, '90-minute battery backup'),
            _buildRuleItem(colors, 'Illuminated or self-luminous'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLocationRow(ZaftoColors colors, String location, int count, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text('$count', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(location, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildRuleItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(LucideIcons.check, color: colors.accentPrimary, size: 12),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    // Exit door signs - one at each exit door
    final exitDoorSigns = _exitDoors;

    // Directional signs - at each direction change in egress path
    final directionalSigns = _corridorChanges;

    // Stairwell signs - at stairwell doors (both entry and exit)
    final stairwellSigns = _stairwellDoors * 2;

    // Elevator signs - "EXIT" sign near elevator + no elevator in fire
    final elevatorSigns = _elevators > 0 ? _elevators + 1 : 0;

    final total = exitDoorSigns + directionalSigns + stairwellSigns + elevatorSigns;

    // Estimate load - LED signs ~5W each
    final load = total * 5.0;

    setState(() {
      _exitDoorSigns = exitDoorSigns;
      _directionalSigns = directionalSigns;
      _stairwellSigns = stairwellSigns;
      _elevatorSigns = elevatorSigns;
      _totalSigns = total;
      _totalLoad = load;
    });
  }

  void _reset() {
    setState(() {
      _exitDoors = 2;
      _corridorChanges = 3;
      _stairwellDoors = 2;
      _elevators = 1;
      _maxViewingDistance = 100;
    });
    _calculate();
  }
}
