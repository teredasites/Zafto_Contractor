import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// VFD Sizing Calculator - Design System v2.6
/// Variable Frequency Drive selection per NEC 430
class VfdSizingScreen extends ConsumerStatefulWidget {
  const VfdSizingScreen({super.key});
  @override
  ConsumerState<VfdSizingScreen> createState() => _VfdSizingScreenState();
}

class _VfdSizingScreenState extends ConsumerState<VfdSizingScreen> {
  double _motorHp = 10;
  double _motorFla = 14;
  int _voltage = 480;
  String _loadType = 'Variable Torque';
  bool _hasLineReactor = false;
  bool _hasOutputFilter = false;
  double _cableLength = 100;

  // VFD sizing rules
  // Variable torque (fans/pumps): Size VFD at motor FLA
  // Constant torque (conveyors): Size VFD 10-15% above motor FLA
  // Heavy duty: Size VFD 20-25% above motor FLA

  static const Map<String, double> _loadMultiplier = {
    'Variable Torque': 1.0,    // Fans, pumps - most common
    'Constant Torque': 1.15,   // Conveyors, mixers
    'Heavy Duty': 1.25,        // Crushers, hoists
  };

  // Standard VFD HP ratings
  static const List<double> _standardVfdHp = [
    0.5, 0.75, 1, 1.5, 2, 3, 5, 7.5, 10, 15, 20, 25, 30, 40, 50,
    60, 75, 100, 125, 150, 200, 250, 300, 350, 400, 450, 500
  ];

  double get _loadFactor => _loadMultiplier[_loadType] ?? 1.0;

  double get _requiredVfdAmps => _motorFla * _loadFactor;

  double get _recommendedVfdHp {
    final requiredHp = _motorHp * _loadFactor;
    for (final hp in _standardVfdHp) {
      if (hp >= requiredHp) return hp;
    }
    return _standardVfdHp.last;
  }

  // Input line reactor sizing - typically 3-5% impedance
  String get _lineReactorSize {
    if (!_hasLineReactor) return 'Not required';
    return '3% impedance, ${_requiredVfdAmps.toStringAsFixed(0)}A rated';
  }

  // Output filter recommendation based on cable length
  String get _outputFilterRec {
    if (_cableLength < 50) return 'Not typically needed';
    if (_cableLength < 100) return 'Consider dV/dt filter';
    if (_cableLength < 300) return 'dV/dt filter recommended';
    return 'Sine wave filter recommended';
  }

  // NEC 430.122 - Conductor sizing at 125% of VFD input current
  double get _conductorSizingAmps => _requiredVfdAmps * 1.25;

  // NEC 430.124 - Bypass considerations
  bool get _bypassRecommended => _motorHp >= 25;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('VFD Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMotorDataCard(colors),
          const SizedBox(height: 16),
          _buildLoadTypeCard(colors),
          const SizedBox(height: 16),
          _buildCableLengthCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
          const SizedBox(height: 20),
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildRecommendationsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildMotorDataCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MOTOR DATA', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 16),
        Text('Motor HP', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [5.0, 7.5, 10.0, 15.0, 20.0, 25.0, 30.0, 50.0].map((hp) {
          final isSelected = _motorHp == hp;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _motorHp = hp); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${hp.toStringAsFixed(hp == hp.toInt() ? 0 : 1)}', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 13)),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        Text('Motor FLA', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Text('${_motorFla.toStringAsFixed(1)}A', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _motorFla, min: 1, max: 500, divisions: 499, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _motorFla = v); }),
          )),
        ]),
        const SizedBox(height: 12),
        Text('Voltage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [208, 230, 460, 480, 575].map((v) {
          final isSelected = _voltage == v;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _voltage = v); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Text('${v}V', style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildLoadTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOAD TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        ..._loadMultiplier.keys.map((type) {
          final isSelected = _loadType == type;
          final multiplier = _loadMultiplier[type] ?? 1.0;
          String description;
          switch (type) {
            case 'Variable Torque': description = 'Fans, pumps, HVAC'; break;
            case 'Constant Torque': description = 'Conveyors, mixers'; break;
            case 'Heavy Duty': description = 'Crushers, hoists, extruders'; break;
            default: description = '';
          }
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _loadType = type); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(type, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(description, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                ])),
                Text('×${multiplier.toStringAsFixed(2)}', style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildCableLengthCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VFD TO MOTOR CABLE LENGTH (feet)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Text('${_cableLength.toInt()} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Expanded(child: SliderTheme(
            data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgBase, thumbColor: colors.accentPrimary),
            child: Slider(value: _cableLength, min: 10, max: 500, divisions: 49, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _cableLength = v); }),
          )),
        ]),
        const SizedBox(height: 8),
        Text(_outputFilterRec, style: TextStyle(color: _cableLength > 100 ? colors.accentWarning : colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Line reactor (input)', style: TextStyle(color: colors.textSecondary, fontSize: 14))),
          Switch(value: _hasLineReactor, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasLineReactor = v); }, activeColor: colors.accentPrimary),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Output filter', style: TextStyle(color: colors.textSecondary, fontSize: 14))),
          Switch(value: _hasOutputFilter, onChanged: (v) { HapticFeedback.selectionClick(); setState(() => _hasOutputFilter = v); }, activeColor: colors.accentPrimary),
        ]),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2))),
      child: Column(children: [
        Text('${_recommendedVfdHp.toStringAsFixed(_recommendedVfdHp == _recommendedVfdHp.toInt() ? 0 : 1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2)),
        Text('HP VFD Required', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            _buildResultRow(colors, 'Motor HP', '${_motorHp.toStringAsFixed(1)} HP'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Motor FLA', '${_motorFla.toStringAsFixed(1)}A'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Load Factor', '${(_loadFactor * 100).toInt()}%'),
            const SizedBox(height: 10),
            _buildResultRow(colors, 'Required VFD Amps', '${_requiredVfdAmps.toStringAsFixed(1)}A'),
            Divider(color: colors.borderSubtle, height: 20),
            _buildResultRow(colors, 'Conductor Sizing', '${_conductorSizingAmps.toStringAsFixed(1)}A (125%)', highlight: true),
            if (_hasLineReactor) ...[
              const SizedBox(height: 10),
              _buildResultRow(colors, 'Line Reactor', _lineReactorSize),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildRecommendationsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        _buildRecItem(colors, LucideIcons.checkCircle, 'Use shielded VFD cable to motor'),
        const SizedBox(height: 8),
        _buildRecItem(colors, LucideIcons.checkCircle, 'Ground cable shield at both ends'),
        const SizedBox(height: 8),
        if (_cableLength > 100)
          _buildRecItem(colors, LucideIcons.alertTriangle, 'Long cable - use output filter'),
        if (_cableLength > 100) const SizedBox(height: 8),
        if (_bypassRecommended)
          _buildRecItem(colors, LucideIcons.info, 'Consider bypass contactor for ${_motorHp.toInt()}+ HP'),
      ]),
    );
  }

  Widget _buildRecItem(ZaftoColors colors, IconData icon, String text) {
    final isWarning = icon == LucideIcons.alertTriangle;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: isWarning ? colors.accentWarning : colors.textTertiary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(color: isWarning ? colors.accentWarning : colors.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    ]);
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.textTertiary, size: 16), const SizedBox(width: 8), Text('NEC Article 430 Part X', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 430.122 - Conductors at 125% input\n• 430.124 - Bypass circuit provisions\n• 430.126 - Motor overload protection\n• Nameplate amps for branch circuit', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}
