import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Paint Coverage Calculator - Interior paint estimation
class PaintCoverageScreen extends ConsumerStatefulWidget {
  const PaintCoverageScreen({super.key});
  @override
  ConsumerState<PaintCoverageScreen> createState() => _PaintCoverageScreenState();
}

class _PaintCoverageScreenState extends ConsumerState<PaintCoverageScreen> {
  final _lengthController = TextEditingController(text: '12');
  final _widthController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '8');
  final _doorsController = TextEditingController(text: '1');
  final _windowsController = TextEditingController(text: '2');

  String _coats = '2';
  String _finish = 'eggshell';

  double? _wallSqft;
  double? _gallons;
  double? _primerGal;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final coats = int.tryParse(_coats) ?? 2;

    // Perimeter * height
    final perimeter = (length + width) * 2;
    var wallSqft = perimeter * height;

    // Subtract openings (door ~21 sqft, window ~15 sqft)
    wallSqft -= (doors * 21) + (windows * 15);
    if (wallSqft < 0) wallSqft = 0;

    // Coverage: ~350 sqft per gallon
    final gallonsPerCoat = wallSqft / 350;
    final gallons = gallonsPerCoat * coats;

    // Primer: 1 coat at 400 sqft/gal
    final primerGal = wallSqft / 400;

    setState(() { _wallSqft = wallSqft; _gallons = gallons; _primerGal = primerGal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '12'; _widthController.text = '12'; _heightController.text = '8'; _doorsController.text = '1'; _windowsController.text = '2'; setState(() { _coats = '2'; _finish = 'eggshell'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paint Coverage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Room Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COATS', ['1', '2', '3'], _coats, {'1': '1 Coat', '2': '2 Coats', '3': '3 Coats'}, (v) { setState(() => _coats = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FINISH', ['flat', 'eggshell', 'satin', 'semi'], _finish, {'flat': 'Flat', 'eggshell': 'Eggshell', 'satin': 'Satin', 'semi': 'Semi-Gloss'}, (v) { setState(() => _finish = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_wallSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PAINT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Primer (if needed)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_primerGal!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Coverage varies by color and surface. Dark colors may need 3 coats. Always prime bare drywall.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
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
}
