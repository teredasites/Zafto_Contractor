import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Crew Size Calculator - Optimal crew sizing
class CrewSizeScreen extends ConsumerStatefulWidget {
  const CrewSizeScreen({super.key});
  @override
  ConsumerState<CrewSizeScreen> createState() => _CrewSizeScreenState();
}

class _CrewSizeScreenState extends ConsumerState<CrewSizeScreen> {
  final _laborHoursController = TextEditingController(text: '320');
  final _daysController = TextEditingController(text: '5');
  final _hoursPerDayController = TextEditingController(text: '8');

  int? _crewSize;
  double? _utilizationRate;
  double? _actualHoursNeeded;

  @override
  void dispose() { _laborHoursController.dispose(); _daysController.dispose(); _hoursPerDayController.dispose(); super.dispose(); }

  void _calculate() {
    final laborHours = double.tryParse(_laborHoursController.text);
    final days = double.tryParse(_daysController.text);
    final hoursPerDay = double.tryParse(_hoursPerDayController.text);

    if (laborHours == null || days == null || hoursPerDay == null || days == 0 || hoursPerDay == 0) {
      setState(() { _crewSize = null; _utilizationRate = null; _actualHoursNeeded = null; });
      return;
    }

    // Calculate required crew size
    final hoursAvailablePerPerson = days * hoursPerDay;
    final crewSizeExact = laborHours / hoursAvailablePerPerson;
    final crewSize = crewSizeExact.ceil();

    // Actual hours with rounded crew
    final actualHoursNeeded = laborHours / crewSize;

    // Utilization rate
    final utilizationRate = (crewSizeExact / crewSize) * 100;

    setState(() { _crewSize = crewSize; _utilizationRate = utilizationRate; _actualHoursNeeded = actualHoursNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _laborHoursController.text = '320'; _daysController.text = '5'; _hoursPerDayController.text = '8'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Crew Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Total Labor Hours', unit: 'hrs', controller: _laborHoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Available Days', unit: 'days', controller: _daysController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Hours/Day', unit: 'hrs', controller: _hoursPerDayController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_crewSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CREW SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_crewSize workers', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hours per Worker', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_actualHoursNeeded!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Utilization', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_utilizationRate!.toStringAsFixed(0)}%', style: TextStyle(color: _utilizationRate! >= 80 ? colors.accentSuccess : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Target 80-90% utilization. Factor in breaks, setup, and coordination time.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCrewGuidelines(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCrewGuidelines(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CREW CONSIDERATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Framing crew', '3-4 workers'),
        _buildTableRow(colors, 'Drywall hang', '2 workers min'),
        _buildTableRow(colors, 'Painting crew', '2-3 workers'),
        _buildTableRow(colors, 'Roofing crew', '4-6 workers'),
        _buildTableRow(colors, 'Concrete pour', '4-8 workers'),
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
