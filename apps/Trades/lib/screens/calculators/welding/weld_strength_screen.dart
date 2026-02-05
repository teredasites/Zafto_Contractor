import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weld Strength Calculator - Fillet weld capacity
class WeldStrengthScreen extends ConsumerStatefulWidget {
  const WeldStrengthScreen({super.key});
  @override
  ConsumerState<WeldStrengthScreen> createState() => _WeldStrengthScreenState();
}

class _WeldStrengthScreenState extends ConsumerState<WeldStrengthScreen> {
  final _legSizeController = TextEditingController();
  final _weldLengthController = TextEditingController();
  String _electrodeStrength = 'E70';
  String _loadType = 'Shear';

  double? _allowableLoad;
  double? _throatArea;
  double? _loadPerInch;
  String? _notes;

  // Electrode tensile strengths (ksi)
  static const Map<String, double> _electrodeStrengths = {
    'E60': 60,
    'E70': 70,
    'E80': 80,
    'E90': 90,
    'E100': 100,
    'E110': 110,
  };

  void _calculate() {
    final legSize = double.tryParse(_legSizeController.text);
    final weldLength = double.tryParse(_weldLengthController.text);

    if (legSize == null || legSize <= 0) {
      setState(() { _allowableLoad = null; });
      return;
    }

    final tensile = _electrodeStrengths[_electrodeStrength] ?? 70;

    // Effective throat = leg × 0.707
    final throat = legSize * 0.707;

    // AWS D1.1 allowable shear stress on filler = 0.30 × tensile
    final allowableShearStress = 0.30 * tensile;

    // Load per inch of weld
    final loadPerInch = throat * allowableShearStress; // kips per inch

    double totalLoad;
    double? throatArea;
    String notes;

    if (weldLength != null && weldLength > 0) {
      throatArea = throat * weldLength;
      totalLoad = loadPerInch * weldLength;
      notes = 'Total capacity for ${weldLength.toStringAsFixed(1)}" of weld';
    } else {
      totalLoad = loadPerInch;
      notes = 'Capacity per linear inch of weld';
    }

    if (_loadType == 'Tension') {
      // Tension perpendicular is more restrictive
      totalLoad *= 0.85;
      notes = '$notes (tension factor applied)';
    }

    setState(() {
      _allowableLoad = totalLoad;
      _throatArea = throatArea;
      _loadPerInch = loadPerInch;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _legSizeController.clear();
    _weldLengthController.clear();
    setState(() { _allowableLoad = null; });
  }

  @override
  void dispose() {
    _legSizeController.dispose();
    _weldLengthController.dispose();
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
        title: Text('Weld Strength', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Electrode Strength', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildElectrodeSelector(colors),
            const SizedBox(height: 16),
            Text('Load Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildLoadSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Leg Size', unit: 'in', hint: 'Fillet leg dimension', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Weld Length', unit: 'in', hint: 'Optional - total length', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_allowableLoad != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildElectrodeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _electrodeStrengths.keys.map((e) => ChoiceChip(
        label: Text(e),
        selected: _electrodeStrength == e,
        onSelected: (_) => setState(() { _electrodeStrength = e; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildLoadSelector(ZaftoColors colors) {
    final types = ['Shear', 'Tension'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _loadType == t,
        onSelected: (_) => setState(() { _loadType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('P = 0.707 x Leg x L x Fv', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Fillet weld allowable load (AWS D1.1)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Allowable Load', '${_allowableLoad!.toStringAsFixed(2)} kips', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Per Inch', '${_loadPerInch!.toStringAsFixed(2)} kips/in'),
        if (_throatArea != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Throat Area', '${_throatArea!.toStringAsFixed(3)} sq in'),
        ],
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
