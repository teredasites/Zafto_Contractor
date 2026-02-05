import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// PWHT Calculator - Post Weld Heat Treatment parameters
class PwhtScreen extends ConsumerStatefulWidget {
  const PwhtScreen({super.key});
  @override
  ConsumerState<PwhtScreen> createState() => _PwhtScreenState();
}

class _PwhtScreenState extends ConsumerState<PwhtScreen> {
  final _thicknessController = TextEditingController();
  String _material = 'Carbon Steel';
  String _code = 'ASME';

  int? _holdTemp;
  double? _holdTime;
  int? _heatingRate;
  int? _coolingRate;
  String? _notes;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    if (thickness == null || thickness <= 0) {
      setState(() { _holdTemp = null; });
      return;
    }

    int holdTemp;
    double holdTime;
    int heatingRate;
    int coolingRate;
    String notes;

    if (_material == 'Carbon Steel') {
      holdTemp = 1100; // Typical ASME/AWS
      // 1 hour per inch, minimum 1 hour
      holdTime = (thickness * 1).clamp(1.0, 8.0);

      if (_code == 'AWS D1.1') {
        holdTemp = 1100;
        notes = 'AWS D1.1 - 1100F minimum, 1 hr/inch';
      } else {
        holdTemp = 1150;
        notes = 'ASME B31.3/VIII - 1100-1200F range';
      }
    } else if (_material == 'Low Alloy Cr-Mo') {
      holdTemp = 1275;
      holdTime = (thickness * 1).clamp(1.0, 10.0);
      notes = 'Cr-Mo steels require higher PWHT temp';
    } else if (_material == '9Cr-1Mo') {
      holdTemp = 1375;
      holdTime = (thickness * 2).clamp(2.0, 12.0);
      notes = 'P91 - critical temperature control required';
    } else {
      holdTemp = 1050;
      holdTime = (thickness * 0.5).clamp(0.5, 4.0);
      notes = 'Material-specific PWHT per code';
    }

    // Heating/cooling rates per code
    // Max 400F/hr for thickness > 2", slower for thicker
    heatingRate = thickness > 2 ? 400 : 600;
    heatingRate = (heatingRate / (thickness / 2)).round().clamp(100, 600);

    // Cooling rate typically slower
    coolingRate = (heatingRate * 0.8).round();

    setState(() {
      _holdTemp = holdTemp;
      _holdTime = holdTime;
      _heatingRate = heatingRate;
      _coolingRate = coolingRate;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _holdTemp = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('PWHT', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            Text('Code', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildCodeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Thickness', unit: 'in', hint: 'Governing thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_holdTemp != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Carbon Steel', 'Low Alloy Cr-Mo', '9Cr-1Mo', 'Other'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 11)),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildCodeSelector(ZaftoColors colors) {
    final codes = ['ASME', 'AWS D1.1', 'AWS D1.5'];
    return Wrap(
      spacing: 8,
      children: codes.map((c) => ChoiceChip(
        label: Text(c),
        selected: _code == c,
        onSelected: (_) => setState(() { _code = c; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Post Weld Heat Treatment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Stress relief and tempering parameters', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Hold Temperature', '$_holdTemp\u00B0F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hold Time', '${_holdTime!.toStringAsFixed(1)} hr'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Heat Rate', '$_heatingRate\u00B0F/hr'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Cool Rate', '$_coolingRate\u00B0F/hr'),
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
