import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cool Roof Calculator - Calculate energy savings from reflective roofing
class CoolRoofScreen extends ConsumerStatefulWidget {
  const CoolRoofScreen({super.key});
  @override
  ConsumerState<CoolRoofScreen> createState() => _CoolRoofScreenState();
}

class _CoolRoofScreenState extends ConsumerState<CoolRoofScreen> {
  final _roofAreaController = TextEditingController(text: '2000');
  final _currentSRIController = TextEditingController(text: '25');
  final _newSRIController = TextEditingController(text: '78');
  final _electricRateController = TextEditingController(text: '0.12');

  String _climateZone = 'Hot-Humid';

  double? _tempReduction;
  double? _coolingSavings;
  double? _annualSavings;
  double? _paybackYears;
  bool? _meetsCode;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _currentSRIController.dispose();
    _newSRIController.dispose();
    _electricRateController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final currentSRI = double.tryParse(_currentSRIController.text);
    final newSRI = double.tryParse(_newSRIController.text);
    final electricRate = double.tryParse(_electricRateController.text);

    if (roofArea == null || currentSRI == null || newSRI == null || electricRate == null) {
      setState(() {
        _tempReduction = null;
        _coolingSavings = null;
        _annualSavings = null;
        _paybackYears = null;
        _meetsCode = null;
      });
      return;
    }

    // SRI improvement effect on roof surface temp
    // Each 10 points of SRI ≈ 5°F cooler surface
    final sriImprovement = newSRI - currentSRI;
    final tempReduction = sriImprovement * 0.5;

    // Cooling load reduction estimate
    // Hot climates: ~10-15% reduction in cooling energy
    // Based on: 0.5 kWh/sq ft/year cooling reduction per 10 SRI points
    double coolingFactor;
    switch (_climateZone) {
      case 'Hot-Humid':
        coolingFactor = 0.06;
        break;
      case 'Hot-Dry':
        coolingFactor = 0.08;
        break;
      case 'Mixed':
        coolingFactor = 0.04;
        break;
      default:
        coolingFactor = 0.05;
    }

    final coolingSavings = roofArea * (sriImprovement / 100) * coolingFactor * 1000; // kWh/year
    final annualSavings = coolingSavings * electricRate;

    // Payback estimate (cool roof premium ~$0.50-1.00/sq ft)
    const roofPremium = 0.75;
    final paybackYears = (roofArea * roofPremium) / annualSavings;

    // Code compliance (ASHRAE 90.1, Title 24)
    // Low-slope: SRI ≥ 78, Steep-slope: SRI ≥ 25
    final meetsCode = newSRI >= 78;

    setState(() {
      _tempReduction = tempReduction;
      _coolingSavings = coolingSavings;
      _annualSavings = annualSavings;
      _paybackYears = paybackYears;
      _meetsCode = meetsCode;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2000';
    _currentSRIController.text = '25';
    _newSRIController.text = '78';
    _electricRateController.text = '0.12';
    setState(() => _climateZone = 'Hot-Humid');
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
        title: Text('Cool Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CLIMATE ZONE'),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF SPECIFICATIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Area',
                unit: 'sq ft',
                hint: 'Total area',
                controller: _roofAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Current SRI',
                      unit: '',
                      hint: '0-100',
                      controller: _currentSRIController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'New SRI',
                      unit: '',
                      hint: 'Cool roof',
                      controller: _newSRIController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Electric Rate',
                unit: '\$/kWh',
                hint: 'Utility rate',
                controller: _electricRateController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_tempReduction != null) ...[
                _buildSectionHeader(colors, 'COOL ROOF BENEFITS'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cool Roof Calculator',
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
            'Estimate energy savings from reflective roofing',
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

  Widget _buildClimateSelector(ZaftoColors colors) {
    final climates = ['Hot-Humid', 'Hot-Dry', 'Mixed'];
    return Row(
      children: climates.map((climate) {
        final isSelected = _climateZone == climate;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _climateZone = climate);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: climate != climates.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                climate,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final codeColor = _meetsCode! ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: codeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _meetsCode! ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 16,
                  color: codeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _meetsCode! ? 'Meets Code SRI ≥ 78' : 'Below Code Minimum',
                  style: TextStyle(color: codeColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Roof Temp Reduction', '${_tempReduction!.toStringAsFixed(0)}°F'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Cooling Savings', '${_coolingSavings!.toStringAsFixed(0)} kWh/yr'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'ANNUAL SAVINGS', '\$${_annualSavings!.toStringAsFixed(0)}', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Payback Period', '${_paybackYears!.toStringAsFixed(1)} years'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('SRI Reference', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Black roof: SRI ≈ 0-25', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('White/reflective: SRI ≈ 78-100', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Metal cool roof: SRI ≈ 50-70', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
