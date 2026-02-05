import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Service Area Calculator - Daily capacity planning
class ServiceAreaScreen extends ConsumerStatefulWidget {
  const ServiceAreaScreen({super.key});
  @override
  ConsumerState<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends ConsumerState<ServiceAreaScreen> {
  final _avgLotController = TextEditingController(text: '8000');
  final _crewSizeController = TextEditingController(text: '2');
  final _workHoursController = TextEditingController(text: '8');

  String _serviceType = 'mowing';

  int? _propertiesPerDay;
  double? _sqFtPerDay;
  double? _sqFtPerHour;

  @override
  void dispose() { _avgLotController.dispose(); _crewSizeController.dispose(); _workHoursController.dispose(); super.dispose(); }

  void _calculate() {
    final avgLot = double.tryParse(_avgLotController.text) ?? 8000;
    final crewSize = int.tryParse(_crewSizeController.text) ?? 2;
    final workHours = double.tryParse(_workHoursController.text) ?? 8;

    // Base sq ft per person-hour by service type
    double sqFtPerPersonHour;
    switch (_serviceType) {
      case 'mowing':
        sqFtPerPersonHour = 4000; // With commercial ZTR
        break;
      case 'trimming':
        sqFtPerPersonHour = 2000;
        break;
      case 'mulching':
        sqFtPerPersonHour = 500;
        break;
      case 'cleanup':
        sqFtPerPersonHour = 3000;
        break;
      default:
        sqFtPerPersonHour = 3000;
    }

    final totalPersonHours = crewSize * workHours;
    final sqFtPerDay = totalPersonHours * sqFtPerPersonHour;
    final properties = (sqFtPerDay / avgLot).floor();

    setState(() {
      _propertiesPerDay = properties;
      _sqFtPerDay = sqFtPerDay;
      _sqFtPerHour = sqFtPerPersonHour * crewSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _avgLotController.text = '8000'; _crewSizeController.text = '2'; _workHoursController.text = '8'; setState(() { _serviceType = 'mowing'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Service Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SERVICE TYPE', ['mowing', 'trimming', 'mulching', 'cleanup'], _serviceType, {'mowing': 'Mowing', 'trimming': 'Trim', 'mulching': 'Mulch', 'cleanup': 'Cleanup'}, (v) { setState(() => _serviceType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Avg Property Size', unit: 'sq ft', controller: _avgLotController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Crew Size', unit: '', controller: _crewSizeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Work Hours', unit: 'hrs', controller: _workHoursController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_propertiesPerDay != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PROPERTIES/DAY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_propertiesPerDay', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Daily capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_sqFtPerDay! / 1000).toStringAsFixed(0)}K sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Crew rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqFtPerHour!.toStringAsFixed(0)} sq ft/hr', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCapacityGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCapacityGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRODUCTION RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mowing (ZTR)', '3-5K sq ft/person-hr'),
        _buildTableRow(colors, 'String trim', '2K sq ft/person-hr'),
        _buildTableRow(colors, 'Mulching', '0.5K sq ft/person-hr'),
        _buildTableRow(colors, 'Leaf cleanup', '2-4K sq ft/person-hr'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
