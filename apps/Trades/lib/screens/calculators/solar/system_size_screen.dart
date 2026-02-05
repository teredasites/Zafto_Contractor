import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Solar System Size Calculator - kW from annual usage
class SystemSizeScreen extends ConsumerStatefulWidget {
  const SystemSizeScreen({super.key});
  @override
  ConsumerState<SystemSizeScreen> createState() => _SystemSizeScreenState();
}

class _SystemSizeScreenState extends ConsumerState<SystemSizeScreen> {
  final _annualUsageController = TextEditingController();
  final _sunHoursController = TextEditingController(text: '4.5');
  final _systemLossController = TextEditingController(text: '14');

  double? _systemSizeKw;
  double? _systemSizeDc;
  double? _dailyProduction;

  @override
  void dispose() {
    _annualUsageController.dispose();
    _sunHoursController.dispose();
    _systemLossController.dispose();
    super.dispose();
  }

  void _calculate() {
    final annualKwh = double.tryParse(_annualUsageController.text);
    final sunHours = double.tryParse(_sunHoursController.text);
    final lossPercent = double.tryParse(_systemLossController.text);

    if (annualKwh == null || sunHours == null || lossPercent == null || sunHours <= 0) {
      setState(() {
        _systemSizeKw = null;
        _systemSizeDc = null;
        _dailyProduction = null;
      });
      return;
    }

    // Daily kWh needed
    final dailyKwh = annualKwh / 365;

    // Account for system losses
    final lossFactor = 1 - (lossPercent / 100);

    // System size = Daily kWh / (Sun Hours × Loss Factor)
    final systemKw = dailyKwh / (sunHours * lossFactor);

    // DC size is typically 1.1-1.2x AC for clipping
    final dcSize = systemKw * 1.15;

    setState(() {
      _systemSizeKw = systemKw;
      _systemSizeDc = dcSize;
      _dailyProduction = dailyKwh;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _annualUsageController.clear();
    _sunHoursController.text = '4.5';
    _systemLossController.text = '14';
    setState(() {
      _systemSizeKw = null;
      _systemSizeDc = null;
      _dailyProduction = null;
    });
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
        title: Text('System Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INPUTS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Annual Usage',
                unit: 'kWh',
                hint: 'From utility bill',
                controller: _annualUsageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Peak Sun Hours',
                unit: 'hrs/day',
                hint: 'Average for location',
                controller: _sunHoursController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'System Losses',
                unit: '%',
                hint: 'Typical 10-20%',
                controller: _systemLossController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_systemSizeKw != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
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
            'Size = Annual kWh / (365 × Sun Hours × Efficiency)',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculates minimum system size to offset usage',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
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
          _buildResultRow(colors, 'System Size (AC)', '${_systemSizeKw!.toStringAsFixed(2)} kW', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Recommended DC', '${_systemSizeDc!.toStringAsFixed(2)} kWp'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Daily Production Target', '${_dailyProduction!.toStringAsFixed(1)} kWh'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DC/AC ratio of 1.15 recommended for optimal clipping',
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? colors.accentPrimary : colors.textPrimary,
            fontSize: isPrimary ? 20 : 16,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
