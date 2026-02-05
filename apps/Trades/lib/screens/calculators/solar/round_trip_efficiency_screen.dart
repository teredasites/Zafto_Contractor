import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Round-Trip Efficiency Calculator - AC-AC losses
class RoundTripEfficiencyScreen extends ConsumerStatefulWidget {
  const RoundTripEfficiencyScreen({super.key});
  @override
  ConsumerState<RoundTripEfficiencyScreen> createState() => _RoundTripEfficiencyScreenState();
}

class _RoundTripEfficiencyScreenState extends ConsumerState<RoundTripEfficiencyScreen> {
  final _energyInController = TextEditingController(text: '10');
  final _energyOutController = TextEditingController(text: '9');

  String _batterySystem = 'AC-Coupled';

  double? _rtEfficiency;
  double? _energyLoss;
  String? _rating;
  String? _notes;

  @override
  void dispose() {
    _energyInController.dispose();
    _energyOutController.dispose();
    super.dispose();
  }

  void _calculate() {
    final energyIn = double.tryParse(_energyInController.text);
    final energyOut = double.tryParse(_energyOutController.text);

    if (energyIn == null || energyOut == null || energyIn == 0) {
      setState(() {
        _rtEfficiency = null;
        _energyLoss = null;
        _rating = null;
        _notes = null;
      });
      return;
    }

    final rtEfficiency = (energyOut / energyIn) * 100;
    final energyLoss = energyIn - energyOut;

    String rating;
    String notes;

    if (rtEfficiency >= 95) {
      rating = 'Excellent';
      notes = 'Top-tier efficiency, typical of DC-coupled LFP systems.';
    } else if (rtEfficiency >= 90) {
      rating = 'Very Good';
      notes = 'Standard for modern lithium systems.';
    } else if (rtEfficiency >= 85) {
      rating = 'Good';
      notes = 'Acceptable for AC-coupled systems.';
    } else if (rtEfficiency >= 80) {
      rating = 'Fair';
      notes = 'Higher losses - check inverter efficiency.';
    } else {
      rating = 'Poor';
      notes = 'Significant losses - review system configuration.';
    }

    // Adjust notes for system type
    if (_batterySystem == 'AC-Coupled') {
      notes += ' AC-coupled systems have 2 conversion steps.';
    } else {
      notes += ' DC-coupled minimizes conversion losses.';
    }

    setState(() {
      _rtEfficiency = rtEfficiency;
      _energyLoss = energyLoss;
      _rating = rating;
      _notes = notes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _energyInController.text = '10';
    _energyOutController.text = '9';
    setState(() => _batterySystem = 'AC-Coupled');
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
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Round-Trip Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM TYPE'),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ENERGY MEASUREMENT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Energy In',
                      unit: 'kWh',
                      hint: 'Charging',
                      controller: _energyInController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Energy Out',
                      unit: 'kWh',
                      hint: 'Discharging',
                      controller: _energyOutController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_rtEfficiency != null) ...[
                _buildSectionHeader(colors, 'EFFICIENCY'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildEfficiencyGuide(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'RTE = Energy Out ÷ Energy In × 100',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Measure AC-to-AC storage efficiency',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = ['AC-Coupled', 'DC-Coupled'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _batterySystem == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _batterySystem = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _rtEfficiency! >= 85;
    final statusColor = _rtEfficiency! >= 90 ? colors.accentSuccess :
                        _rtEfficiency! >= 85 ? colors.accentInfo : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Round-Trip Efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_rtEfficiency!.toStringAsFixed(1)}%',
            style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _rating!,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Energy Loss', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Text('${_energyLoss!.toStringAsFixed(2)} kWh (${(100 - _rtEfficiency!).toStringAsFixed(1)}%)',
                    style: TextStyle(color: colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notes!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TYPICAL EFFICIENCY RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildRangeRow(colors, 'DC-Coupled LFP', '94-97%', colors.accentSuccess),
          _buildRangeRow(colors, 'DC-Coupled Li-ion', '92-95%', colors.accentSuccess),
          _buildRangeRow(colors, 'AC-Coupled Li-ion', '85-92%', colors.accentInfo),
          _buildRangeRow(colors, 'Lead-Acid', '75-85%', colors.accentWarning),
        ],
      ),
    );
  }

  Widget _buildRangeRow(ZaftoColors colors, String system, String range, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(system, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
          Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
