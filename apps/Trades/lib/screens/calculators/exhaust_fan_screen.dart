import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Exhaust Fan Calculator - Design System v2.6
/// CFM sizing for bathrooms, kitchens, and general exhaust
class ExhaustFanScreen extends ConsumerStatefulWidget {
  const ExhaustFanScreen({super.key});
  @override
  ConsumerState<ExhaustFanScreen> createState() => _ExhaustFanScreenState();
}

class _ExhaustFanScreenState extends ConsumerState<ExhaustFanScreen> {
  String _applicationType = 'bathroom';
  double _roomSquareFeet = 100;
  double _ceilingHeight = 9;
  int _airChangesPerHour = 8;
  double _ductLength = 10;
  int _elbowCount = 2;
  String _ductType = 'flex';

  double? _requiredCfm;
  double? _effectiveCfm;
  double? _staticPressure;
  String? _fanSize;
  double? _soneRating;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double requiredCfm;

    switch (_applicationType) {
      case 'bathroom':
        // Bathroom: 1 CFM per sq ft or 8 ACH minimum
        // Minimum 50 CFM for half bath, 70 CFM for full bath
        final volumeCfm = (_roomSquareFeet * _ceilingHeight * _airChangesPerHour) / 60;
        final areaCfm = _roomSquareFeet * 1.0;
        requiredCfm = [volumeCfm, areaCfm, 50.0].reduce((a, b) => a > b ? a : b);
        if (_roomSquareFeet > 100) requiredCfm = requiredCfm.clamp(70, 300);
        break;

      case 'kitchen':
        // Kitchen range hood: 100 CFM per linear foot of range
        // Or capture velocity method
        requiredCfm = 300; // Minimum for residential
        if (_roomSquareFeet > 150) requiredCfm = 400;
        if (_roomSquareFeet > 250) requiredCfm = 600;
        break;

      case 'laundry':
        // Laundry room: ~100 CFM typical
        requiredCfm = 100;
        break;

      case 'utility':
        // Utility room: 8-12 ACH
        requiredCfm = (_roomSquareFeet * _ceilingHeight * _airChangesPerHour) / 60;
        break;

      case 'commercial':
        // Commercial: Based on ACH for space type
        requiredCfm = (_roomSquareFeet * _ceilingHeight * _airChangesPerHour) / 60;
        break;

      default:
        requiredCfm = (_roomSquareFeet * _ceilingHeight * 8) / 60;
    }

    // Calculate static pressure (duct loss)
    double ductFrictionPer100;
    switch (_ductType) {
      case 'rigid': ductFrictionPer100 = 0.05; break;
      case 'flex': ductFrictionPer100 = 0.10; break;
      case 'spiral': ductFrictionPer100 = 0.04; break;
      default: ductFrictionPer100 = 0.08;
    }

    final ductLoss = (_ductLength / 100) * ductFrictionPer100 * (requiredCfm / 100);
    final elbowLoss = _elbowCount * 0.03; // ~0.03" WC per 90° elbow
    final terminalLoss = 0.05; // Wall cap/roof jack
    final staticPressure = ductLoss + elbowLoss + terminalLoss;

    // Effective CFM needed (fan must produce rated CFM at actual static)
    // Fans typically rated at 0.1" WC; derate for higher static
    final derateFactor = staticPressure > 0.1 ? 1.0 + (staticPressure - 0.1) * 2 : 1.0;
    final effectiveCfm = requiredCfm * derateFactor;

    // Fan size recommendation
    String fanSize;
    double soneRating;
    if (effectiveCfm <= 50) {
      fanSize = '50 CFM';
      soneRating = 0.5;
    } else if (effectiveCfm <= 80) {
      fanSize = '80 CFM';
      soneRating = 1.0;
    } else if (effectiveCfm <= 110) {
      fanSize = '110 CFM';
      soneRating = 1.5;
    } else if (effectiveCfm <= 150) {
      fanSize = '150 CFM';
      soneRating = 2.0;
    } else if (effectiveCfm <= 200) {
      fanSize = '200 CFM';
      soneRating = 2.5;
    } else {
      fanSize = '250+ CFM';
      soneRating = 3.0;
    }

    String recommendation;
    if (_applicationType == 'bathroom') {
      recommendation = 'Bath fan: Install near moisture source. Timer or humidity sensor recommended. <1.5 sones for quiet operation.';
    } else if (_applicationType == 'kitchen') {
      recommendation = 'Range hood: Capture velocity ~100 FPM at cooking surface. Make-up air required for >400 CFM.';
    } else {
      recommendation = 'General exhaust: Ensure adequate make-up air path. Backflow damper prevents cold air entry.';
    }

    if (staticPressure > 0.25) {
      recommendation += ' High static pressure - use in-line fan or boost duct size.';
    }

    if (_ductType == 'flex' && _ductLength > 15) {
      recommendation += ' Long flex duct reduces performance. Consider rigid duct.';
    }

    setState(() {
      _requiredCfm = requiredCfm;
      _effectiveCfm = effectiveCfm;
      _staticPressure = staticPressure;
      _fanSize = fanSize;
      _soneRating = soneRating;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _applicationType = 'bathroom';
      _roomSquareFeet = 100;
      _ceilingHeight = 9;
      _airChangesPerHour = 8;
      _ductLength = 10;
      _elbowCount = 2;
      _ductType = 'flex';
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
        title: Text('Exhaust Fan', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'APPLICATION'),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Area', value: _roomSquareFeet, min: 25, max: 500, unit: ' sq ft', onChanged: (v) { setState(() => _roomSquareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 7, max: 12, unit: ' ft', onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              if (_applicationType == 'utility' || _applicationType == 'commercial') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Air Changes/Hour', value: _airChangesPerHour.toDouble(), min: 4, max: 20, unit: ' ACH', onChanged: (v) { setState(() => _airChangesPerHour = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCTWORK'),
              const SizedBox(height: 12),
              _buildDuctTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Duct Length', value: _ductLength, min: 2, max: 50, unit: ' ft', onChanged: (v) { setState(() => _ductLength = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Number of Elbows', value: _elbowCount.toDouble(), min: 0, max: 6, unit: '', onChanged: (v) { setState(() => _elbowCount = v.round()); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FAN SELECTION'),
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
        Icon(LucideIcons.fan, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Bath fans: 1 CFM/sq ft min. Kitchen hoods: 100 CFM/linear ft of range. Select fan CFM rated at actual static pressure.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [
      ('bathroom', 'Bathroom'),
      ('kitchen', 'Kitchen'),
      ('laundry', 'Laundry'),
      ('utility', 'Utility'),
      ('commercial', 'Commercial'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: apps.map((a) {
        final selected = _applicationType == a.$1;
        return GestureDetector(
          onTap: () { setState(() => _applicationType = a.$1); _calculate(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDuctTypeSelector(ZaftoColors colors) {
    final types = [('rigid', 'Rigid'), ('flex', 'Flex'), ('spiral', 'Spiral')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duct Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final selected = _ductType == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _ductType = t.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
            child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_fanSize == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_fanSize ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
          Text('Recommended Fan', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Required', '${_requiredCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Effective', '${_effectiveCfm?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Static', '${_staticPressure?.toStringAsFixed(2)}" WC')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.volume2, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text('Target: <${_soneRating?.toStringAsFixed(1)} sones for quiet operation', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
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
