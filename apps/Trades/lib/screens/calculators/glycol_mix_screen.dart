import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Glycol Mix Calculator - Design System v2.6
/// Antifreeze mixing and freeze/burst protection
class GlycolMixScreen extends ConsumerStatefulWidget {
  const GlycolMixScreen({super.key});
  @override
  ConsumerState<GlycolMixScreen> createState() => _GlycolMixScreenState();
}

class _GlycolMixScreenState extends ConsumerState<GlycolMixScreen> {
  double _systemVolume = 50;
  double _targetFreezeProtection = 0;
  String _glycolType = 'propylene';
  String _calculationMode = 'new_fill';
  double _currentConcentration = 0;

  double? _glycolGallons;
  double? _waterGallons;
  double? _finalConcentration;
  double? _freezePoint;
  double? _burstPoint;
  double? _heatTransferPenalty;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Glycol freeze protection chart (approximate)
    // Propylene glycol (food-safe, less efficient)
    // Ethylene glycol (toxic, more efficient)

    // Find required concentration for target freeze protection
    double requiredConcentration;
    if (_glycolType == 'propylene') {
      // Propylene glycol freeze points
      if (_targetFreezeProtection >= 32) {
        requiredConcentration = 0;
      } else if (_targetFreezeProtection >= 25) {
        requiredConcentration = 15;
      } else if (_targetFreezeProtection >= 15) {
        requiredConcentration = 25;
      } else if (_targetFreezeProtection >= 0) {
        requiredConcentration = 35;
      } else if (_targetFreezeProtection >= -20) {
        requiredConcentration = 45;
      } else {
        requiredConcentration = 55;
      }
    } else {
      // Ethylene glycol - more efficient
      if (_targetFreezeProtection >= 32) {
        requiredConcentration = 0;
      } else if (_targetFreezeProtection >= 25) {
        requiredConcentration = 12;
      } else if (_targetFreezeProtection >= 15) {
        requiredConcentration = 20;
      } else if (_targetFreezeProtection >= 0) {
        requiredConcentration = 30;
      } else if (_targetFreezeProtection >= -20) {
        requiredConcentration = 40;
      } else {
        requiredConcentration = 50;
      }
    }

    double glycolGallons;
    double waterGallons;

    if (_calculationMode == 'new_fill') {
      // New system fill
      glycolGallons = _systemVolume * (requiredConcentration / 100);
      waterGallons = _systemVolume - glycolGallons;
    } else {
      // Adjusting existing system
      final currentGlycolGal = _systemVolume * (_currentConcentration / 100);
      final neededGlycolGal = _systemVolume * (requiredConcentration / 100);
      glycolGallons = neededGlycolGal - currentGlycolGal;
      if (glycolGallons < 0) {
        glycolGallons = 0;
        waterGallons = 0;
      } else {
        // Need to drain some water to add glycol
        waterGallons = -glycolGallons; // Indicates draining needed
      }
    }

    // Actual freeze point at this concentration
    double freezePoint;
    double burstPoint;
    if (_glycolType == 'propylene') {
      freezePoint = _getPropyleneFreeze(requiredConcentration);
      burstPoint = freezePoint - 20; // Burst protection lower than freeze
    } else {
      freezePoint = _getEthyleneFreeze(requiredConcentration);
      burstPoint = freezePoint - 25;
    }

    // Heat transfer penalty (glycol reduces efficiency)
    // Approximately 1% penalty per 5% glycol
    final heatTransferPenalty = requiredConcentration * 0.2;

    // Recommendation
    String recommendation;
    if (requiredConcentration == 0) {
      recommendation = 'No glycol needed for this freeze protection level. Plain water is most efficient.';
    } else if (requiredConcentration > 50) {
      recommendation = 'High glycol concentration. Consider if lower freeze protection is acceptable for better efficiency.';
    } else if (_glycolType == 'propylene') {
      recommendation = 'Propylene glycol is food-safe and less toxic. Use for potable water systems or where safety is critical.';
    } else {
      recommendation = 'Ethylene glycol is more efficient but toxic. Never use in potable systems. Mark pipes clearly.';
    }

    if (requiredConcentration >= 35) {
      recommendation += ' High concentration - verify pump can handle increased viscosity.';
    }

    setState(() {
      _glycolGallons = glycolGallons;
      _waterGallons = waterGallons;
      _finalConcentration = requiredConcentration;
      _freezePoint = freezePoint;
      _burstPoint = burstPoint;
      _heatTransferPenalty = heatTransferPenalty;
      _recommendation = recommendation;
    });
  }

  double _getPropyleneFreeze(double concentration) {
    if (concentration <= 0) return 32;
    if (concentration <= 15) return 25;
    if (concentration <= 25) return 15;
    if (concentration <= 35) return 0;
    if (concentration <= 45) return -20;
    return -40;
  }

  double _getEthyleneFreeze(double concentration) {
    if (concentration <= 0) return 32;
    if (concentration <= 12) return 25;
    if (concentration <= 20) return 15;
    if (concentration <= 30) return 0;
    if (concentration <= 40) return -20;
    return -50;
  }

  void _reset() {
    setState(() {
      _systemVolume = 50;
      _targetFreezeProtection = 0;
      _glycolType = 'propylene';
      _calculationMode = 'new_fill';
      _currentConcentration = 0;
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
        title: Text('Glycol Mix', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'System Volume', value: _systemVolume, min: 10, max: 200, unit: ' gal', onChanged: (v) { setState(() => _systemVolume = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Calculation Mode', options: const ['New Fill', 'Adjust Existing'], selectedIndex: _calculationMode == 'new_fill' ? 0 : 1, onChanged: (i) { setState(() => _calculationMode = i == 0 ? 'new_fill' : 'adjust'); _calculate(); }),
              if (_calculationMode == 'adjust') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Current Concentration', value: _currentConcentration, min: 0, max: 50, unit: '%', onChanged: (v) { setState(() => _currentConcentration = v); _calculate(); }),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PROTECTION'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Target Freeze Protection', value: _targetFreezeProtection, min: -40, max: 32, unit: '\u00B0F', onChanged: (v) { setState(() => _targetFreezeProtection = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildGlycolTypeSelector(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MIX RECIPE'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
              const SizedBox(height: 16),
              _buildProtectionTable(colors),
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
        Icon(LucideIcons.thermometerSnowflake, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Glycol protects against freezing. Propylene is food-safe, ethylene is more efficient. Never exceed 60%.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildGlycolTypeSelector(ZaftoColors colors) {
    final types = [
      ('propylene', 'Propylene Glycol', 'Food-safe, less toxic'),
      ('ethylene', 'Ethylene Glycol', 'More efficient, toxic'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Glycol Type', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        ...types.map((t) {
          final selected = _glycolType == t.$1;
          return GestureDetector(
            onTap: () { setState(() => _glycolType = t.$1); _calculate(); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Row(children: [
                Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(t.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11)),
                ])),
              ]),
            ),
          );
        }),
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
    if (_glycolGallons == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          if (_finalConcentration! > 0) ...[
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 24),
                    const SizedBox(height: 8),
                    Text('${_glycolGallons?.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text('Gal Glycol', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Icon(LucideIcons.droplets, color: colors.textSecondary, size: 24),
                    const SizedBox(height: 8),
                    Text('${_waterGallons?.abs().toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                    Text(_waterGallons! >= 0 ? 'Gal Water' : 'Gal Drain', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('${_finalConcentration?.toStringAsFixed(0)}% Concentration', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Freeze Point', '${_freezePoint?.toStringAsFixed(0)}\u00B0F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Burst Point', '${_burstPoint?.toStringAsFixed(0)}\u00B0F')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'HT Penalty', '-${_heatTransferPenalty?.toStringAsFixed(0)}%')),
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

  Widget _buildProtectionTable(ZaftoColors colors) {
    final isEthylene = _glycolType == 'ethylene';
    final data = isEthylene
        ? [('0%', '32\u00B0F'), ('20%', '15\u00B0F'), ('30%', '0\u00B0F'), ('40%', '-20\u00B0F'), ('50%', '-35\u00B0F')]
        : [('0%', '32\u00B0F'), ('25%', '15\u00B0F'), ('35%', '0\u00B0F'), ('45%', '-20\u00B0F'), ('55%', '-40\u00B0F')];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${isEthylene ? 'ETHYLENE' : 'PROPYLENE'} GLYCOL PROTECTION', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...data.map((d) {
            final isSelected = d.$1 == '${_finalConcentration?.toStringAsFixed(0)}%';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(children: [
                SizedBox(width: 60, child: Text(d.$1, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                Expanded(child: Text('Freeze: ${d.$2}', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
