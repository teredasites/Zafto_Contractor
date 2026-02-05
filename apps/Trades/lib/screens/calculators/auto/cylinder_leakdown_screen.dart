import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cylinder Leakdown Test Interpretation Calculator
class CylinderLeakdownScreen extends ConsumerStatefulWidget {
  const CylinderLeakdownScreen({super.key});
  @override
  ConsumerState<CylinderLeakdownScreen> createState() => _CylinderLeakdownScreenState();
}

class _CylinderLeakdownScreenState extends ConsumerState<CylinderLeakdownScreen> {
  final _inputPressureController = TextEditingController(text: '100');
  final _leakageController = TextEditingController();

  double? _leakagePercent;
  String? _condition;
  String? _conditionColor;
  String? _diagnosis;
  List<String> _possibleCauses = [];

  @override
  void dispose() {
    _inputPressureController.dispose();
    _leakageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inputPressure = double.tryParse(_inputPressureController.text);
    final leakage = double.tryParse(_leakageController.text);

    if (inputPressure == null || leakage == null || inputPressure <= 0) {
      setState(() { _leakagePercent = null; });
      return;
    }

    // Leakage percentage = (pressure lost / input pressure) * 100
    final leakagePercent = (leakage / inputPressure) * 100;

    String condition;
    String conditionColor;
    String diagnosis;
    List<String> causes = [];

    if (leakagePercent <= 5) {
      condition = 'Excellent';
      conditionColor = 'green';
      diagnosis = 'Engine is in excellent condition with minimal wear.';
    } else if (leakagePercent <= 10) {
      condition = 'Good';
      conditionColor = 'green';
      diagnosis = 'Normal wear, engine is in good working condition.';
    } else if (leakagePercent <= 15) {
      condition = 'Fair';
      conditionColor = 'yellow';
      diagnosis = 'Moderate wear present. Monitor for changes.';
      causes = ['Worn piston rings', 'Minor valve seating issues'];
    } else if (leakagePercent <= 20) {
      condition = 'Poor';
      conditionColor = 'orange';
      diagnosis = 'Significant leakage. Repair recommended.';
      causes = ['Worn piston rings', 'Valve seal issues', 'Head gasket seepage', 'Cylinder wall wear'];
    } else {
      condition = 'Failed';
      conditionColor = 'red';
      diagnosis = 'Excessive leakage. Major repair required.';
      causes = ['Blown head gasket', 'Cracked cylinder head', 'Broken piston rings', 'Burned valve', 'Scored cylinder wall'];
    }

    setState(() {
      _leakagePercent = leakagePercent;
      _condition = condition;
      _conditionColor = conditionColor;
      _diagnosis = diagnosis;
      _possibleCauses = causes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inputPressureController.text = '100';
    _leakageController.clear();
    setState(() { _leakagePercent = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Cylinder Leakdown', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PRESSURE READINGS'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Input Pressure', unit: 'psi', hint: 'Regulated input', controller: _inputPressureController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Pressure Lost', unit: 'psi', hint: 'Leakage reading', controller: _leakageController, onChanged: (_) => _calculate()),
              const SizedBox(height: 24),
              _buildLeakSourceGuide(colors),
              const SizedBox(height: 32),
              if (_leakagePercent != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('Leakage % = (Pressure Lost / Input) x 100', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Cylinder leakdown test measures sealing integrity', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLeakSourceGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEAK SOURCE IDENTIFICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildLeakSourceRow(colors, 'Air at exhaust pipe', 'Exhaust valve leak'),
          _buildLeakSourceRow(colors, 'Air at intake/carb', 'Intake valve leak'),
          _buildLeakSourceRow(colors, 'Air at oil filler', 'Piston ring leak'),
          _buildLeakSourceRow(colors, 'Bubbles in coolant', 'Head gasket leak'),
          _buildLeakSourceRow(colors, 'Air at adjacent cyl', 'Head gasket between cyls'),
        ],
      ),
    );
  }

  Widget _buildLeakSourceRow(ZaftoColors colors, String symptom, String cause) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, size: 14, color: colors.textTertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(symptom, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Text(cause, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_conditionColor) {
      case 'green':
        statusColor = Colors.green;
        break;
      case 'yellow':
        statusColor = Colors.amber;
        break;
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          _buildResultRow(colors, 'Leakage', '${_leakagePercent!.toStringAsFixed(1)}%', isPrimary: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Condition', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_condition!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text('Diagnosis', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_diagnosis!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (_possibleCauses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Possible Causes:', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ..._possibleCauses.map((cause) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(LucideIcons.chevronRight, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildReferenceScale(colors),
        ],
      ),
    );
  }

  Widget _buildReferenceScale(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REFERENCE SCALE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildScaleItem(colors, '0-5%', 'Excellent', Colors.green),
            _buildScaleItem(colors, '5-10%', 'Good', Colors.green),
            _buildScaleItem(colors, '10-15%', 'Fair', Colors.amber),
            _buildScaleItem(colors, '15-20%', 'Poor', Colors.orange),
            _buildScaleItem(colors, '>20%', 'Failed', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleItem(ZaftoColors colors, String range, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(height: 4, color: color),
          const SizedBox(height: 4),
          Text(range, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
