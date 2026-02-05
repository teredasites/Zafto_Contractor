import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// UV Water Treatment Sizing Calculator - Design System v2.6
///
/// Sizes ultraviolet water disinfection systems.
/// Calculates UV dose requirements based on flow and water quality.
///
/// References: NSF/ANSI 55, EPA UV Guidelines
class UvTreatmentScreen extends ConsumerStatefulWidget {
  const UvTreatmentScreen({super.key});
  @override
  ConsumerState<UvTreatmentScreen> createState() => _UvTreatmentScreenState();
}

class _UvTreatmentScreenState extends ConsumerState<UvTreatmentScreen> {
  // Flow rate (GPM)
  double _flowRate = 10;

  // UV transmittance (%)
  double _uvt = 85;

  // Application type
  String _application = 'residential';

  // Target organisms
  String _target = 'bacteria';

  static const Map<String, ({String desc, double minDose})> _applications = {
    'residential': (desc: 'Residential Well', minDose: 40),
    'commercial': (desc: 'Commercial', minDose: 40),
    'food_service': (desc: 'Food Service', minDose: 40),
    'aquaculture': (desc: 'Aquaculture', minDose: 100),
  };

  static const Map<String, ({String desc, double dose})> _targets = {
    'bacteria': (desc: 'Bacteria (E. coli)', dose: 16),
    'virus': (desc: 'Viruses', dose: 40),
    'crypto': (desc: 'Cryptosporidium', dose: 12),
    'giardia': (desc: 'Giardia', dose: 11),
  };

  // Required UV dose (mJ/cm²)
  double get _requiredDose {
    final appDose = _applications[_application]?.minDose ?? 40;
    final targetDose = _targets[_target]?.dose ?? 40;
    return appDose > targetDose ? appDose : targetDose;
  }

  // UVT correction factor
  double get _uvtFactor {
    if (_uvt >= 95) return 1.0;
    if (_uvt >= 90) return 1.2;
    if (_uvt >= 85) return 1.5;
    if (_uvt >= 80) return 2.0;
    if (_uvt >= 75) return 2.5;
    return 3.0;
  }

  // Lamp wattage required
  int get _lampWattage {
    final baseWatts = _flowRate * 2; // ~2 watts per GPM baseline
    final adjusted = baseWatts * _uvtFactor;
    if (adjusted <= 15) return 15;
    if (adjusted <= 25) return 25;
    if (adjusted <= 40) return 40;
    if (adjusted <= 55) return 55;
    if (adjusted <= 80) return 80;
    return 110;
  }

  // Chamber size
  String get _chamberSize {
    if (_flowRate <= 6) return '¾\" inlet';
    if (_flowRate <= 12) return '1\" inlet';
    if (_flowRate <= 20) return '1¼\" inlet';
    if (_flowRate <= 35) return '1½\" inlet';
    return '2\" inlet';
  }

  // Annual lamp replacement
  String get _lampLife => '9,000 hours (~12 months)';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'UV Treatment Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildUvtCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildTargetCard(colors),
          const SizedBox(height: 16),
          _buildPretreatmentCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$_lampWattage W',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'UV Lamp Required',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Chamber Size', _chamberSize),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'UV Dose', '${_requiredDose.toStringAsFixed(0)} mJ/cm²'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'UVT Factor', '${_uvtFactor.toStringAsFixed(1)}x'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Lamp Life', _lampLife),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLOW RATE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peak Flow', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_flowRate.toStringAsFixed(0)} GPM',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _flowRate,
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _flowRate = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUvtCard(ZaftoColors colors) {
    final uvtStatus = _uvt >= 75 ? 'Good' : 'Pre-treat Required';
    final uvtColor = _uvt >= 75 ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UV TRANSMITTANCE (UVT)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UVT %', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Row(
                children: [
                  Text(
                    '${_uvt.toStringAsFixed(0)}%',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: uvtColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      uvtStatus,
                      style: TextStyle(color: uvtColor, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _uvt,
              min: 50,
              max: 98,
              divisions: 48,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _uvt = v);
              },
            ),
          ),
          Text(
            'Higher UVT = cleaner water = smaller system needed',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _applications.entries.map((entry) {
              final isSelected = _application == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _application = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TARGET ORGANISMS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._targets.entries.map((entry) {
            final isSelected = _target == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _target = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.dose.toStringAsFixed(0)} mJ/cm²',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPretreatmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Text(
                'Pre-Treatment Required',
                style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Iron < 0.3 ppm\n'
            '• Manganese < 0.05 ppm\n'
            '• Hardness < 7 gpg\n'
            '• Turbidity < 1 NTU\n'
            '• Tannins < 0.1 ppm',
            style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sun, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'NSF/ANSI 55',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Class A: 40 mJ/cm² (disinfection)\n'
            '• Class B: 16 mJ/cm² (supplemental)\n'
            '• Replace lamp annually\n'
            '• Clean quartz sleeve quarterly\n'
            '• Install after all other filtration\n'
            '• Include UV monitor/alarm',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
