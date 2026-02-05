import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Engine CFM Calculator - Airflow requirements by HP target
class EngineCfmScreen extends ConsumerStatefulWidget {
  const EngineCfmScreen({super.key});
  @override
  ConsumerState<EngineCfmScreen> createState() => _EngineCfmScreenState();
}

class _EngineCfmScreenState extends ConsumerState<EngineCfmScreen> {
  final _displacementController = TextEditingController();
  final _rpmController = TextEditingController();
  final _veController = TextEditingController(text: '85');

  double? _cfmRequired;
  double? _throttleBody;

  void _calculate() {
    final ci = double.tryParse(_displacementController.text);
    final rpm = double.tryParse(_rpmController.text);
    final ve = double.tryParse(_veController.text);

    if (ci == null || rpm == null || ve == null) {
      setState(() { _cfmRequired = null; });
      return;
    }

    // CFM = (CID × RPM × VE) / 3456
    final cfm = (ci * rpm * (ve / 100)) / 3456;
    // Throttle body size estimate (area = CFM / 146)
    final area = cfm / 146;
    final diameter = 2 * (area / 3.14159).abs();

    setState(() {
      _cfmRequired = cfm;
      _throttleBody = diameter > 0 ? (diameter * 25.4).abs() : null;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _rpmController.clear();
    _veController.text = '85';
    setState(() { _cfmRequired = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
    _rpmController.dispose();
    _veController.dispose();
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
        title: Text('Engine CFM', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Displacement', unit: 'CI', hint: 'Cubic inches', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max RPM', unit: 'RPM', hint: 'Peak engine speed', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Volumetric Efficiency', unit: '%', hint: '80-100%', controller: _veController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cfmRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('CFM = (CID × RPM × VE%) / 3456', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Size carb, throttle body, or turbo for engine', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Airflow Required', '${_cfmRequired!.toStringAsFixed(0)} CFM', isPrimary: true),
        if (_throttleBody != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Min Throttle Body', '${_throttleBody!.toStringAsFixed(0)} mm'),
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
