import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Derating / Adjustment Factors Table - Design System v2.6
class DeratingTableScreen extends ConsumerWidget {
  const DeratingTableScreen({super.key});

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
        title: Text('Derating / Adjustment Factors', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConduitFillDerating(colors),
            const SizedBox(height: 16),
            _buildAmbientTempCorrection(colors),
            const SizedBox(height: 16),
            _buildRooftopDerating(colors),
            const SizedBox(height: 16),
            _buildExample(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildConduitFillDerating(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 310.15(C)(1)', 'Conduit Fill Adjustment Factors', colors),
          const SizedBox(height: 8),
          Text('When more than 3 current-carrying conductors in raceway:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['# Conductors', 'Adjustment Factor'], colors),
                _dataRow(['4-6', '80%'], colors),
                _dataRow(['7-9', '70%'], colors),
                _dataRow(['10-20', '50%'], colors),
                _dataRow(['21-30', '45%'], colors),
                _dataRow(['31-40', '40%'], colors),
                _dataRow(['41+', '35%'], colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOT counted as current-carrying:', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
                Text('• Equipment grounding conductors', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('• Neutrals that carry only unbalanced current', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('• Control/signal conductors', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientTempCorrection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 310.15(B)(1)', 'Ambient Temperature Correction', colors),
          const SizedBox(height: 8),
          Text('For ambient temperatures other than 30°C (86°F):', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Ambient °C', 'Ambient °F', '60°C', '75°C', '90°C'], colors),
                _dataRow(['21-25', '70-77', '1.08', '1.05', '1.04'], colors),
                _dataRow(['26-30', '78-86', '1.00', '1.00', '1.00'], colors),
                _dataRow(['31-35', '87-95', '0.91', '0.94', '0.96'], colors),
                _dataRow(['36-40', '96-104', '0.82', '0.88', '0.91'], colors),
                _dataRow(['41-45', '105-113', '0.71', '0.82', '0.87'], colors),
                _dataRow(['46-50', '114-122', '0.58', '0.75', '0.82'], colors),
                _dataRow(['51-55', '123-131', '0.41', '0.67', '0.76'], colors),
                _dataRow(['56-60', '132-140', '-', '0.58', '0.71'], colors),
                _dataRow(['61-65', '141-149', '-', '0.47', '0.65'], colors),
                _dataRow(['66-70', '150-158', '-', '0.33', '0.58'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Multiply base ampacity by correction factor', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRooftopDerating(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader('NEC Table 310.15(B)(2)', 'Rooftop Ambient Temperature Adders', colors),
          const SizedBox(height: 8),
          Text('Add to outdoor ambient for conduit on rooftops exposed to sun:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _headerRow(['Height Above Roof', 'Temp Adder °C', 'Temp Adder °F'], colors),
                _dataRow(['0 - 1/2 inch', '+33°C', '+60°F'], colors),
                _dataRow(['Above 1/2" to 3-1/2"', '+22°C', '+40°F'], colors),
                _dataRow(['Above 3-1/2" to 12"', '+17°C', '+30°F'], colors),
                _dataRow(['Above 12" to 36"', '+14°C', '+25°F'], colors),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Add this to ambient, then use correction factor table', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildExample(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.calculator, color: colors.accentSuccess, size: 18),
            const SizedBox(width: 8),
            Text('CALCULATION EXAMPLE', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Problem: 6 current-carrying conductors in conduit, 95°F ambient, using 75°C rated wire (THWN). Base ampacity for #10 THWN = 35A.\n',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 1: Conduit fill adjustment', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
                Text('  6 conductors = 80% (0.80)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Step 2: Temperature correction', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
                Text('  95°F = 35°C = 0.94 for 75°C wire', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Step 3: Final ampacity', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
                Text('  35A × 0.80 × 0.94 = 26.32A', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String code, String title, ZaftoColors colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)),
          child: Text(code, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _headerRow(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(h, textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
        )).toList(),
      ),
    );
  }

  Widget _dataRow(List<String> values, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: e.key == 0 ? colors.textPrimary : colors.textSecondary,
              fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        )).toList(),
      ),
    );
  }
}
