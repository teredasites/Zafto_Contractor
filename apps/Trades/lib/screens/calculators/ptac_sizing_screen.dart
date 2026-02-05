import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// PTAC/PTHP Sizing Calculator - Design System v2.6
/// Packaged terminal air conditioner and heat pump sizing
class PtacSizingScreen extends ConsumerStatefulWidget {
  const PtacSizingScreen({super.key});
  @override
  ConsumerState<PtacSizingScreen> createState() => _PtacSizingScreenState();
}

class _PtacSizingScreenState extends ConsumerState<PtacSizingScreen> {
  double _roomSquareFeet = 350;
  double _ceilingHeight = 9;
  String _exposure = 'north';
  String _unitType = 'ptac';
  int _windowArea = 20;
  int _occupants = 2;
  bool _hasKitchenette = false;

  double? _coolingBtu;
  double? _heatingBtu;
  String? _recommendedSize;
  double? _electricKw;
  String? _sleeveSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Base cooling load: ~25-30 BTU/sq ft for hotel/motel
    double baseBtu = _roomSquareFeet * 28;

    // Exposure factor
    double exposureFactor;
    switch (_exposure) {
      case 'north': exposureFactor = 1.0; break;
      case 'east': exposureFactor = 1.1; break;
      case 'west': exposureFactor = 1.2; break;
      case 'south': exposureFactor = 1.15; break;
      default: exposureFactor = 1.0;
    }

    // Window load: ~200 BTU per sq ft of window
    final windowLoad = _windowArea * 200;

    // Occupant load: ~400 BTU per person
    final occupantLoad = _occupants * 400;

    // Kitchenette load
    final kitchenLoad = _hasKitchenette ? 1500 : 0;

    // Total cooling
    final coolingBtu = (baseBtu * exposureFactor) + windowLoad + occupantLoad + kitchenLoad;

    // Heating (generally ~1.0-1.2x cooling for heat pump)
    final heatingBtu = coolingBtu * 1.1;

    // Standard PTAC sizes: 7000, 9000, 12000, 15000
    String recommendedSize;
    double electricKw;
    String sleeveSize;

    if (coolingBtu <= 7500) {
      recommendedSize = '7,000 BTU';
      electricKw = _unitType == 'ptac' ? 3.5 : 0; // Electric heat strip
      sleeveSize = '42" × 16"';
    } else if (coolingBtu <= 10000) {
      recommendedSize = '9,000 BTU';
      electricKw = _unitType == 'ptac' ? 4.5 : 0;
      sleeveSize = '42" × 16"';
    } else if (coolingBtu <= 13000) {
      recommendedSize = '12,000 BTU';
      electricKw = _unitType == 'ptac' ? 5.0 : 0;
      sleeveSize = '42" × 16"';
    } else if (coolingBtu <= 16000) {
      recommendedSize = '15,000 BTU';
      electricKw = _unitType == 'ptac' ? 5.0 : 0;
      sleeveSize = '42" × 16"';
    } else {
      recommendedSize = 'Multiple units needed';
      electricKw = 0;
      sleeveSize = 'N/A';
    }

    String recommendation;
    if (_unitType == 'pthp') {
      recommendation = 'PTHP (heat pump): More efficient heating, no electric strips required for mild climates. Add backup heat for cold climates.';
    } else {
      recommendation = 'PTAC: Electric resistance heat. ${electricKw}kW strip heater. Higher operating cost than heat pump.';
    }

    if (_exposure == 'west') {
      recommendation += ' West exposure: High solar gain in afternoon. Consider low-E glass or solar film.';
    }

    if (coolingBtu > 15000) {
      recommendation += ' Load exceeds single PTAC capacity. Consider two units or alternative system.';
    }

    if (_hasKitchenette) {
      recommendation += ' Kitchenette: Ensure adequate CFM for cooking exhaust.';
    }

    setState(() {
      _coolingBtu = coolingBtu;
      _heatingBtu = heatingBtu;
      _recommendedSize = recommendedSize;
      _electricKw = electricKw;
      _sleeveSize = sleeveSize;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _roomSquareFeet = 350;
      _ceilingHeight = 9;
      _exposure = 'north';
      _unitType = 'ptac';
      _windowArea = 20;
      _occupants = 2;
      _hasKitchenette = false;
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
        title: Text('PTAC / PTHP', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Area', value: _roomSquareFeet, min: 150, max: 600, unit: ' sq ft', onChanged: (v) { setState(() => _roomSquareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Window Area', _windowArea.toDouble(), 5, 50, ' sq ft', (v) { setState(() => _windowArea = v.round()); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Occupants', _occupants.toDouble(), 1, 4, '', (v) { setState(() => _occupants = v.round()); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'EXPOSURE'),
              const SizedBox(height: 12),
              _buildExposureSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'UNIT TYPE'),
              const SizedBox(height: 12),
              _buildUnitTypeSelector(colors),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, 'Has Kitchenette', _hasKitchenette, (v) { setState(() => _hasKitchenette = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'UNIT SIZING'),
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
        Icon(LucideIcons.building, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('PTAC/PTHP sizing for hotels, apartments, senior living. Standard sleeves: 42"×16". PTHP more efficient than electric heat.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildExposureSelector(ZaftoColors colors) {
    final exposures = [('north', 'North'), ('east', 'East'), ('south', 'South'), ('west', 'West')];
    return Row(
      children: exposures.map((e) {
        final selected = _exposure == e.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _exposure = e.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: e != exposures.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(e.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUnitTypeSelector(ZaftoColors colors) {
    final types = [
      ('ptac', 'PTAC', 'Electric Heat'),
      ('pthp', 'PTHP', 'Heat Pump'),
    ];
    return Row(
      children: types.map((t) {
        final selected = _unitType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _unitType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
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
    if (_coolingBtu == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_recommendedSize ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          Text(_unitType == 'ptac' ? 'PTAC Unit' : 'PTHP Unit', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.snowflake, color: Colors.blue, size: 18),
                  const SizedBox(height: 4),
                  Text('Cooling', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${(_coolingBtu! / 1000).toStringAsFixed(1)}k BTU', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(LucideIcons.flame, color: Colors.orange, size: 18),
                  const SizedBox(height: 4),
                  Text('Heating', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                  Text('${(_heatingBtu! / 1000).toStringAsFixed(1)}k BTU', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Sleeve', _sleeveSize ?? '')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Electric', _unitType == 'ptac' ? '${_electricKw}kW' : 'N/A')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Area', '${_roomSquareFeet.toStringAsFixed(0)} sf')),
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
