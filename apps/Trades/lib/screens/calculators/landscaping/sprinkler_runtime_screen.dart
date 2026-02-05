import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sprinkler Runtime Calculator - Watering schedule
class SprinklerRuntimeScreen extends ConsumerStatefulWidget {
  const SprinklerRuntimeScreen({super.key});
  @override
  ConsumerState<SprinklerRuntimeScreen> createState() => _SprinklerRuntimeScreenState();
}

class _SprinklerRuntimeScreenState extends ConsumerState<SprinklerRuntimeScreen> {
  final _targetInchesController = TextEditingController(text: '1');

  String _headType = 'rotor';
  String _soilType = 'loam';

  int? _runtimeMinutes;
  int? _cyclesNeeded;
  int? _cycleMinutes;
  double? _precipRate;

  @override
  void dispose() { _targetInchesController.dispose(); super.dispose(); }

  void _calculate() {
    final targetInches = double.tryParse(_targetInchesController.text) ?? 1;

    // Precipitation rate (inches per hour)
    double precipRate;
    switch (_headType) {
      case 'spray':
        precipRate = 1.5;
        break;
      case 'rotor':
        precipRate = 0.5;
        break;
      case 'mp_rotor':
        precipRate = 0.4;
        break;
      case 'drip':
        precipRate = 0.5;
        break;
      default:
        precipRate = 0.5;
    }

    // Total runtime needed
    final totalMinutes = (targetInches / precipRate) * 60;

    // Soil infiltration rate (inches per hour)
    double infiltrationRate;
    switch (_soilType) {
      case 'sandy':
        infiltrationRate = 2.0;
        break;
      case 'loam':
        infiltrationRate = 0.75;
        break;
      case 'clay':
        infiltrationRate = 0.25;
        break;
      default:
        infiltrationRate = 0.75;
    }

    // Cycle length before runoff
    final maxCycleMinutes = (infiltrationRate / precipRate) * 60;
    final cycles = (totalMinutes / maxCycleMinutes).ceil();
    final cycleLength = (totalMinutes / cycles).ceil();

    setState(() {
      _runtimeMinutes = totalMinutes.round();
      _cyclesNeeded = precipRate > infiltrationRate ? cycles : 1;
      _cycleMinutes = precipRate > infiltrationRate ? cycleLength : totalMinutes.round();
      _precipRate = precipRate;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _targetInchesController.text = '1'; setState(() { _headType = 'rotor'; _soilType = 'loam'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sprinkler Runtime', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HEAD TYPE', ['spray', 'rotor', 'mp_rotor', 'drip'], _headType, {'spray': 'Spray', 'rotor': 'Rotor', 'mp_rotor': 'MP', 'drip': 'Drip'}, (v) { setState(() => _headType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'SOIL TYPE', ['sandy', 'loam', 'clay'], _soilType, {'sandy': 'Sandy', 'loam': 'Loam', 'clay': 'Clay'}, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Target Water', unit: 'inches', controller: _targetInchesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_runtimeMinutes != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL RUNTIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_runtimeMinutes min', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cycles needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cyclesNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Minutes per cycle', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cycleMinutes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Precip rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_precipRate!.toStringAsFixed(2)} in/hr', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWateringGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWateringGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WATERING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Cool season lawn', '1-1.5\" per week'),
        _buildTableRow(colors, 'Warm season lawn', '0.75-1\" per week'),
        _buildTableRow(colors, 'Best time', '4-10 AM'),
        _buildTableRow(colors, 'Deep & infrequent', '2-3× per week'),
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
