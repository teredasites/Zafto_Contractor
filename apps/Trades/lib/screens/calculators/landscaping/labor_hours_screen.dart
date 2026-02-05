import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Labor Hours Calculator - Estimate task duration
class LaborHoursScreen extends ConsumerStatefulWidget {
  const LaborHoursScreen({super.key});
  @override
  ConsumerState<LaborHoursScreen> createState() => _LaborHoursScreenState();
}

class _LaborHoursScreenState extends ConsumerState<LaborHoursScreen> {
  final _quantityController = TextEditingController(text: '100');

  String _task = 'mulch';
  int _crewSize = 2;

  double? _laborHours;
  double? _crewHours;
  double? _laborCost;

  @override
  void dispose() { _quantityController.dispose(); super.dispose(); }

  void _calculate() {
    final quantity = double.tryParse(_quantityController.text) ?? 100;

    // Production rates (unit per man-hour)
    double unitsPerManHour;
    String unit;
    switch (_task) {
      case 'mulch': // sq ft spread per hour
        unitsPerManHour = 100;
        unit = 'sq ft';
        break;
      case 'planting': // plants per hour
        unitsPerManHour = 10;
        unit = 'plants';
        break;
      case 'pavers': // sq ft per hour
        unitsPerManHour = 15;
        unit = 'sq ft';
        break;
      case 'sod': // sq ft per hour
        unitsPerManHour = 150;
        unit = 'sq ft';
        break;
      case 'edging': // linear ft per hour
        unitsPerManHour = 50;
        unit = 'lin ft';
        break;
      case 'fence': // linear ft per hour
        unitsPerManHour = 8;
        unit = 'lin ft';
        break;
      default:
        unitsPerManHour = 100;
        unit = 'units';
    }

    final manHours = quantity / unitsPerManHour;
    final crewHours = manHours / _crewSize;

    // Assume $35/hr labor cost
    final laborCost = manHours * 35;

    setState(() {
      _laborHours = manHours;
      _crewHours = crewHours;
      _laborCost = laborCost;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _quantityController.text = '100'; setState(() { _task = 'mulch'; _crewSize = 2; }); _calculate(); }

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
            _buildTaskSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Quantity', unit: _getUnit(), controller: _quantityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Crew size:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(children: [1, 2, 3, 4].map((s) {
                  final isSelected = _crewSize == s;
                  return Expanded(child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() { _crewSize = s; }); _calculate(); },
                    child: Container(margin: EdgeInsets.only(right: s != 4 ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
                      child: Text('$s', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ));
                }).toList()),
              ),
            ]),
            const SizedBox(height: 32),
            if (_laborHours != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MAN-HOURS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Crew time ($_crewSize workers)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_crewHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor cost (\$35/hr)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_laborCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRatesGuide(colors),
          ]),
        ),
      ),
    );
  }

  String _getUnit() {
    switch (_task) {
      case 'mulch': return 'sq ft';
      case 'planting': return 'plants';
      case 'pavers': return 'sq ft';
      case 'sod': return 'sq ft';
      case 'edging': return 'lin ft';
      case 'fence': return 'lin ft';
      default: return 'units';
    }
  }

  Widget _buildTaskSelector(ZaftoColors colors) {
    final tasks = ['mulch', 'planting', 'pavers', 'sod', 'edging', 'fence'];
    final labels = {'mulch': 'Mulch', 'planting': 'Planting', 'pavers': 'Pavers', 'sod': 'Sod', 'edging': 'Edging', 'fence': 'Fence'};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TASK TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: tasks.map((t) {
        final isSelected = _task == t;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _task = t; }); _calculate(); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[t]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildRatesGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRODUCTION RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mulch spreading', '100 sq ft/man-hr'),
        _buildTableRow(colors, 'Planting (1 gal)', '10 plants/man-hr'),
        _buildTableRow(colors, 'Paver install', '15 sq ft/man-hr'),
        _buildTableRow(colors, 'Sod laying', '150 sq ft/man-hr'),
        _buildTableRow(colors, 'Steel edging', '50 lin ft/man-hr'),
        _buildTableRow(colors, 'Wood fence', '8 lin ft/man-hr'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
