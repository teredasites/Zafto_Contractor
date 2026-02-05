import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Network Cable Calculator - Design System v2.6
/// Cat5e/Cat6/Cat6a run length limits and recommendations
class NetworkCableScreen extends ConsumerStatefulWidget {
  const NetworkCableScreen({super.key});
  @override
  ConsumerState<NetworkCableScreen> createState() => _NetworkCableScreenState();
}

class _NetworkCableScreenState extends ConsumerState<NetworkCableScreen> {
  String _cableType = 'cat6';
  double _runLength = 150;
  String _application = 'gigabit';
  bool _includePatchCables = true;

  String? _status;
  String? _maxSpeed;
  double? _remainingLength;
  String? _recommendation;
  bool? _isCompliant;

  final Map<String, Map<String, dynamic>> _cableSpecs = {
    'cat5e': {'maxLength': 100, 'maxSpeed': '1 Gbps', 'bandwidth': '100 MHz'},
    'cat6': {'maxLength': 100, 'maxSpeed': '10 Gbps (55m)', 'bandwidth': '250 MHz'},
    'cat6a': {'maxLength': 100, 'maxSpeed': '10 Gbps', 'bandwidth': '500 MHz'},
    'cat7': {'maxLength': 100, 'maxSpeed': '10 Gbps', 'bandwidth': '600 MHz'},
    'cat8': {'maxLength': 30, 'maxSpeed': '40 Gbps', 'bandwidth': '2000 MHz'},
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    final specs = _cableSpecs[_cableType]!;
    final maxLength = (specs['maxLength'] as int).toDouble();
    final patchAllowance = _includePatchCables ? 10.0 : 0.0;
    final effectiveMax = maxLength - patchAllowance;
    final runLengthMeters = _runLength * 0.3048;
    final remaining = effectiveMax - runLengthMeters;
    final compliant = runLengthMeters <= effectiveMax;

    String recommendation;
    if (!compliant) {
      recommendation = 'Run exceeds maximum. Use fiber or add switch.';
    } else if (remaining < 10) {
      recommendation = 'Near limit. Allow margin for patch cables.';
    } else {
      recommendation = 'Within TIA-568 limits.';
    }

    String speed = specs['maxSpeed'] as String;
    if (_cableType == 'cat6' && runLengthMeters > 55) {
      speed = '1 Gbps (exceeds 55m for 10G)';
    }

    setState(() {
      _status = compliant ? 'COMPLIANT' : 'EXCEEDS LIMIT';
      _maxSpeed = speed;
      _remainingLength = remaining;
      _recommendation = recommendation;
      _isCompliant = compliant;
    });
  }

  void _reset() {
    setState(() {
      _cableType = 'cat6';
      _runLength = 150;
      _application = 'gigabit';
      _includePatchCables = true;
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
        title: Text('Network Cable', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CABLE TYPE'),
              const SizedBox(height: 12),
              _buildCableTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RUN PARAMETERS'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Horizontal Run Length', value: _runLength, min: 10, max: 400, unit: ' ft', onChanged: (v) { setState(() => _runLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'Include patch cable allowance (10m)', value: _includePatchCables, onChanged: (v) { setState(() => _includePatchCables = v ?? true); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'COMPLIANCE CHECK'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildSpecsCard(colors),
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
        Icon(LucideIcons.network, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('TIA-568 limits horizontal runs to 90m (295ft) permanent link + 10m patch cables = 100m channel.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCableTypeSelector(ZaftoColors colors) {
    final types = ['cat5e', 'cat6', 'cat6a', 'cat7', 'cat8'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final selected = _cableType == t;
        return GestureDetector(
          onTap: () { setState(() => _cableType = t); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(t.toUpperCase(), style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('${value.round()}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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

  Widget _buildCheckboxRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool?> onChanged}) {
    return Row(children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
    ]);
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_status == null) return const SizedBox.shrink();
    final compliant = _isCompliant ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(compliant ? LucideIcons.checkCircle : LucideIcons.xCircle, color: compliant ? colors.accentPositive : colors.accentNegative, size: 24),
            const SizedBox(width: 8),
            Text(_status!, style: TextStyle(color: compliant ? colors.accentPositive : colors.accentNegative, fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          Text(_maxSpeed ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          Text('Maximum Speed', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(ZaftoColors colors) {
    final specs = _cableSpecs[_cableType]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_cableType.toUpperCase()} SPECIFICATIONS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildSpecRow(colors, 'Max Channel Length', '${specs['maxLength']}m (328 ft)'),
          _buildSpecRow(colors, 'Bandwidth', specs['bandwidth'] as String),
          _buildSpecRow(colors, 'Max Speed', specs['maxSpeed'] as String),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
