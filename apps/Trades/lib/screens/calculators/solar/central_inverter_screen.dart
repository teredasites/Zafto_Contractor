import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Central Inverter Sizing Calculator - kW AC output sizing
class CentralInverterScreen extends ConsumerStatefulWidget {
  const CentralInverterScreen({super.key});
  @override
  ConsumerState<CentralInverterScreen> createState() => _CentralInverterScreenState();
}

class _CentralInverterScreenState extends ConsumerState<CentralInverterScreen> {
  final _arrayDcKwController = TextEditingController(text: '10.0');
  final _dcAcRatioController = TextEditingController(text: '1.2');
  final _inverterEfficiencyController = TextEditingController(text: '97.5');

  double? _inverterKw;
  double? _clippingLoss;
  double? _expectedAcOutput;
  String? _recommendation;

  @override
  void dispose() {
    _arrayDcKwController.dispose();
    _dcAcRatioController.dispose();
    _inverterEfficiencyController.dispose();
    super.dispose();
  }

  void _calculate() {
    final arrayDcKw = double.tryParse(_arrayDcKwController.text);
    final dcAcRatio = double.tryParse(_dcAcRatioController.text);
    final efficiency = double.tryParse(_inverterEfficiencyController.text);

    if (arrayDcKw == null || dcAcRatio == null || efficiency == null) {
      setState(() {
        _inverterKw = null;
        _clippingLoss = null;
        _expectedAcOutput = null;
        _recommendation = null;
      });
      return;
    }

    // Inverter AC rating = DC array / DC:AC ratio
    final inverterKw = arrayDcKw / dcAcRatio;

    // Estimated clipping loss (simplified)
    double clippingLoss;
    if (dcAcRatio <= 1.0) {
      clippingLoss = 0;
    } else if (dcAcRatio <= 1.15) {
      clippingLoss = 0.5;
    } else if (dcAcRatio <= 1.25) {
      clippingLoss = 1.5;
    } else if (dcAcRatio <= 1.35) {
      clippingLoss = 3.0;
    } else {
      clippingLoss = 5.0;
    }

    // Expected AC output
    final expectedAcOutput = arrayDcKw * (efficiency / 100) * (1 - clippingLoss / 100);

    String recommendation;
    if (dcAcRatio < 1.1) {
      recommendation = 'Undersized array - inverter underutilized';
    } else if (dcAcRatio <= 1.2) {
      recommendation = 'Optimal range for most climates';
    } else if (dcAcRatio <= 1.3) {
      recommendation = 'Good for high-latitude or cloudy areas';
    } else {
      recommendation = 'High ratio - increased clipping, verify economics';
    }

    setState(() {
      _inverterKw = inverterKw;
      _clippingLoss = clippingLoss;
      _expectedAcOutput = expectedAcOutput;
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
    _arrayDcKwController.text = '10.0';
    _dcAcRatioController.text = '1.2';
    _inverterEfficiencyController.text = '97.5';
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
        title: Text('Central Inverter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ARRAY SIZE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Array DC Capacity',
                unit: 'kW',
                hint: 'Total module watts',
                controller: _arrayDcKwController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INVERTER PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'DC:AC Ratio',
                      unit: '',
                      hint: '1.1 - 1.3 typical',
                      controller: _dcAcRatioController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Efficiency',
                      unit: '%',
                      hint: 'CEC weighted',
                      controller: _inverterEfficiencyController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_inverterKw != null) ...[
                _buildSectionHeader(colors, 'INVERTER SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
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
            'Inverter kW = Array kW ÷ DC:AC Ratio',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size string or central inverter based on array capacity',
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
          Text('Inverter AC Rating Needed', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_inverterKw!.toStringAsFixed(2)} kW',
            style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Clipping Loss', '~${_clippingLoss!.toStringAsFixed(1)}%', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'AC Output', '${_expectedAcOutput!.toStringAsFixed(2)} kW', colors.accentSuccess),
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
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
}
