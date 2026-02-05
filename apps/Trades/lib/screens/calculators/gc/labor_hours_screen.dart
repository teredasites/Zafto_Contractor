import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Labor Hours Calculator - Project labor estimation
class LaborHoursScreen extends ConsumerStatefulWidget {
  const LaborHoursScreen({super.key});
  @override
  ConsumerState<LaborHoursScreen> createState() => _LaborHoursScreenState();
}

class _LaborHoursScreenState extends ConsumerState<LaborHoursScreen> {
  final _sqftController = TextEditingController(text: '2000');
  final _rateController = TextEditingController(text: '45');

  String _taskType = 'framing';

  double? _laborHours;
  double? _laborCost;
  int? _manDays;

  @override
  void dispose() { _sqftController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text);
    final rate = double.tryParse(_rateController.text);

    if (sqft == null || rate == null) {
      setState(() { _laborHours = null; _laborCost = null; _manDays = null; });
      return;
    }

    // Hours per sq ft by task type (industry averages)
    double hoursPerSqFt;
    switch (_taskType) {
      case 'framing': hoursPerSqFt = 0.08; break;      // ~12.5 sqft/hour
      case 'drywall': hoursPerSqFt = 0.04; break;      // ~25 sqft/hour
      case 'painting': hoursPerSqFt = 0.025; break;    // ~40 sqft/hour
      case 'flooring': hoursPerSqFt = 0.05; break;     // ~20 sqft/hour
      case 'roofing': hoursPerSqFt = 0.03; break;      // ~33 sqft/hour
      case 'siding': hoursPerSqFt = 0.04; break;       // ~25 sqft/hour
      case 'tile': hoursPerSqFt = 0.1; break;          // ~10 sqft/hour
      case 'demo': hoursPerSqFt = 0.02; break;         // ~50 sqft/hour
      default: hoursPerSqFt = 0.05;
    }

    final laborHours = sqft * hoursPerSqFt;
    final laborCost = laborHours * rate;
    final manDays = (laborHours / 8).ceil();

    setState(() { _laborHours = laborHours; _laborCost = laborCost; _manDays = manDays; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '2000'; _rateController.text = '45'; setState(() => _taskType = 'framing'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Labor Hours', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Labor Rate', unit: '\$/hr', controller: _rateController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_laborHours != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LABOR HOURS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Man-Days (8 hr)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_manDays days', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_laborCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add 10-20% for complexity, access issues, or inexperienced crews.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildProductivityTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['framing', 'drywall', 'painting', 'flooring'];
    final labels = {'framing': 'Framing', 'drywall': 'Drywall', 'painting': 'Paint', 'flooring': 'Floor'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TASK TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _taskType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _taskType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
      const SizedBox(height: 8),
      Row(children: ['roofing', 'siding', 'tile', 'demo'].map((o) {
        final isSelected = _taskType == o;
        final labels2 = {'roofing': 'Roof', 'siding': 'Siding', 'tile': 'Tile', 'demo': 'Demo'};
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _taskType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != 'demo' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels2[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildProductivityTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRODUCTIVITY RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Framing', '~12.5 sqft/hr'),
        _buildTableRow(colors, 'Drywall', '~25 sqft/hr'),
        _buildTableRow(colors, 'Painting', '~40 sqft/hr'),
        _buildTableRow(colors, 'Flooring', '~20 sqft/hr'),
        _buildTableRow(colors, 'Tile', '~10 sqft/hr'),
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
