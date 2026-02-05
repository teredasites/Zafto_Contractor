import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Combustion Air Calculator - Design System v2.6
/// NFGC/IMC combustion air requirements
class CombustionAirScreen extends ConsumerStatefulWidget {
  const CombustionAirScreen({super.key});
  @override
  ConsumerState<CombustionAirScreen> createState() => _CombustionAirScreenState();
}

class _CombustionAirScreenState extends ConsumerState<CombustionAirScreen> {
  double _totalBtuInput = 100000;
  double _roomVolume = 1000;
  String _airSource = 'indoor';
  bool _hasOutdoorOpening = false;
  int _outdoorOpeningSqIn = 0;
  String _applianceType = 'furnace';

  double? _cfmRequired;
  double? _openingHighSqIn;
  double? _openingLowSqIn;
  String? _complianceMethod;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // CFM required (15 CFM per 1000 BTU for gas)
    final cfmRequired = (_totalBtuInput / 1000) * 15;

    double openingHigh = 0;
    double openingLow = 0;
    String complianceMethod;
    String recommendation;

    if (_airSource == 'indoor') {
      // Indoor air - confined space check
      // 50 cu ft per 1000 BTU minimum
      final minVolume = (_totalBtuInput / 1000) * 50;

      if (_roomVolume >= minVolume) {
        complianceMethod = 'Unconfined Space';
        recommendation = 'Room volume adequate (${_roomVolume.toStringAsFixed(0)} ≥ ${minVolume.toStringAsFixed(0)} cu ft). No additional openings required if rest of building is unconfined.';
      } else {
        complianceMethod = 'Confined Space - Indoor Air';
        // Need openings to rest of building
        // 1 sq in per 1000 BTU each opening
        openingHigh = _totalBtuInput / 1000;
        openingLow = _totalBtuInput / 1000;
        recommendation = 'Room is confined space. Two permanent openings required to adjacent spaces (within 12" of ceiling and floor).';
      }
    } else if (_airSource == 'outdoor_direct') {
      complianceMethod = 'Direct Outdoor Air';
      // 1 sq in per 4000 BTU for direct outdoor
      openingHigh = _totalBtuInput / 4000;
      openingLow = _totalBtuInput / 4000;
      recommendation = 'Direct outdoor openings: one high, one low. Minimum 100 sq in each. Screen with 1/4" mesh max.';
    } else {
      complianceMethod = 'Outdoor Air via Duct';
      // 1 sq in per 2000 BTU for ducted (horizontal)
      // 1 sq in per 4000 BTU for ducted (vertical)
      openingHigh = _totalBtuInput / 4000;
      openingLow = _totalBtuInput / 2000;
      recommendation = 'Ducted combustion air: horizontal duct = 1 sq in/2000 BTU, vertical duct = 1 sq in/4000 BTU.';
    }

    // Minimum 100 sq in per opening
    if (openingHigh > 0 && openingHigh < 100) openingHigh = 100;
    if (openingLow > 0 && openingLow < 100) openingLow = 100;

    // Appliance-specific notes
    if (_applianceType == 'waterheater' && _airSource == 'indoor') {
      recommendation += ' Water heater in confined space - ensure adequate draft and consider direct vent unit.';
    }

    setState(() {
      _cfmRequired = cfmRequired;
      _openingHighSqIn = openingHigh;
      _openingLowSqIn = openingLow;
      _complianceMethod = complianceMethod;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _totalBtuInput = 100000;
      _roomVolume = 1000;
      _airSource = 'indoor';
      _hasOutdoorOpening = false;
      _outdoorOpeningSqIn = 0;
      _applianceType = 'furnace';
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
        title: Text('Combustion Air', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'APPLIANCES'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Total BTU Input', value: _totalBtuInput, min: 20000, max: 500000, unit: ' BTU', onChanged: (v) { setState(() => _totalBtuInput = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Primary Appliance', options: const ['Furnace', 'Water Heater', 'Boiler'], selectedIndex: ['furnace', 'waterheater', 'boiler'].indexOf(_applianceType), onChanged: (i) { setState(() => _applianceType = ['furnace', 'waterheater', 'boiler'][i]); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MECHANICAL ROOM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Room Volume', value: _roomVolume, min: 200, max: 5000, unit: ' cu ft', onChanged: (v) { setState(() => _roomVolume = v); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COMBUSTION AIR SOURCE'),
              const SizedBox(height: 12),
              _buildAirSourceSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'REQUIREMENTS'),
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
        Expanded(child: Text('Calculate combustion air per NFGC/IMC. All gas appliances require adequate combustion air for safe operation.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildAirSourceSelector(ZaftoColors colors) {
    final sources = [
      ('indoor', 'Indoor Air', 'From building'),
      ('outdoor_direct', 'Direct Outdoor', 'Wall openings'),
      ('outdoor_ducted', 'Ducted Outdoor', 'Via ductwork'),
    ];
    return Column(
      children: sources.map((s) {
        final selected = _airSource == s.$1;
        return GestureDetector(
          onTap: () { setState(() => _airSource = s.$1); _calculate(); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary : colors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Row(children: [
              Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(s.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required double value, required double min, required double max, required String unit, required ValueChanged<double> onChanged}) {
    final displayValue = unit == ' BTU' ? '${(value / 1000).toStringAsFixed(0)}k$unit' : '${value.toStringAsFixed(0)}$unit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text(displayValue, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12))),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_complianceMethod ?? '', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          if (_openingHighSqIn! > 0) ...[
            Row(children: [
              Expanded(child: _buildResultItem(colors, 'CFM Required', '${_cfmRequired?.toStringAsFixed(0)}')),
              Container(width: 1, height: 50, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'High Opening', '${_openingHighSqIn?.toStringAsFixed(0)} sq in')),
              Container(width: 1, height: 50, color: colors.borderDefault),
              Expanded(child: _buildResultItem(colors, 'Low Opening', '${_openingLowSqIn?.toStringAsFixed(0)} sq in')),
            ]),
          ] else ...[
            _buildResultItem(colors, 'CFM Required', '${_cfmRequired?.toStringAsFixed(0)} CFM'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(LucideIcons.checkCircle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('No additional openings required', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
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
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
