import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Dehumidifier Sizing Calculator - Design System v2.6
/// Pints per day capacity for whole-house dehumidification
class DehumidifierSizingScreen extends ConsumerStatefulWidget {
  const DehumidifierSizingScreen({super.key});
  @override
  ConsumerState<DehumidifierSizingScreen> createState() => _DehumidifierSizingScreenState();
}

class _DehumidifierSizingScreenState extends ConsumerState<DehumidifierSizingScreen> {
  double _squareFeet = 2000;
  double _ceilingHeight = 8;
  String _currentRh = 'high';
  String _moistureSources = 'moderate';
  String _application = 'wholehouse';
  double _targetRh = 50;

  double? _pintsPerDay;
  String? _unitSize;
  double? _cfmRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Volume calculation
    final volume = _squareFeet * _ceilingHeight;

    // Base moisture removal (pints per day per 1000 sq ft)
    double baseRate;
    switch (_currentRh) {
      case 'moderate': baseRate = 10; break; // 50-60% RH
      case 'high': baseRate = 14; break; // 60-70% RH
      case 'veryhigh': baseRate = 18; break; // 70-80% RH
      case 'wet': baseRate = 22; break; // >80% RH
      default: baseRate = 14;
    }

    // Moisture source factor
    double sourceFactor;
    switch (_moistureSources) {
      case 'low': sourceFactor = 0.8; break;
      case 'moderate': sourceFactor = 1.0; break;
      case 'high': sourceFactor = 1.3; break;
      case 'veryhigh': sourceFactor = 1.6; break;
      default: sourceFactor = 1.0;
    }

    // Calculate base capacity
    var pintsPerDay = (_squareFeet / 1000) * baseRate * sourceFactor;

    // Adjust for ceiling height (higher = more volume)
    pintsPerDay *= (_ceilingHeight / 8);

    // Application factor
    if (_application == 'basement') {
      pintsPerDay *= 1.3; // Basements typically need more
    } else if (_application == 'crawlspace') {
      pintsPerDay *= 1.5; // Crawlspaces very humid
    }

    // CFM requirement (for ducted systems)
    // Approximately 1.5 CFM per sq ft for dehumidification
    final cfmRequired = _squareFeet * 0.1; // Simplified

    // Size recommendation
    String unitSize;
    if (pintsPerDay <= 30) {
      unitSize = '30 PPD Portable';
    } else if (pintsPerDay <= 50) {
      unitSize = '50 PPD Portable';
    } else if (pintsPerDay <= 70) {
      unitSize = '70 PPD Whole-House';
    } else if (pintsPerDay <= 90) {
      unitSize = '90 PPD Whole-House';
    } else if (pintsPerDay <= 130) {
      unitSize = '130 PPD Commercial';
    } else {
      unitSize = '200+ PPD Commercial';
    }

    String recommendation;
    if (_application == 'wholehouse') {
      recommendation = 'Whole-house: Install on return air duct or dedicated duct system. Target 45-55% RH.';
    } else if (_application == 'basement') {
      recommendation = 'Basement: Standalone unit with condensate pump or drain. Check for water intrusion sources.';
    } else {
      recommendation = 'Crawlspace: Sealed crawl with dehumidifier. Ensure vapor barrier installed. Target <60% RH.';
    }

    if (_targetRh < 45) {
      recommendation += ' Very low target RH may require oversized unit or longer runtime.';
    }

    if (_moistureSources == 'veryhigh') {
      recommendation += ' Address moisture sources (leaks, poor drainage) for best results.';
    }

    setState(() {
      _pintsPerDay = pintsPerDay;
      _unitSize = unitSize;
      _cfmRequired = cfmRequired;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _squareFeet = 2000;
      _ceilingHeight = 8;
      _currentRh = 'high';
      _moistureSources = 'moderate';
      _application = 'wholehouse';
      _targetRh = 50;
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
        title: Text('Dehumidifier Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SPACE'),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Area', value: _squareFeet, min: 200, max: 5000, unit: ' sq ft', onChanged: (v) { setState(() => _squareFeet = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Ceiling Height', value: _ceilingHeight, min: 7, max: 12, unit: ' ft', decimals: 1, onChanged: (v) { setState(() => _ceilingHeight = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HUMIDITY CONDITIONS'),
              const SizedBox(height: 12),
              _buildHumiditySelector(colors),
              const SizedBox(height: 12),
              _buildMoistureSourceSelector(colors),
              const SizedBox(height: 12),
              _buildSliderRow(colors, label: 'Target RH', value: _targetRh, min: 40, max: 60, unit: '%', onChanged: (v) { setState(() => _targetRh = v); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DEHUMIDIFIER SIZE'),
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
        Icon(LucideIcons.droplets, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Size dehumidifier by pints/day (PPD) capacity. Target 45-55% RH for comfort and mold prevention.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = [
      ('wholehouse', 'Whole House'),
      ('basement', 'Basement'),
      ('crawlspace', 'Crawlspace'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Application', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: apps.map((a) {
            final selected = _application == a.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _application = a.$1); _calculate(); },
                child: Container(
                  margin: EdgeInsets.only(right: a != apps.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? colors.accentPrimary : colors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
                  ),
                  child: Center(child: Text(a.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHumiditySelector(ZaftoColors colors) {
    final levels = [
      ('moderate', '50-60%', 'Slightly damp'),
      ('high', '60-70%', 'Damp, musty'),
      ('veryhigh', '70-80%', 'Wet spots'),
      ('wet', '>80%', 'Standing water'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Humidity Level', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((l) {
            final selected = _currentRh == l.$1;
            return GestureDetector(
              onTap: () { setState(() => _currentRh = l.$1); _calculate(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildMoistureSourceSelector(ZaftoColors colors) {
    final sources = [
      ('low', 'Low', 'Tight home, few sources'),
      ('moderate', 'Moderate', 'Typical home'),
      ('high', 'High', 'Many plants, cooking'),
      ('veryhigh', 'Very High', 'Leaks, poor drainage'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Moisture Sources', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        ...sources.map((s) {
          final selected = _moistureSources == s.$1;
          return GestureDetector(
            onTap: () { setState(() => _moistureSources = s.$1); _calculate(); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Row(children: [
                Icon(selected ? LucideIcons.checkCircle : LucideIcons.circle, color: selected ? Colors.white : colors.textSecondary, size: 16),
                const SizedBox(width: 10),
                Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(child: Text(s.$3, style: TextStyle(color: selected ? Colors.white70 : colors.textSecondary, fontSize: 11))),
              ]),
            ),
          );
        }),
      ],
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
            child: Text('${value.toStringAsFixed(decimals)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
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
    if (_pintsPerDay == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_pintsPerDay?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('Pints Per Day (PPD)', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text(_unitSize ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Volume', '${(_squareFeet * _ceilingHeight).toStringAsFixed(0)} cu ft')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Target RH', '${_targetRh.toStringAsFixed(0)}%')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'CFM Need', '${_cfmRequired?.toStringAsFixed(0)}')),
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
