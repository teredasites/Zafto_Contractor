import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Make-Up Air Calculator - Design System v2.6
/// MUA requirements for exhaust and combustion systems
class MakeupAirScreen extends ConsumerStatefulWidget {
  const MakeupAirScreen({super.key});
  @override
  ConsumerState<MakeupAirScreen> createState() => _MakeupAirScreenState();
}

class _MakeupAirScreenState extends ConsumerState<MakeupAirScreen> {
  double _rangeHoodCfm = 400;
  double _bathExhaustCfm = 80;
  double _dryerCfm = 150;
  double _combustionCfm = 0;
  double _otherExhaustCfm = 0;
  String _buildingTightness = 'average';
  bool _hasBalancedVent = false;

  double? _totalExhaust;
  double? _naturalInfiltration;
  double? _muaRequired;
  String? _muaType;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Total exhaust CFM
    final totalExhaust = _rangeHoodCfm + _bathExhaustCfm + _dryerCfm + _combustionCfm + _otherExhaustCfm;

    // Natural infiltration depends on building tightness
    double infiltrationRate;
    switch (_buildingTightness) {
      case 'leaky': infiltrationRate = 0.5; break; // 50% of exhaust can infiltrate
      case 'average': infiltrationRate = 0.35; break;
      case 'tight': infiltrationRate = 0.2; break;
      case 'very_tight': infiltrationRate = 0.1; break;
      default: infiltrationRate = 0.3;
    }

    var naturalInfiltration = totalExhaust * infiltrationRate;

    // Balanced ventilation provides make-up
    double balancedSupply = 0;
    if (_hasBalancedVent) {
      // ERV/HRV typically provides 50-150 CFM
      balancedSupply = 100;
    }

    // MUA required = exhaust - infiltration - balanced
    var muaRequired = totalExhaust - naturalInfiltration - balancedSupply;
    if (muaRequired < 0) muaRequired = 0;

    // IRC requirement: MUA for kitchen exhaust > 400 CFM
    final needsMechMua = _rangeHoodCfm > 400;

    // MUA system type recommendation
    String muaType;
    if (muaRequired <= 0) {
      muaType = 'None Required';
    } else if (muaRequired <= 100) {
      muaType = 'Passive MUA Damper';
    } else if (muaRequired <= 300) {
      muaType = 'Motorized MUA Damper';
    } else {
      muaType = 'Dedicated MUA Unit (tempered)';
    }

    String recommendation;
    if (_rangeHoodCfm > 400) {
      recommendation = 'IRC requires make-up air for kitchen exhaust >400 CFM. MUA must be interlocked with range hood.';
    } else if (muaRequired <= 0) {
      recommendation = 'Building infiltration and balanced ventilation sufficient. Monitor for backdrafting of combustion appliances.';
    } else if (muaRequired < 150) {
      recommendation = 'Moderate MUA need. Passive damper or transfer grille may suffice. Locate away from exhaust outlets.';
    } else {
      recommendation = 'Significant MUA requirement. Tempered/heated MUA recommended for cold climates. Consider dedicated unit.';
    }

    if (_combustionCfm > 0) {
      recommendation += ' Combustion appliances: Ensure MUA path doesn\'t create negative pressure near appliances.';
    }

    if (_buildingTightness == 'very_tight') {
      recommendation += ' Very tight home: MUA critical. Test for negative pressure with blower door.';
    }

    setState(() {
      _totalExhaust = totalExhaust;
      _naturalInfiltration = naturalInfiltration;
      _muaRequired = muaRequired;
      _muaType = muaType;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _rangeHoodCfm = 400;
      _bathExhaustCfm = 80;
      _dryerCfm = 150;
      _combustionCfm = 0;
      _otherExhaustCfm = 0;
      _buildingTightness = 'average';
      _hasBalancedVent = false;
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
        title: Text('Make-Up Air', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EXHAUST SOURCES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Range Hood', value: _rangeHoodCfm, min: 0, max: 1200, unit: ' CFM', onChanged: (v) { setState(() => _rangeHoodCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Bath Exhaust (total)', value: _bathExhaustCfm, min: 0, max: 300, unit: ' CFM', onChanged: (v) { setState(() => _bathExhaustCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Dryer', value: _dryerCfm, min: 0, max: 200, unit: ' CFM', onChanged: (v) { setState(() => _dryerCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Combustion Air (draft hoods)', value: _combustionCfm, min: 0, max: 300, unit: ' CFM', onChanged: (v) { setState(() => _combustionCfm = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Other Exhaust', value: _otherExhaustCfm, min: 0, max: 500, unit: ' CFM', onChanged: (v) { setState(() => _otherExhaustCfm = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BUILDING'),
              const SizedBox(height: 12),
              _buildTightnessSelector(colors),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Has balanced ventilation (ERV/HRV)', _hasBalancedVent, (v) { setState(() => _hasBalancedVent = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MAKE-UP AIR REQUIREMENT'),
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
        Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('MUA replaces exhausted air. IRC requires MUA for range hoods >400 CFM. Prevents negative pressure and backdrafting.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildTightnessSelector(ZaftoColors colors) {
    final levels = [
      ('leaky', 'Leaky', '>7 ACH50'),
      ('average', 'Average', '5-7 ACH50'),
      ('tight', 'Tight', '3-5 ACH50'),
      ('very_tight', 'Very Tight', '<3 ACH50'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Building Air Tightness', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((l) {
            final selected = _buildingTightness == l.$1;
            return GestureDetector(
              onTap: () { setState(() => _buildingTightness = l.$1); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? colors.accentPrimary : colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                ),
                child: Column(children: [
                  Text(l.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(l.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
                ]),
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

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? colors.accentPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? colors.accentPrimary : colors.borderDefault, width: 2),
            ),
            child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_muaRequired == null) return const SizedBox.shrink();

    final needsMua = _muaRequired! > 0;
    final isCodeRequired = _rangeHoodCfm > 400;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          if (isCodeRequired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('IRC REQUIRES MUA FOR >400 CFM HOOD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          Text('${_muaRequired?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('CFM Make-Up Air Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: needsMua ? colors.accentPrimary : Colors.green, borderRadius: BorderRadius.circular(20)),
            child: Text(_muaType ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Total Exhaust', '${_totalExhaust?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Infiltration', '${_naturalInfiltration?.toStringAsFixed(0)} CFM')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'MUA Need', '${_muaRequired?.toStringAsFixed(0)} CFM')),
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
