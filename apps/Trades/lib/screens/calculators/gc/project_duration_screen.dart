import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Project Duration Calculator - Schedule estimation
class ProjectDurationScreen extends ConsumerStatefulWidget {
  const ProjectDurationScreen({super.key});
  @override
  ConsumerState<ProjectDurationScreen> createState() => _ProjectDurationScreenState();
}

class _ProjectDurationScreenState extends ConsumerState<ProjectDurationScreen> {
  final _sqftController = TextEditingController(text: '2500');
  final _crewController = TextEditingController(text: '4');

  String _projectType = 'new_home';

  int? _workDays;
  int? _calendarDays;
  int? _weeks;

  @override
  void dispose() { _sqftController.dispose(); _crewController.dispose(); super.dispose(); }

  void _calculate() {
    final sqft = double.tryParse(_sqftController.text);
    final crew = int.tryParse(_crewController.text) ?? 4;

    if (sqft == null) {
      setState(() { _workDays = null; _calendarDays = null; _weeks = null; });
      return;
    }

    // Days per 1000 sqft by project type (with standard crew)
    double daysPerThousand;
    switch (_projectType) {
      case 'new_home': daysPerThousand = 60; break;      // 4-6 months typical
      case 'addition': daysPerThousand = 30; break;      // Faster but complex
      case 'renovation': daysPerThousand = 25; break;    // Depends on scope
      case 'commercial': daysPerThousand = 45; break;    // More complex
      case 'tenant_imp': daysPerThousand = 15; break;    // Lighter work
      default: daysPerThousand = 60;
    }

    // Base calculation
    var workDays = ((sqft / 1000) * daysPerThousand).ceil();

    // Adjust for crew size (baseline is 4)
    final crewFactor = 4 / crew;
    workDays = (workDays * crewFactor).ceil();

    // Minimum duration
    if (workDays < 5) workDays = 5;

    // Calendar days (add weekends, ~1.4x multiplier)
    final calendarDays = (workDays * 1.4).ceil();
    final weeks = (calendarDays / 7).ceil();

    setState(() { _workDays = workDays; _calendarDays = calendarDays; _weeks = weeks; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _sqftController.text = '2500'; _crewController.text = '4'; setState(() => _projectType = 'new_home'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Project Duration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Project Size', unit: 'sq ft', controller: _sqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Crew Size', unit: 'workers', controller: _crewController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_workDays != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DURATION', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_weeks weeks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Work Days', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_workDays days', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calendar Days', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_calendarDays days', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add buffer for weather, inspections, material delays. Typical: 10-20%.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildDurationTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['new_home', 'addition', 'renovation', 'commercial'];
    final labels = {'new_home': 'New Home', 'addition': 'Addition', 'renovation': 'Reno', 'commercial': 'Commercial'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PROJECT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _projectType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _projectType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildDurationTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL DURATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'New home (2500 sf)', '4-6 months'),
        _buildTableRow(colors, 'Major addition', '2-3 months'),
        _buildTableRow(colors, 'Kitchen remodel', '4-8 weeks'),
        _buildTableRow(colors, 'Bathroom remodel', '2-4 weeks'),
        _buildTableRow(colors, 'Roof replacement', '1-3 days'),
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
