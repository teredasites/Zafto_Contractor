import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Crew Productivity Calculator - Labor efficiency metrics
class CrewProductivityScreen extends ConsumerStatefulWidget {
  const CrewProductivityScreen({super.key});
  @override
  ConsumerState<CrewProductivityScreen> createState() => _CrewProductivityScreenState();
}

class _CrewProductivityScreenState extends ConsumerState<CrewProductivityScreen> {
  final _crewSizeController = TextEditingController(text: '3');
  final _hoursController = TextEditingController(text: '8');
  final _revenueController = TextEditingController(text: '1800');
  final _laborCostController = TextEditingController(text: '600');

  double? _revenuePerManHour;
  double? _costPerManHour;
  double? _laborEfficiency;
  double? _totalManHours;
  String? _rating;

  @override
  void dispose() { _crewSizeController.dispose(); _hoursController.dispose(); _revenueController.dispose(); _laborCostController.dispose(); super.dispose(); }

  void _calculate() {
    final crewSize = double.tryParse(_crewSizeController.text) ?? 3;
    final hours = double.tryParse(_hoursController.text) ?? 8;
    final revenue = double.tryParse(_revenueController.text) ?? 1800;
    final laborCost = double.tryParse(_laborCostController.text) ?? 600;

    final manHours = crewSize * hours;
    final revenuePerMH = revenue / manHours;
    final costPerMH = laborCost / manHours;
    final efficiency = (revenue / laborCost) * 100;

    String rating;
    if (revenuePerMH >= 80) {
      rating = 'Excellent';
    } else if (revenuePerMH >= 60) {
      rating = 'Good';
    } else if (revenuePerMH >= 45) {
      rating = 'Average';
    } else {
      rating = 'Below target';
    }

    setState(() {
      _totalManHours = manHours;
      _revenuePerManHour = revenuePerMH;
      _costPerManHour = costPerMH;
      _laborEfficiency = efficiency;
      _rating = rating;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _crewSizeController.text = '3'; _hoursController.text = '8'; _revenueController.text = '1800'; _laborCostController.text = '600'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isGood = (_revenuePerManHour ?? 0) >= 60;
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Crew Productivity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Crew Size', unit: 'people', controller: _crewSizeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Hours Worked', unit: 'hrs', controller: _hoursController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Day Revenue', unit: '\$', controller: _revenueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Labor Cost', unit: '\$', controller: _laborCostController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_revenuePerManHour != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('REVENUE/MAN-HOUR', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_revenuePerManHour!.toStringAsFixed(0)}', style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rating', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rating', style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Man-hours worked', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalManHours!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cost/man-hour', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_costPerManHour!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor efficiency', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborEfficiency!.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildProductivityGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProductivityGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRODUCTIVITY TARGETS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Excellent', '\$80+/man-hour'),
        _buildTableRow(colors, 'Good', '\$60-80/man-hour'),
        _buildTableRow(colors, 'Average', '\$45-60/man-hour'),
        _buildTableRow(colors, 'Target ratio', '3:1 revenue:labor'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
