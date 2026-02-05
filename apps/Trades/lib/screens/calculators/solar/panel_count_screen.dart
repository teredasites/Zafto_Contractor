import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Panel Count Calculator - Modules needed for target system size
class PanelCountScreen extends ConsumerStatefulWidget {
  const PanelCountScreen({super.key});
  @override
  ConsumerState<PanelCountScreen> createState() => _PanelCountScreenState();
}

class _PanelCountScreenState extends ConsumerState<PanelCountScreen> {
  final _systemSizeController = TextEditingController();
  final _panelWattageController = TextEditingController(text: '400');

  int? _panelCount;
  double? _actualSystemSize;
  double? _totalArea;

  // Standard panel dimensions (residential)
  static const double _panelWidthFt = 3.5;
  static const double _panelHeightFt = 6.5;

  @override
  void dispose() {
    _systemSizeController.dispose();
    _panelWattageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemKw = double.tryParse(_systemSizeController.text);
    final panelWatts = double.tryParse(_panelWattageController.text);

    if (systemKw == null || panelWatts == null || panelWatts <= 0) {
      setState(() {
        _panelCount = null;
        _actualSystemSize = null;
        _totalArea = null;
      });
      return;
    }

    final systemWatts = systemKw * 1000;
    final count = (systemWatts / panelWatts).ceil();
    final actualSize = (count * panelWatts) / 1000;
    final area = count * _panelWidthFt * _panelHeightFt;

    setState(() {
      _panelCount = count;
      _actualSystemSize = actualSize;
      _totalArea = area;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemSizeController.clear();
    _panelWattageController.text = '400';
    setState(() {
      _panelCount = null;
      _actualSystemSize = null;
      _totalArea = null;
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
        title: Text('Panel Count', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                label: 'Target System Size',
                unit: 'kW',
                hint: 'Desired DC capacity',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Panel Wattage',
                unit: 'W',
                hint: 'Per module rating',
                controller: _panelWattageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildCommonPanels(colors),
              const SizedBox(height: 32),
              if (_panelCount != null) ...[
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
            'Panels = System kW × 1000 / Panel Watts',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Round up to nearest whole panel',
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

  Widget _buildCommonPanels(ZaftoColors colors) {
    final commonWattages = [350, 370, 400, 410, 430, 450];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common Panel Sizes', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commonWattages.map((w) => GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _panelWattageController.text = w.toString();
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _panelWattageController.text == w.toString()
                    ? colors.accentPrimary
                    : colors.fillDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${w}W',
                  style: TextStyle(
                    color: _panelWattageController.text == w.toString()
                      ? (colors.isDark ? Colors.black : Colors.white)
                      : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
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
          _buildResultRow(colors, 'Panels Required', '$_panelCount modules', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Actual System Size', '${_actualSystemSize!.toStringAsFixed(2)} kW'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Estimated Roof Area', '${_totalArea!.toStringAsFixed(0)} sq ft'),
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
