import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shielding Gas Calculator - CFH and tank duration
class ShieldingGasScreen extends ConsumerStatefulWidget {
  const ShieldingGasScreen({super.key});
  @override
  ConsumerState<ShieldingGasScreen> createState() => _ShieldingGasScreenState();
}

class _ShieldingGasScreenState extends ConsumerState<ShieldingGasScreen> {
  final _flowRateController = TextEditingController(text: '25');
  final _arcTimeController = TextEditingController();
  String _tankSize = '80 CF';

  double? _gasUsed;
  double? _tankDuration;
  int? _tanksNeeded;

  static const Map<String, double> _tankSizes = {
    '40 CF': 40,
    '80 CF': 80,
    '125 CF': 125,
    '250 CF': 250,
    '330 CF': 330,
  };

  void _calculate() {
    final flowRate = double.tryParse(_flowRateController.text);
    final arcTime = double.tryParse(_arcTimeController.text);
    final tankCf = _tankSizes[_tankSize]!;

    if (flowRate == null || flowRate <= 0) {
      setState(() { _gasUsed = null; });
      return;
    }

    // CFH = flow rate, tank duration in hours
    final duration = tankCf / flowRate;

    double? gasUsed;
    int? tanks;
    if (arcTime != null && arcTime > 0) {
      gasUsed = (flowRate / 60) * arcTime; // Arc time in minutes
      tanks = (gasUsed / tankCf).ceil();
    }

    setState(() {
      _tankDuration = duration;
      _gasUsed = gasUsed;
      _tanksNeeded = tanks;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _flowRateController.text = '25';
    _arcTimeController.clear();
    setState(() { _gasUsed = null; });
  }

  @override
  void dispose() {
    _flowRateController.dispose();
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
        title: Text('Shielding Gas', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('TANK SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTankSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Flow Rate', unit: 'CFH', hint: '20-35 typical', controller: _flowRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Est. Arc Time', unit: 'min', hint: 'Optional - for job planning', controller: _arcTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tankDuration != null) _buildResultsCard(colors),
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
        Text('Duration = Tank CF / Flow Rate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Plan gas needs for jobs', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Tank Duration', '${_tankDuration!.toStringAsFixed(1)} hrs', isPrimary: true),
        if (_gasUsed != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Gas for Job', '${_gasUsed!.toStringAsFixed(1)} CF'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Tanks Needed', '$_tanksNeeded'),
        ],
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
