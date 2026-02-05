import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Depth of Discharge Calculator - DoD optimization
class DepthOfDischargeScreen extends ConsumerStatefulWidget {
  const DepthOfDischargeScreen({super.key});
  @override
  ConsumerState<DepthOfDischargeScreen> createState() => _DepthOfDischargeScreenState();
}

class _DepthOfDischargeScreenState extends ConsumerState<DepthOfDischargeScreen> {
  final _batteryKwhController = TextEditingController(text: '13.5');
  final _dodController = TextEditingController(text: '80');

  String _batteryType = 'Lithium-Ion';

  double? _usableCapacity;
  double? _reserveCapacity;
  int? _expectedCycles;
  String? _recommendation;

  // Estimated cycle life based on DoD
  final Map<String, Map<int, int>> _cycleLife = {
    'Lithium-Ion': {100: 500, 90: 1000, 80: 2000, 70: 3000, 60: 4000, 50: 5000},
    'LFP': {100: 2000, 90: 3000, 80: 4000, 70: 5000, 60: 6000, 50: 7000},
    'Lead-Acid': {100: 200, 80: 400, 60: 600, 50: 800, 40: 1000, 30: 1200},
  };

  @override
  void dispose() {
    _batteryKwhController.dispose();
    _dodController.dispose();
    super.dispose();
  }

  void _calculate() {
    final batteryKwh = double.tryParse(_batteryKwhController.text);
    final dod = double.tryParse(_dodController.text);

    if (batteryKwh == null || dod == null) {
      setState(() {
        _usableCapacity = null;
        _reserveCapacity = null;
        _expectedCycles = null;
        _recommendation = null;
      });
      return;
    }

    final usableCapacity = batteryKwh * (dod / 100);
    final reserveCapacity = batteryKwh - usableCapacity;

    // Find closest cycle life estimate
    final cycleMap = _cycleLife[_batteryType]!;
    int expectedCycles = 0;
    int closestDod = 100;
    for (final d in cycleMap.keys) {
      if ((d - dod).abs() < (closestDod - dod).abs()) {
        closestDod = d;
      }
    }
    expectedCycles = cycleMap[closestDod] ?? 1000;

    String recommendation;
    if (_batteryType == 'Lead-Acid') {
      if (dod > 50) {
        recommendation = 'Lead-acid batteries should stay below 50% DoD for longevity.';
      } else {
        recommendation = 'Good DoD setting for lead-acid battery life.';
      }
    } else {
      if (dod >= 90) {
        recommendation = 'High DoD maximizes usable capacity but reduces cycle life.';
      } else if (dod >= 70) {
        recommendation = 'Balanced DoD - good compromise of capacity and longevity.';
      } else {
        recommendation = 'Conservative DoD extends battery life significantly.';
      }
    }

    setState(() {
      _usableCapacity = usableCapacity;
      _reserveCapacity = reserveCapacity;
      _expectedCycles = expectedCycles;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryKwhController.text = '13.5';
    _dodController.text = '80';
    setState(() => _batteryType = 'Lithium-Ion');
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
        title: Text('Depth of Discharge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BATTERY TYPE'),
              const SizedBox(height: 12),
              _buildBatteryTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SETTINGS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Capacity',
                      unit: 'kWh',
                      hint: 'Total',
                      controller: _batteryKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Depth of Discharge',
                      unit: '%',
                      hint: '0-100',
                      controller: _dodController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_usableCapacity != null) ...[
                _buildSectionHeader(colors, 'DOD ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildDodGuide(colors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.batteryMedium, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'DoD Optimization',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Balance usable capacity vs battery longevity',
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

  Widget _buildBatteryTypeSelector(ZaftoColors colors) {
    final types = ['Lithium-Ion', 'LFP', 'Lead-Acid'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _batteryType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _batteryType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCapacityTile(colors, 'Usable', '${_usableCapacity!.toStringAsFixed(2)} kWh', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCapacityTile(colors, 'Reserve', '${_reserveCapacity!.toStringAsFixed(2)} kWh', colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.repeat, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Text(
                  'Est. Cycle Life: ~$_expectedCycles cycles',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    _recommendation!,
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

  Widget _buildCapacityTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDodGuide(ZaftoColors colors) {
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
          Text('DOD RECOMMENDATIONS BY CHEMISTRY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildChemRow(colors, 'Lithium-Ion (NMC)', '80-90%', 'Powerwall, LG'),
          _buildChemRow(colors, 'LFP (LiFePO4)', '90-100%', 'Enphase, SimpliPhi'),
          _buildChemRow(colors, 'Lead-Acid', '30-50%', 'Off-grid systems'),
        ],
      ),
    );
  }

  Widget _buildChemRow(ZaftoColors colors, String chemistry, String dod, String examples) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(chemistry, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(dod, style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(examples, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
