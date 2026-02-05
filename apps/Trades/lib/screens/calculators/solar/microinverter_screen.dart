import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Microinverter Selection Calculator - Per-module inverter sizing
class MicroinverterScreen extends ConsumerStatefulWidget {
  const MicroinverterScreen({super.key});
  @override
  ConsumerState<MicroinverterScreen> createState() => _MicroinverterScreenState();
}

class _MicroinverterScreenState extends ConsumerState<MicroinverterScreen> {
  final _moduleWattsController = TextEditingController(text: '400');
  final _moduleCountController = TextEditingController(text: '25');
  final _moduleVmpController = TextEditingController(text: '41.7');
  final _moduleImpController = TextEditingController(text: '10.9');

  double? _minMicroWatts;
  double? _recommendedMicroWatts;
  double? _totalSystemAc;
  String? _recommendation;

  @override
  void dispose() {
    _moduleWattsController.dispose();
    _moduleCountController.dispose();
    _moduleVmpController.dispose();
    _moduleImpController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleWatts = double.tryParse(_moduleWattsController.text);
    final moduleCount = int.tryParse(_moduleCountController.text);
    final moduleVmp = double.tryParse(_moduleVmpController.text);
    final moduleImp = double.tryParse(_moduleImpController.text);

    if (moduleWatts == null || moduleCount == null || moduleVmp == null || moduleImp == null) {
      setState(() {
        _minMicroWatts = null;
        _recommendedMicroWatts = null;
        _totalSystemAc = null;
        _recommendation = null;
      });
      return;
    }

    // Microinverter should be slightly undersized vs module (DC:AC ratio ~1.1-1.2)
    final minMicroWatts = moduleWatts / 1.25; // Max DC:AC ratio
    final recommendedMicroWatts = moduleWatts / 1.15; // Optimal DC:AC ratio

    // Total system AC output (approximate)
    final totalSystemAc = (recommendedMicroWatts * moduleCount) / 1000;

    String recommendation;
    if (moduleWatts <= 300) {
      recommendation = 'IQ7 series or equivalent (290-310W AC)';
    } else if (moduleWatts <= 370) {
      recommendation = 'IQ7+ series or equivalent (290-366W AC)';
    } else if (moduleWatts <= 440) {
      recommendation = 'IQ7A/IQ8A series or equivalent (349-400W AC)';
    } else if (moduleWatts <= 500) {
      recommendation = 'IQ8+ or IQ8M series (300-480W AC)';
    } else {
      recommendation = 'IQ8H or dual-module micros for high-watt panels';
    }

    setState(() {
      _minMicroWatts = minMicroWatts;
      _recommendedMicroWatts = recommendedMicroWatts;
      _totalSystemAc = totalSystemAc;
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
    _moduleWattsController.text = '400';
    _moduleCountController.text = '25';
    _moduleVmpController.text = '41.7';
    _moduleImpController.text = '10.9';
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
        title: Text('Microinverter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Watts',
                      unit: 'W',
                      hint: 'Pmax STC',
                      controller: _moduleWattsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Count',
                      unit: '',
                      hint: 'Total panels',
                      controller: _moduleCountController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Vmp',
                      unit: 'V',
                      hint: 'For MPPT check',
                      controller: _moduleVmpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Imp',
                      unit: 'A',
                      hint: 'For input check',
                      controller: _moduleImpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_minMicroWatts != null) ...[
                _buildSectionHeader(colors, 'MICROINVERTER SELECTION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildMicroinverterGuide(colors),
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
              Icon(LucideIcons.cpu, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Module-Level Power Electronics',
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
            'One microinverter per module for independent MPPT',
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
          Text('Recommended Microinverter Rating', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_recommendedMicroWatts!.toStringAsFixed(0)}+ W',
            style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Min Rating', '${_minMicroWatts!.toStringAsFixed(0)} W', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'System AC', '${_totalSystemAc!.toStringAsFixed(2)} kW', colors.accentSuccess),
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
                Icon(LucideIcons.lightbulb, size: 18, color: colors.accentInfo),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMicroinverterGuide(ZaftoColors colors) {
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
          Text('COMPATIBILITY CHECKLIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCheckItem(colors, 'Module Vmp within MPPT range'),
          _buildCheckItem(colors, 'Module Voc below max input voltage'),
          _buildCheckItem(colors, 'Module Isc below max input current'),
          _buildCheckItem(colors, 'Module Pmax compatible with DC:AC ratio'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 14, color: colors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Microinverters provide shade tolerance, per-panel monitoring, and simplified rapid shutdown compliance.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.checkSquare, size: 14, color: colors.accentPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
