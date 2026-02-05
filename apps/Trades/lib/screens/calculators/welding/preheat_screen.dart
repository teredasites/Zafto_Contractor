import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Preheat Calculator - Minimum preheat temperature
class PreheatScreen extends ConsumerStatefulWidget {
  const PreheatScreen({super.key});
  @override
  ConsumerState<PreheatScreen> createState() => _PreheatScreenState();
}

class _PreheatScreenState extends ConsumerState<PreheatScreen> {
  final _thicknessController = TextEditingController();
  final _carbonController = TextEditingController(text: '0.25');
  final _ambientController = TextEditingController(text: '70');
  String _material = 'Carbon Steel';
  bool _highRestraint = false;
  bool _lowHydrogen = true;

  int? _preheatTemp;
  String? _codeReference;
  String? _notes;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final carbon = double.tryParse(_carbonController.text) ?? 0.25;
    final ambient = double.tryParse(_ambientController.text) ?? 70;

    if (thickness == null || thickness <= 0) {
      setState(() { _preheatTemp = null; });
      return;
    }

    int preheat;
    String codeRef;
    String notes;

    if (_material == 'Carbon Steel') {
      // AWS D1.1 based preheat
      if (thickness <= 0.75 && carbon <= 0.30) {
        preheat = 50; // Minimum practical
        codeRef = 'AWS D1.1 Table 3.2';
      } else if (thickness <= 1.5 && carbon <= 0.30) {
        preheat = 150;
        codeRef = 'AWS D1.1 Table 3.2';
      } else if (thickness <= 2.5) {
        preheat = 225;
        codeRef = 'AWS D1.1 Table 3.2';
      } else {
        preheat = 300;
        codeRef = 'AWS D1.1 Table 3.2';
      }

      // Carbon equivalent adjustment
      if (carbon > 0.35) {
        preheat += 50;
        notes = 'High carbon - increased preheat recommended';
      } else if (carbon > 0.30) {
        preheat += 25;
        notes = 'Moderate carbon content';
      } else {
        notes = 'Standard carbon steel preheat';
      }
    } else if (_material == 'Low Alloy') {
      preheat = 250 + (thickness * 50).round();
      preheat = preheat.clamp(200, 400);
      codeRef = 'AWS D1.1 / ASME';
      notes = 'Low alloy requires consistent preheat';
    } else {
      // Stainless/other
      preheat = 0;
      codeRef = 'Material specific';
      notes = 'Austenitic stainless typically no preheat';
    }

    // Restraint adjustment
    if (_highRestraint) {
      preheat += 50;
      notes = '${notes ?? ""} (+50F for high restraint)';
    }

    // Non-low hydrogen electrode adjustment
    if (!_lowHydrogen && _material == 'Carbon Steel') {
      preheat += 50;
      notes = '${notes ?? ""} (+50F for non-low H2)';
    }

    // Never below ambient
    if (preheat < ambient.round()) {
      preheat = ambient.round();
    }

    setState(() {
      _preheatTemp = preheat;
      _codeReference = codeRef;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _carbonController.text = '0.25';
    _ambientController.text = '70';
    setState(() { _preheatTemp = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _carbonController.dispose();
    _ambientController.dispose();
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
        title: Text('Preheat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Thickest section', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Carbon Content', unit: '%', hint: '0.25 typical', controller: _carbonController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ambient Temp', unit: 'F', hint: 'Shop temperature', controller: _ambientController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildOptions(colors),
            const SizedBox(height: 32),
            if (_preheatTemp != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Carbon Steel', 'Low Alloy', 'Stainless'];
    return Wrap(
      spacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildOptions(ZaftoColors colors) {
    return Column(children: [
      CheckboxListTile(
        title: Text('High Restraint Joint', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        value: _highRestraint,
        onChanged: (v) => setState(() { _highRestraint = v ?? false; _calculate(); }),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      CheckboxListTile(
        title: Text('Low Hydrogen Electrode', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        value: _lowHydrogen,
        onChanged: (v) => setState(() { _lowHydrogen = v ?? true; _calculate(); }),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Preheat Temperature', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Based on AWS D1.1 requirements', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Min Preheat', '$_preheatTemp\u00B0F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${((_preheatTemp! - 32) * 5 / 9).round()}\u00B0C'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Reference', _codeReference!),
        if (_notes != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
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
