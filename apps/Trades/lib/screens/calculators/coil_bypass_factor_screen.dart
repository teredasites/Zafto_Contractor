import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Coil Bypass Factor Calculator - Design System v2.6
/// Bypass factor and apparatus dew point analysis
class CoilBypassFactorScreen extends ConsumerStatefulWidget {
  const CoilBypassFactorScreen({super.key});
  @override
  ConsumerState<CoilBypassFactorScreen> createState() => _CoilBypassFactorScreenState();
}

class _CoilBypassFactorScreenState extends ConsumerState<CoilBypassFactorScreen> {
  double _enteringDb = 80;
  double _enteringWb = 67;
  double _leavingDb = 55;
  double _leavingWb = 54;
  double _coilRows = 4;
  double _finsPerInch = 12;
  String _coilType = 'dx';

  double? _bypassFactor;
  double? _adp;
  double? _contactFactor;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Approximate apparatus dew point (ADP)
    // Using simplified psychrometric relationship
    // ADP ≈ Leaving WB for well-designed coil
    final adp = _leavingWb;

    // Bypass Factor = (Leaving DB - ADP) / (Entering DB - ADP)
    final denominator = _enteringDb - adp;
    final bypassFactor = denominator > 0 ? (_leavingDb - adp) / denominator : 0.0;

    // Contact Factor = 1 - Bypass Factor
    final contactFactor = 1 - bypassFactor;

    String recommendation;
    if (bypassFactor < 0.05) {
      recommendation = 'Very low bypass (${(bypassFactor * 100).toStringAsFixed(1)}%). Deep coil, high contact. Check for frosting.';
    } else if (bypassFactor < 0.15) {
      recommendation = 'Low bypass (${(bypassFactor * 100).toStringAsFixed(1)}%). Good dehumidification, typical comfort cooling.';
    } else if (bypassFactor < 0.30) {
      recommendation = 'Moderate bypass. Standard coil performance.';
    } else {
      recommendation = 'High bypass (${(bypassFactor * 100).toStringAsFixed(1)}%). Less dehumidification. Consider deeper coil or lower velocity.';
    }

    recommendation += ' ADP: ${adp.toStringAsFixed(0)}°F. Contact factor: ${(contactFactor * 100).toStringAsFixed(0)}%.';

    switch (_coilType) {
      case 'dx':
        recommendation += ' DX coil: Typical bypass 0.10-0.20. Verify superheat for proper loading.';
        break;
      case 'chw':
        recommendation += ' Chilled water: Bypass varies with water temp and flow. Check GPM/ton.';
        break;
    }

    // Coil geometry effects
    if (_coilRows >= 6) {
      recommendation += ' Deep coil (${_coilRows.toStringAsFixed(0)} rows) provides low bypass for dehumidification.';
    } else if (_coilRows <= 2) {
      recommendation += ' Shallow coil may have high bypass. Limited dehumidification.';
    }

    if (_finsPerInch > 14) {
      recommendation += ' Dense fin spacing: More surface but higher pressure drop. Watch for icing.';
    }

    setState(() {
      _bypassFactor = bypassFactor.clamp(0, 1);
      _adp = adp;
      _contactFactor = contactFactor.clamp(0, 1);
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _enteringDb = 80;
      _enteringWb = 67;
      _leavingDb = 55;
      _leavingWb = 54;
      _coilRows = 4;
      _finsPerInch = 12;
      _coilType = 'dx';
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
        title: Text('Bypass Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COIL TYPE'),
              const SizedBox(height: 12),
              _buildCoilTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ENTERING AIR'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Dry Bulb', _enteringDb, 70, 95, '°F', (v) { setState(() => _enteringDb = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Wet Bulb', _enteringWb, 60, 80, '°F', (v) { setState(() => _enteringWb = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LEAVING AIR'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Dry Bulb', _leavingDb, 45, 65, '°F', (v) { setState(() => _leavingDb = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Wet Bulb', _leavingWb, 45, 60, '°F', (v) { setState(() => _leavingWb = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'COIL GEOMETRY'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Rows', _coilRows, 2, 8, '', (v) { setState(() => _coilRows = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'FPI', _finsPerInch, 8, 18, '', (v) { setState(() => _finsPerInch = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'BYPASS ANALYSIS'),
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
        Expanded(child: Text('Bypass factor = portion of air not contacting coil. Lower bypass = better dehumidification. Typical range 0.05-0.30.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCoilTypeSelector(ZaftoColors colors) {
    final types = [('dx', 'DX (Refrigerant)'), ('chw', 'Chilled Water')];
    return Row(
      children: types.map((t) {
        final selected = _coilType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _coilType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
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

  Widget _buildResultCard(ZaftoColors colors) {
    if (_bypassFactor == null) return const SizedBox.shrink();

    final isLow = _bypassFactor! < 0.15;
    final isHigh = _bypassFactor! > 0.30;
    final statusColor = isLow ? Colors.green : (isHigh ? Colors.orange : Colors.blue);
    final status = isLow ? 'LOW BYPASS' : (isHigh ? 'HIGH BYPASS' : 'NORMAL');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${(_bypassFactor! * 100).toStringAsFixed(1)}%', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Bypass Factor', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'ADP', '${_adp?.toStringAsFixed(0)}°F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Contact Factor', '${((_contactFactor ?? 0) * 100).toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Coil', '${_coilRows.toStringAsFixed(0)} row')),
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
