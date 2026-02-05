import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// OCPD Sizing (AC) Calculator - AC breaker sizing
class OcpdAcScreen extends ConsumerStatefulWidget {
  const OcpdAcScreen({super.key});
  @override
  ConsumerState<OcpdAcScreen> createState() => _OcpdAcScreenState();
}

class _OcpdAcScreenState extends ConsumerState<OcpdAcScreen> {
  final _inverterKwController = TextEditingController(text: '7.6');
  final _voltageController = TextEditingController(text: '240');

  String _phases = 'Single';

  double? _outputCurrent;
  double? _continuousCurrent;
  int? _breakerSize;
  String? _notes;

  @override
  void dispose() {
    _inverterKwController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterKw = double.tryParse(_inverterKwController.text);
    final voltage = double.tryParse(_voltageController.text);

    if (inverterKw == null || voltage == null || voltage == 0) {
      setState(() {
        _outputCurrent = null;
        _continuousCurrent = null;
        _breakerSize = null;
        _notes = null;
      });
      return;
    }

    // Calculate output current
    double outputCurrent;
    if (_phases == 'Single') {
      outputCurrent = (inverterKw * 1000) / voltage;
    } else {
      outputCurrent = (inverterKw * 1000) / (voltage * 1.732);
    }

    // NEC requires 125% for continuous loads
    final continuousCurrent = outputCurrent * 1.25;

    // Standard breaker sizes
    final breakerSizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 125, 150, 175, 200];
    int breakerSize = 15;
    for (final size in breakerSizes) {
      if (size >= continuousCurrent) {
        breakerSize = size;
        break;
      }
    }

    String notes;
    if (breakerSize <= 30) {
      notes = 'Standard residential breaker. Verify panel has space.';
    } else if (breakerSize <= 60) {
      notes = 'May require dedicated sub-panel or main panel upgrade.';
    } else {
      notes = 'Large system - verify main panel rating and bus capacity.';
    }

    setState(() {
      _outputCurrent = outputCurrent;
      _continuousCurrent = continuousCurrent;
      _breakerSize = breakerSize;
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
    _inverterKwController.text = '7.6';
    _voltageController.text = '240';
    setState(() => _phases = 'Single');
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
        title: Text('AC Breaker Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INVERTER OUTPUT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'AC Output',
                      unit: 'kW',
                      hint: 'Inverter rating',
                      controller: _inverterKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voltage',
                      unit: 'V',
                      hint: '240/208/480',
                      controller: _voltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPhaseSelector(colors),
              const SizedBox(height: 32),
              if (_breakerSize != null) ...[
                _buildSectionHeader(colors, 'BREAKER SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildInterconnectionNote(colors),
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
            'Breaker ≥ Inverter Output × 1.25',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size AC circuit breaker for inverter output circuit',
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

  Widget _buildPhaseSelector(ZaftoColors colors) {
    final phases = ['Single', 'Three-Phase'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: phases.map((phase) {
          final isSelected = _phases == phase;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _phases = phase);
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
                    phase,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Minimum Breaker Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_breakerSize}A',
            style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Text(
            _phases == 'Single' ? '240V 2-pole' : '${_voltageController.text}V 3-pole',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Output', '${_outputCurrent!.toStringAsFixed(1)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, '× 1.25', '${_continuousCurrent!.toStringAsFixed(1)} A', colors.accentInfo),
              ),
            ],
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

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInterconnectionNote(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
              const SizedBox(width: 8),
              Text(
                '120% RULE CHECK REQUIRED',
                style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Per NEC 705.12(B)(2), the solar breaker + main breaker cannot exceed 120% of bus rating.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Example: 200A panel × 120% = 240A max. If main is 200A, solar breaker ≤ 40A for load-side connection.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
