import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Compressor Oil Calculator - Design System v2.6
/// Oil charge, type selection, and diagnosis
class CompressorOilScreen extends ConsumerStatefulWidget {
  const CompressorOilScreen({super.key});
  @override
  ConsumerState<CompressorOilScreen> createState() => _CompressorOilScreenState();
}

class _CompressorOilScreenState extends ConsumerState<CompressorOilScreen> {
  double _compressorHp = 5;
  double _linesetLength = 50; // feet
  double _oilSightGlass = 50; // percent visible in glass
  double _suctionTemp = 50; // degrees F
  String _refrigerant = 'r410a';
  String _compressorType = 'scroll';
  String _oilType = 'poe';

  double? _factoryCharge;
  double? _additionalOil;
  String? _status;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Factory oil charge estimate (oz per HP)
    double ozPerHp;
    switch (_compressorType) {
      case 'scroll':
        ozPerHp = 8;
        break;
      case 'reciprocating':
        ozPerHp = 10;
        break;
      case 'rotary':
        ozPerHp = 6;
        break;
      case 'screw':
        ozPerHp = 12;
        break;
      default:
        ozPerHp = 8;
    }

    final factoryCharge = _compressorHp * ozPerHp;

    // Additional oil for long linesets (1 oz per 10-20 ft over 25 ft)
    double additionalOil = 0;
    if (_linesetLength > 25) {
      additionalOil = (_linesetLength - 25) / 15; // oz
    }

    // Status based on sight glass
    String status;
    if (_oilSightGlass < 25) {
      status = 'LOW OIL';
    } else if (_oilSightGlass > 75) {
      status = 'HIGH OIL';
    } else {
      status = 'NORMAL';
    }

    // Check for oil logging issues
    if (_suctionTemp < 35 && _oilSightGlass < 50) {
      status = 'OIL MIGRATION';
    }

    String recommendation;
    recommendation = 'Factory charge: ~${factoryCharge.toStringAsFixed(0)} oz. ';
    if (additionalOil > 0) {
      recommendation += 'Add ${additionalOil.toStringAsFixed(1)} oz for ${_linesetLength.toStringAsFixed(0)} ft lineset. ';
    }

    switch (status) {
      case 'LOW OIL':
        recommendation += 'LOW: Check for leaks, migration, or insufficient charge. ';
        recommendation += 'Verify suction velocity for oil return. ';
        break;
      case 'HIGH OIL':
        recommendation += 'HIGH: May indicate oil migration return or overcharge. ';
        recommendation += 'Monitor for compressor flooding. ';
        break;
      case 'OIL MIGRATION':
        recommendation += 'MIGRATION: Low suction temp + low oil suggests oil logged in evaporator. ';
        recommendation += 'Check suction line velocity (min 750 FPM). ';
        break;
      case 'NORMAL':
        recommendation += 'Oil level OK (1/4 to 3/4 sight glass). ';
        break;
    }

    // Oil type notes
    switch (_oilType) {
      case 'poe':
        recommendation += 'POE oil: Required for HFC (R-410A, R-134a). Hygroscopic - minimize exposure.';
        break;
      case 'pag':
        recommendation += 'PAG oil: Automotive (R-134a). Not for HVAC.';
        break;
      case 'mineral':
        recommendation += 'Mineral oil: R-22 systems only. Not compatible with HFC.';
        break;
      case 'ab':
        recommendation += 'Alkylbenzene: R-22, some transitional refrigerants.';
        break;
    }

    // Refrigerant compatibility
    switch (_refrigerant) {
      case 'r410a':
        if (_oilType != 'poe') {
          recommendation += ' WARNING: R-410A requires POE oil!';
        }
        break;
      case 'r22':
        if (_oilType == 'poe') {
          recommendation += ' Note: POE OK for R-22 but mineral preferred.';
        }
        break;
    }

    recommendation += ' Check oil at stable running conditions. Log sight glass level.';

    setState(() {
      _factoryCharge = factoryCharge;
      _additionalOil = additionalOil;
      _status = status;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _compressorHp = 5;
      _linesetLength = 50;
      _oilSightGlass = 50;
      _suctionTemp = 50;
      _refrigerant = 'r410a';
      _compressorType = 'scroll';
      _oilType = 'poe';
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
        title: Text('Compressor Oil', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COMPRESSOR TYPE'),
              const SizedBox(height: 12),
              _buildCompressorTypeSelector(colors),
              const SizedBox(height: 12),
              _buildOilTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Compressor HP', _compressorHp, 1, 50, ' HP', (v) { setState(() => _compressorHp = v); _calculate(); }, decimals: 1)),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Lineset', _linesetLength, 10, 200, ' ft', (v) { setState(() => _linesetLength = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CURRENT READINGS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Sight Glass', _oilSightGlass, 0, 100, '%', (v) { setState(() => _oilSightGlass = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Suction Temp', _suctionTemp, 20, 80, '°F', (v) { setState(() => _suctionTemp = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'OIL STATUS'),
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
        Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Oil level 1/4-3/4 in sight glass at stable operation. Add oil for long linesets. Match oil to refrigerant.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCompressorTypeSelector(ZaftoColors colors) {
    final types = [('scroll', 'Scroll'), ('reciprocating', 'Recip'), ('rotary', 'Rotary'), ('screw', 'Screw')];
    return Row(
      children: types.map((t) {
        final selected = _compressorType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _compressorType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOilTypeSelector(ZaftoColors colors) {
    final types = [('poe', 'POE'), ('mineral', 'Mineral'), ('ab', 'AB'), ('pag', 'PAG')];
    return Row(
      children: types.map((t) {
        final selected = _oilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _oilType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, {int decimals = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_factoryCharge == null) return const SizedBox.shrink();

    Color statusColor;
    switch (_status) {
      case 'NORMAL':
        statusColor = Colors.green;
        break;
      case 'LOW OIL':
      case 'OIL MIGRATION':
        statusColor = Colors.red;
        break;
      case 'HIGH OIL':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          // Oil sight glass visualization
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: colors.borderDefault, width: 3),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 74,
                  height: 114 * (_oilSightGlass / 100),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(37),
                  ),
                ),
                Positioned(
                  bottom: 114 * 0.25,
                  child: Container(width: 60, height: 1, color: Colors.green),
                ),
                Positioned(
                  bottom: 114 * 0.75,
                  child: Container(width: 60, height: 1, color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('${_oilSightGlass.toStringAsFixed(0)}% Sight Glass', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(_status ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Factory', '${_factoryCharge?.toStringAsFixed(0)} oz')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Additional', '${_additionalOil?.toStringAsFixed(1)} oz')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total', '${((_factoryCharge ?? 0) + (_additionalOil ?? 0)).toStringAsFixed(1)} oz')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(statusColor == Colors.green ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: statusColor, size: 16),
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
