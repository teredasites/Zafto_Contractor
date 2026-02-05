import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Inverter Efficiency Calculator - CEC weighted efficiency impact
class InverterEfficiencyScreen extends ConsumerStatefulWidget {
  const InverterEfficiencyScreen({super.key});
  @override
  ConsumerState<InverterEfficiencyScreen> createState() => _InverterEfficiencyScreenState();
}

class _InverterEfficiencyScreenState extends ConsumerState<InverterEfficiencyScreen> {
  final _dcInputController = TextEditingController(text: '10.0');
  final _cecEfficiencyController = TextEditingController(text: '97.5');
  final _annualProductionController = TextEditingController(text: '15000');

  double? _acOutput;
  double? _conversionLoss;
  double? _annualLoss;
  String? _efficiencyRating;

  @override
  void dispose() {
    _dcInputController.dispose();
    _cecEfficiencyController.dispose();
    _annualProductionController.dispose();
    super.dispose();
  }

  void _calculate() {
    final dcInput = double.tryParse(_dcInputController.text);
    final cecEfficiency = double.tryParse(_cecEfficiencyController.text);
    final annualProduction = double.tryParse(_annualProductionController.text);

    if (dcInput == null || cecEfficiency == null || annualProduction == null) {
      setState(() {
        _acOutput = null;
        _conversionLoss = null;
        _annualLoss = null;
        _efficiencyRating = null;
      });
      return;
    }

    final acOutput = dcInput * (cecEfficiency / 100);
    final conversionLoss = dcInput - acOutput;
    final annualLoss = annualProduction * (1 - cecEfficiency / 100);

    String efficiencyRating;
    if (cecEfficiency >= 98) {
      efficiencyRating = 'Excellent - Premium inverter';
    } else if (cecEfficiency >= 97) {
      efficiencyRating = 'Very Good - High-quality inverter';
    } else if (cecEfficiency >= 96) {
      efficiencyRating = 'Good - Standard quality';
    } else if (cecEfficiency >= 95) {
      efficiencyRating = 'Fair - Budget option';
    } else {
      efficiencyRating = 'Low - Consider upgrading';
    }

    setState(() {
      _acOutput = acOutput;
      _conversionLoss = conversionLoss;
      _annualLoss = annualLoss;
      _efficiencyRating = efficiencyRating;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dcInputController.text = '10.0';
    _cecEfficiencyController.text = '97.5';
    _annualProductionController.text = '15000';
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
        title: Text('Inverter Efficiency', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INVERTER DATA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'DC Input',
                      unit: 'kW',
                      hint: 'Array power',
                      controller: _dcInputController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'CEC Efficiency',
                      unit: '%',
                      hint: 'Weighted avg',
                      controller: _cecEfficiencyController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Est. Annual DC Production',
                unit: 'kWh',
                hint: 'Before inverter',
                controller: _annualProductionController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_acOutput != null) ...[
                _buildSectionHeader(colors, 'EFFICIENCY IMPACT'),
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
            'AC Output = DC Input × Efficiency',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'CEC weighted efficiency accounts for real-world operating conditions',
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
    final efficiency = double.parse(_cecEfficiencyController.text);
    final isGood = efficiency >= 97;

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
                child: _buildStatTile(colors, 'AC Output', '${_acOutput!.toStringAsFixed(2)} kW', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Loss (Heat)', '${(_conversionLoss! * 1000).toStringAsFixed(0)} W', colors.accentWarning),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Annual Inverter Loss', '${_annualLoss!.toStringAsFixed(0)} kWh'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Net Annual AC', '${(double.parse(_annualProductionController.text) - _annualLoss!).toStringAsFixed(0)} kWh'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGood ? colors.accentSuccess : colors.accentInfo).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isGood ? LucideIcons.award : LucideIcons.info,
                  size: 18,
                  color: isGood ? colors.accentSuccess : colors.accentInfo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _efficiencyRating!,
                    style: TextStyle(
                      color: isGood ? colors.accentSuccess : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
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
          Text('EFFICIENCY TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildEffRow(colors, 'Peak Efficiency', 'Max at optimal load (~30-50%)'),
          _buildEffRow(colors, 'CEC Weighted', 'Real-world weighted average'),
          _buildEffRow(colors, 'Euro Efficiency', 'European weighting standard'),
          _buildEffRow(colors, 'MPPT Efficiency', 'Tracking algorithm accuracy'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CEC efficiency is the most relevant metric for US installations. A 1% efficiency difference = ~150 kWh/year for a 10 kW system.',
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

  Widget _buildEffRow(ZaftoColors colors, String type, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
