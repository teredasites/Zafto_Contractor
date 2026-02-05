import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Sensible Heat Ratio Calculator - Design System v2.6
/// SHR calculation for equipment selection
class SensibleHeatRatioScreen extends ConsumerStatefulWidget {
  const SensibleHeatRatioScreen({super.key});
  @override
  ConsumerState<SensibleHeatRatioScreen> createState() => _SensibleHeatRatioScreenState();
}

class _SensibleHeatRatioScreenState extends ConsumerState<SensibleHeatRatioScreen> {
  double _totalCoolingBtu = 36000;
  double _sensibleBtu = 27000;
  double _latentBtu = 9000;
  String _inputMode = 'separate';

  double? _shr;
  String? _equipmentMatch;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    double sensible;
    double latent;
    double total;

    if (_inputMode == 'separate') {
      sensible = _sensibleBtu;
      latent = _latentBtu;
      total = sensible + latent;
    } else {
      total = _totalCoolingBtu;
      sensible = _sensibleBtu;
      latent = total - sensible;
    }

    final shr = total > 0 ? sensible / total : 0.0;

    String equipmentMatch;
    String recommendation;

    if (shr >= 0.85) {
      equipmentMatch = 'High SHR Equipment';
      recommendation = 'Dry climate application. Standard A/C works well. May be oversized for humidity removal.';
    } else if (shr >= 0.75) {
      equipmentMatch = 'Standard Equipment (0.75-0.80 SHR)';
      recommendation = 'Typical residential/commercial application. Standard equipment should match well.';
    } else if (shr >= 0.65) {
      equipmentMatch = 'Low SHR Equipment';
      recommendation = 'High latent load. Consider oversizing or dedicated dehumidification.';
    } else {
      equipmentMatch = 'Dedicated Dehumidification';
      recommendation = 'Very high moisture load. Standard A/C won\'t dehumidify adequately. Add dehumidifier.';
    }

    setState(() {
      _shr = shr;
      _equipmentMatch = equipmentMatch;
      _recommendation = recommendation;
      if (_inputMode == 'separate') {
        _totalCoolingBtu = total;
      } else {
        _latentBtu = latent;
      }
    });
  }

  void _reset() {
    setState(() {
      _totalCoolingBtu = 36000;
      _sensibleBtu = 27000;
      _latentBtu = 9000;
      _inputMode = 'separate';
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
        title: Text('Sensible Heat Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INPUT MODE'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: '', options: const ['Sensible + Latent', 'Total + Sensible'], selectedIndex: _inputMode == 'separate' ? 0 : 1, onChanged: (i) { setState(() => _inputMode = i == 0 ? 'separate' : 'total'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD VALUES'),
              const SizedBox(height: 12),
              if (_inputMode == 'separate') ...[
                _buildSliderRow(colors, label: 'Sensible Load', value: _sensibleBtu, min: 5000, max: 100000, unit: ' BTU', onChanged: (v) { setState(() => _sensibleBtu = v); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Latent Load', value: _latentBtu, min: 1000, max: 50000, unit: ' BTU', onChanged: (v) { setState(() => _latentBtu = v); _calculate(); }),
              ] else ...[
                _buildSliderRow(colors, label: 'Total Cooling Load', value: _totalCoolingBtu, min: 10000, max: 150000, unit: ' BTU', onChanged: (v) { setState(() => _totalCoolingBtu = v); _calculate(); }),
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Sensible Load', value: _sensibleBtu, min: 5000, max: _totalCoolingBtu, unit: ' BTU', onChanged: (v) { setState(() => _sensibleBtu = v); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SHR CALCULATION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildShrGuide(colors),
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
        Icon(LucideIcons.divide, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('SHR = Sensible / Total. Match equipment SHR to load SHR for proper dehumidification.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
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
            child: Text('${(value / 1000).toStringAsFixed(0)}k$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    return Container(
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
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_shr == null) return const SizedBox.shrink();

    Color shrColor;
    if (_shr! >= 0.80) {
      shrColor = Colors.green;
    } else if (_shr! >= 0.70) {
      shrColor = colors.accentPrimary;
    } else if (_shr! >= 0.60) {
      shrColor = Colors.orange;
    } else {
      shrColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_shr!.toStringAsFixed(2), style: TextStyle(color: shrColor, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Sensible Heat Ratio', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: shrColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_equipmentMatch ?? '', style: TextStyle(color: shrColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Sensible', '${(_sensibleBtu / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Latent', '${(_latentBtu / 1000).toStringAsFixed(0)}k BTU')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Total', '${(_totalCoolingBtu / 1000).toStringAsFixed(0)}k BTU')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildShrGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHR GUIDE', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildGuideRow(colors, '0.85+', 'Dry climate, minimal humidity', Colors.green),
          _buildGuideRow(colors, '0.75-0.84', 'Standard residential/commercial', colors.accentPrimary),
          _buildGuideRow(colors, '0.65-0.74', 'Humid climate, high moisture', Colors.orange),
          _buildGuideRow(colors, '<0.65', 'Pool rooms, greenhouses', Colors.red),
        ],
      ),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String range, String description, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: indicatorColor, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
