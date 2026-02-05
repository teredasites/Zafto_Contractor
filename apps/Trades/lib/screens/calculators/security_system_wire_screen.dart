import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Security System Wire Calculator - Design System v2.6
/// Wire gauge selection by distance for alarm systems
class SecuritySystemWireScreen extends ConsumerStatefulWidget {
  const SecuritySystemWireScreen({super.key});
  @override
  ConsumerState<SecuritySystemWireScreen> createState() => _SecuritySystemWireScreenState();
}

class _SecuritySystemWireScreenState extends ConsumerState<SecuritySystemWireScreen> {
  String _systemType = 'burglar';
  double _runLength = 200;
  int _voltage = 12;
  double _currentDraw = 0.5;

  String? _recommendedGauge;
  double? _voltageDrop;
  double? _voltageDropPercent;
  String? _maxDistance;
  bool? _isAcceptable;

  final Map<String, double> _wireResistance = {
    '22 AWG': 16.14,
    '20 AWG': 10.15,
    '18 AWG': 6.385,
    '16 AWG': 4.016,
    '14 AWG': 2.525,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final totalCurrent = _currentDraw;
    double vDrop = 0;
    String gauge = '22 AWG';

    for (final entry in _wireResistance.entries) {
      final resistance = entry.value;
      vDrop = (2 * _runLength * totalCurrent * resistance) / 1000;
      final vDropPercent = (vDrop / _voltage) * 100;
      if (vDropPercent <= 5.0) {
        gauge = entry.key;
        break;
      }
    }

    final vDropPercent = (vDrop / _voltage) * 100;
    final resistance = _wireResistance[gauge] ?? 16.14;
    final maxDist = (0.05 * _voltage * 1000) / (2 * totalCurrent * resistance);

    setState(() {
      _recommendedGauge = gauge;
      _voltageDrop = vDrop;
      _voltageDropPercent = vDropPercent;
      _maxDistance = maxDist.toStringAsFixed(0);
      _isAcceptable = vDropPercent <= 5.0;
    });
  }

  void _reset() {
    setState(() {
      _systemType = 'burglar';
      _runLength = 200;
      _voltage = 12;
      _currentDraw = 0.5;
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
        title: Text('Security System Wire', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM TYPE'),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Wire Run Length', value: _runLength, min: 50, max: 1000, unit: ' ft', onChanged: (v) { setState(() => _runLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Current Draw', value: _currentDraw, min: 0.1, max: 3.0, unit: ' A', decimals: 2, onChanged: (v) { setState(() => _currentDraw = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'System Voltage', options: const ['12V', '24V'], selectedIndex: _voltage == 12 ? 0 : 1, onChanged: (i) { setState(() => _voltage = i == 0 ? 12 : 24); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'WIRE SIZING RESULT'),
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
        Icon(LucideIcons.shield, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size wire for burglar alarms, access control, and security panels. Max 5% voltage drop.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = [
      ('burglar', 'Burglar Alarm', LucideIcons.alertTriangle),
      ('access', 'Access Control', LucideIcons.keyRound),
      ('cctv', 'CCTV Power', LucideIcons.video),
    ];
    return Row(
      children: types.map((t) {
        final selected = _systemType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _systemType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Icon(t.$3, color: selected ? Colors.white : colors.textSecondary, size: 20),
                const SizedBox(height: 4),
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, int decimals = 0, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${decimals > 0 ? value.toStringAsFixed(decimals) : value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_recommendedGauge == null) return const SizedBox.shrink();
    final acceptable = _isAcceptable ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(acceptable ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: acceptable ? colors.accentPositive : colors.accentWarning, size: 24),
            const SizedBox(width: 8),
            Text(acceptable ? 'ACCEPTABLE' : 'CHECK SIZING', style: TextStyle(color: acceptable ? colors.accentPositive : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          Text(_recommendedGauge!, style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
          Text('Recommended Wire', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Voltage Drop', '${_voltageDrop?.toStringAsFixed(2)} V')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Drop %', '${_voltageDropPercent?.toStringAsFixed(1)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Max Distance', '$_maxDistance ft')),
          ]),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
