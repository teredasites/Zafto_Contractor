import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Load Calculation Basics Diagram - Design System v2.6
class LoadCalculationScreen extends ConsumerWidget {
  const LoadCalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text('Load Calculation Basics', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhyCalculate(colors),
            const SizedBox(height: 16),
            _buildManualJ(colors),
            const SizedBox(height: 16),
            _buildHeatGainFactors(colors),
            const SizedBox(height: 16),
            _buildHeatLossFactors(colors),
            const SizedBox(height: 16),
            _buildQuickEstimates(colors),
            const SizedBox(height: 16),
            _buildOversizingProblems(colors),
            const SizedBox(height: 16),
            _buildSoftwareTools(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyCalculate(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('WHY LOAD CALCULATIONS MATTER', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Proper equipment sizing ensures comfort, efficiency, and equipment longevity.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _whyRow('Comfort', 'Right-sized equipment maintains even temperatures', colors),
          _whyRow('Efficiency', 'Equipment runs at optimal efficiency', colors),
          _whyRow('Humidity control', 'Proper runtime removes moisture', colors),
          _whyRow('Equipment life', 'Reduces cycling, extends life', colors),
          _whyRow('Cost savings', 'Lower utility bills, smaller equipment cost', colors),
        ],
      ),
    );
  }

  Widget _whyRow(String benefit, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualJ(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANUAL J - THE STANDARD', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('ACCA Manual J is the industry standard for residential load calculations.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _mjRow('Manual J', 'Calculate heating/cooling loads', colors),
          _mjRow('Manual S', 'Equipment selection', colors),
          _mjRow('Manual D', 'Duct design', colors),
          _mjRow('Manual T', 'Air distribution', colors),
          const SizedBox(height: 12),
          Text('Manual J Inputs:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _inputRow('Climate data', 'Design temps for location', colors),
          _inputRow('Building envelope', 'Walls, roof, floor construction', colors),
          _inputRow('Windows', 'Size, type, orientation, shading', colors),
          _inputRow('Insulation', 'R-values throughout', colors),
          _inputRow('Infiltration', 'Air leakage rate', colors),
          _inputRow('Internal gains', 'People, lights, equipment', colors),
        ],
      ),
    );
  }

  Widget _mjRow(String manual, String purpose, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(manual, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(purpose, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _inputRow(String input, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(input, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildHeatGainFactors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.sun, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('COOLING LOAD FACTORS (HEAT GAIN)', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Sources of heat entering the building:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _gainRow('Solar through windows', '30-50%', 'Biggest factor, orientation matters', colors),
          _gainRow('Conduction through walls', '15-25%', 'Depends on insulation, color', colors),
          _gainRow('Conduction through roof', '10-20%', 'Critical in single-story', colors),
          _gainRow('Infiltration', '10-20%', 'Air leakage bringing in hot air', colors),
          _gainRow('Internal gains', '10-20%', 'People, lights, appliances', colors),
          _gainRow('Duct gains', '5-15%', 'Ducts in unconditioned space', colors),
        ],
      ),
    );
  }

  Widget _gainRow(String source, String percent, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(source, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 45, child: Text(percent, style: TextStyle(color: colors.accentError, fontSize: 11))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildHeatLossFactors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.snowflake, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('HEATING LOAD FACTORS (HEAT LOSS)', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Sources of heat leaving the building:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _lossRow('Windows/doors', '25-35%', 'Lowest R-value components', colors),
          _lossRow('Wall conduction', '15-25%', 'Depends on insulation', colors),
          _lossRow('Roof/ceiling', '10-20%', 'Heat rises, escapes through top', colors),
          _lossRow('Infiltration', '20-40%', 'Air leakage - often biggest factor', colors),
          _lossRow('Floor/foundation', '10-15%', 'Slab edge, basement walls', colors),
          _lossRow('Duct losses', '10-25%', 'Ducts in unconditioned space', colors),
        ],
      ),
    );
  }

  Widget _lossRow(String source, String percent, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(source, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 50, child: Text(percent, style: TextStyle(color: colors.accentInfo, fontSize: 11))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildQuickEstimates(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('QUICK ESTIMATES (ROUGH ONLY)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('These are rough estimates only! Proper Manual J calculation is required for accurate sizing.', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Text('Cooling (BTU/hr):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _estRow('Per sq ft', '20-35 BTU', 'varies by climate', colors),
          _estRow('400 CFM', '12,000 BTU', '= 1 ton', colors),
          const SizedBox(height: 10),
          Text('Heating (BTU/hr):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _estRow('Per sq ft', '25-50 BTU', 'varies by climate', colors),
          _estRow('Northern US', '40-50 BTU/sqft', 'cold climate', colors),
          _estRow('Southern US', '25-35 BTU/sqft', 'mild climate', colors),
          const SizedBox(height: 12),
          Text('Example: 2,000 sq ft, moderate climate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
          Text('Cooling: 2,000 × 25 = 50,000 BTU = ~4 tons\nHeating: 2,000 × 35 = 70,000 BTU', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _estRow(String factor, String value, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 85, child: Text(factor, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          SizedBox(width: 70, child: Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildOversizingProblems(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
            const SizedBox(width: 8),
            Text('OVERSIZING PROBLEMS', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Bigger is NOT better! Oversized equipment causes:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _problemRow('Short cycling', 'Rapid on/off, premature wear', colors),
          _problemRow('Poor humidity control', 'Not enough runtime to dehumidify', colors),
          _problemRow('Hot/cold spots', 'Doesn\'t run long enough to mix air', colors),
          _problemRow('Higher cost', 'Larger equipment costs more', colors),
          _problemRow('Energy waste', 'Frequent starts use more energy', colors),
          _problemRow('Noise', 'Larger equipment is louder', colors),
          const SizedBox(height: 12),
          Text('Target 90-100% of calculated load. Never exceed 125%.', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _problemRow(String problem, String effect, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 95, child: Text(problem, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(effect, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSoftwareTools(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.laptop, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('LOAD CALCULATION SOFTWARE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _softRow('Wrightsoft', 'Professional, ACCA approved', colors),
          _softRow('CoolCalc', 'ACCA approved, cloud-based', colors),
          _softRow('HVAC Solution', 'Elite Software', colors),
          _softRow('LoadCalc', 'Online calculators (less accurate)', colors),
          const SizedBox(height: 12),
          Text('Look for ACCA Manual J approved software for code compliance.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _softRow(String software, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(software, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(notes, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IRC M1401.3 - Equipment sizing\n'
            '• ACCA Manual J required (or equivalent)\n'
            '• Load calc must accompany permit\n'
            '• Equipment selection per Manual S\n'
            '• Cannot exceed 125% of calculated load\n'
            '• Duct sizing per Manual D\n'
            '• Design conditions per ACCA Manual J\n'
            '• Documentation retained with permit',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
