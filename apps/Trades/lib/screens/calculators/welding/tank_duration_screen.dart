import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tank Duration Calculator - Gas cylinder usage time
class TankDurationScreen extends ConsumerStatefulWidget {
  const TankDurationScreen({super.key});
  @override
  ConsumerState<TankDurationScreen> createState() => _TankDurationScreenState();
}

class _TankDurationScreenState extends ConsumerState<TankDurationScreen> {
  final _flowRateController = TextEditingController(text: '25');
  final _pressureController = TextEditingController(text: '2200');
  final _arcTimeController = TextEditingController(text: '30');
  String _tankSize = '80 cf';

  double? _totalHours;
  double? _arcHours;
  double? _shiftsPerTank;
  String? _notes;

  // Tank sizes in cubic feet
  static const Map<String, double> _tankSizes = {
    '20 cf': 20,
    '40 cf': 40,
    '80 cf': 80,
    '125 cf': 125,
    '150 cf': 150,
    '250 cf': 250,
    '300 cf': 300,
  };

  void _calculate() {
    final flowRate = double.tryParse(_flowRateController.text) ?? 25;
    final pressure = double.tryParse(_pressureController.text) ?? 2200;
    final arcTimePercent = double.tryParse(_arcTimeController.text) ?? 30;

    if (flowRate <= 0) {
      setState(() { _totalHours = null; });
      return;
    }

    final tankCf = _tankSizes[_tankSize] ?? 80;

    // Adjust for actual pressure (full tank = 2200 psi typical)
    final actualCf = tankCf * (pressure / 2200);

    // Convert CFH to hours
    final totalMinutes = (actualCf / flowRate) * 60;
    final totalHours = totalMinutes / 60;

    // Arc time factor
    final arcHours = totalHours / (arcTimePercent / 100);
    final shiftsPerTank = arcHours / 8;

    String notes;
    if (shiftsPerTank < 0.5) {
      notes = 'Consider larger tank or lower flow rate';
    } else if (shiftsPerTank < 1) {
      notes = 'Will need to change tank mid-shift';
    } else if (shiftsPerTank < 2) {
      notes = 'Good for ~1 shift of production welding';
    } else {
      notes = 'Multiple shifts per tank';
    }

    setState(() {
      _totalHours = totalHours;
      _arcHours = arcHours;
      _shiftsPerTank = shiftsPerTank;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _flowRateController.text = '25';
    _pressureController.text = '2200';
    _arcTimeController.text = '30';
    setState(() { _totalHours = null; });
  }

  @override
  void dispose() {
    _flowRateController.dispose();
    _pressureController.dispose();
    _arcTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tank Duration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Tank Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTankSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Flow Rate', unit: 'CFH', hint: '25 CFH typical', controller: _flowRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tank Pressure', unit: 'PSI', hint: '2200 when full', controller: _pressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Arc-On Time', unit: '%', hint: '30% typical', controller: _arcTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalHours != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTankSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tankSizes.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _tankSize == size,
        onSelected: (_) => setState(() { _tankSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Time = Tank CF / Flow Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate gas cylinder duration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Continuous Use', '${_totalHours!.toStringAsFixed(1)} hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Work Time', '${_arcHours!.toStringAsFixed(1)} hrs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, '8-hr Shifts', _shiftsPerTank!.toStringAsFixed(1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
