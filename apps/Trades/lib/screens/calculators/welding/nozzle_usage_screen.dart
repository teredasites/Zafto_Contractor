import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Nozzle Usage Calculator - MIG nozzle replacement planning
class NozzleUsageScreen extends ConsumerStatefulWidget {
  const NozzleUsageScreen({super.key});
  @override
  ConsumerState<NozzleUsageScreen> createState() => _NozzleUsageScreenState();
}

class _NozzleUsageScreenState extends ConsumerState<NozzleUsageScreen> {
  final _arcHoursController = TextEditingController(text: '8');
  final _amperageController = TextEditingController(text: '200');
  String _nozzleType = 'Copper';
  String _application = 'Production';

  double? _nozzleLife;
  double? _nozzlesPerWeek;
  String? _maintenanceTip;

  // Base nozzle life in arc hours
  static const Map<String, double> _baseLife = {
    'Copper': 40,
    'Brass': 30,
    'Chrome Plated': 60,
    'Ceramic': 100,
  };

  void _calculate() {
    final arcHours = double.tryParse(_arcHoursController.text) ?? 8;
    final amperage = double.tryParse(_amperageController.text) ?? 200;

    if (arcHours <= 0) {
      setState(() { _nozzleLife = null; });
      return;
    }

    var baseLife = _baseLife[_nozzleType] ?? 40.0;

    // Adjust for amperage (higher amps = shorter life)
    final amperageMultiplier = amperage > 300 ? 0.6 : (amperage > 200 ? 0.8 : 1.0);

    // Adjust for application
    double appMultiplier;
    String maintenanceTip;
    if (_application == 'Production') {
      appMultiplier = 0.7;
      maintenanceTip = 'Clean spatter buildup frequently. Use anti-spatter spray';
    } else if (_application == 'Heavy Fab') {
      appMultiplier = 0.5;
      maintenanceTip = 'High spatter environment - consider ceramic nozzles';
    } else {
      appMultiplier = 1.0;
      maintenanceTip = 'Light duty - clean nozzle weekly, replace as needed';
    }

    final nozzleLife = baseLife * amperageMultiplier * appMultiplier;
    final shiftsPerNozzle = nozzleLife / (arcHours * 0.3); // 30% arc-on time
    final nozzlesPerWeek = 5 / shiftsPerNozzle;

    setState(() {
      _nozzleLife = nozzleLife;
      _nozzlesPerWeek = nozzlesPerWeek;
      _maintenanceTip = maintenanceTip;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _arcHoursController.text = '8';
    _amperageController.text = '200';
    setState(() { _nozzleLife = null; });
  }

  @override
  void dispose() {
    _arcHoursController.dispose();
    _amperageController.dispose();
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
        title: Text('Nozzle Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Nozzle Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildNozzleSelector(colors),
            const SizedBox(height: 16),
            Text('Application', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildApplicationSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Shift Length', unit: 'hrs', hint: '8 hr shift', controller: _arcHoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Typical Amperage', unit: 'A', hint: 'Average amps', controller: _amperageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_nozzleLife != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNozzleSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _baseLife.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 12)),
        selected: _nozzleType == type,
        onSelected: (_) => setState(() { _nozzleType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = ['Light Duty', 'Production', 'Heavy Fab'];
    return Wrap(
      spacing: 8,
      children: apps.map((a) => ChoiceChip(
        label: Text(a),
        selected: _application == a,
        onSelected: (_) => setState(() { _application = a; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('MIG Nozzle Life Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Plan consumable replacement', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Nozzle Life', '${_nozzleLife!.toStringAsFixed(0)} arc hrs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Week (5 day)', _nozzlesPerWeek!.toStringAsFixed(1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_maintenanceTip!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
