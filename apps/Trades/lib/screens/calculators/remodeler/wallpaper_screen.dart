import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wallpaper Calculator - Wallpaper roll estimation
class WallpaperScreen extends ConsumerStatefulWidget {
  const WallpaperScreen({super.key});
  @override
  ConsumerState<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends ConsumerState<WallpaperScreen> {
  final _perimeterController = TextEditingController(text: '48');
  final _heightController = TextEditingController(text: '8');
  final _doorsController = TextEditingController(text: '1');
  final _windowsController = TextEditingController(text: '2');

  String _rollType = 'single';
  String _pattern = 'random';

  double? _wallSqft;
  int? _singleRolls;
  int? _doubleRolls;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;

    var wallSqft = perimeter * height;

    // Subtract openings
    wallSqft -= (doors * 21) + (windows * 15);
    if (wallSqft < 0) wallSqft = 0;

    // Pattern match waste factor
    double wasteFactor;
    switch (_pattern) {
      case 'random':
        wasteFactor = 1.10; // 10% waste
        break;
      case 'straight':
        wasteFactor = 1.15; // 15% waste
        break;
      case 'drop':
        wasteFactor = 1.20; // 20% waste
        break;
      default:
        wasteFactor = 1.15;
    }

    final adjustedSqft = wallSqft * wasteFactor;

    // Single roll = ~30 sqft usable, Double roll = ~60 sqft usable
    final singleRolls = (adjustedSqft / 30).ceil();
    final doubleRolls = (adjustedSqft / 60).ceil();

    setState(() { _wallSqft = wallSqft; _singleRolls = singleRolls; _doubleRolls = doubleRolls; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '48'; _heightController.text = '8'; _doorsController.text = '1'; _windowsController.text = '2'; setState(() { _rollType = 'single'; _pattern = 'random'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wallpaper', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'ROLL SIZE', ['single', 'double'], _rollType, {'single': 'Single Roll', 'double': 'Double Roll'}, (v) { setState(() => _rollType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN MATCH', ['random', 'straight', 'drop'], _pattern, {'random': 'Random', 'straight': 'Straight', 'drop': 'Drop Match'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_wallSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROLLS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_rollType == 'single' ? '$_singleRolls' : '$_doubleRolls', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Single Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_singleRolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Double Rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_doubleRolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Buy extra for repairs. Check all rolls have same dye lot number before starting.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRollTable(colors),
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

  Widget _buildRollTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROLL SIZES (US STANDARD)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Single roll', '27\" x 27\' (~33 sqft)'),
        _buildTableRow(colors, 'Double roll', '27\" x 54\' (~66 sqft)'),
        _buildTableRow(colors, 'Euro roll', '20.5\" x 33\' (~56 sqft)'),
        _buildTableRow(colors, 'Usable coverage', '~85-90% of roll'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
