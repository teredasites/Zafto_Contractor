import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Soffit Calculator - Soffit materials for eaves
class SoffitScreen extends ConsumerStatefulWidget {
  const SoffitScreen({super.key});
  @override
  ConsumerState<SoffitScreen> createState() => _SoffitScreenState();
}

class _SoffitScreenState extends ConsumerState<SoffitScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _widthController = TextEditingController(text: '12');

  String _soffitType = 'vinyl';
  String _ventType = 'vented';

  double? _soffitArea;
  int? _panelsNeeded;
  int? _jChannelLF;
  int? _fChannelLF;

  @override
  void dispose() { _perimeterController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final widthInches = double.tryParse(_widthController.text);

    if (perimeter == null || widthInches == null) {
      setState(() { _soffitArea = null; _panelsNeeded = null; _jChannelLF = null; _fChannelLF = null; });
      return;
    }

    final widthFeet = widthInches / 12;
    final soffitArea = perimeter * widthFeet;

    // Soffit panels vary by type
    // Vinyl: 12' x 1' = 12 sq ft per panel
    // Aluminum: 12' x 1' = 12 sq ft
    // Wood/plywood: 4' x 8' = 32 sq ft
    double panelCoverage;
    switch (_soffitType) {
      case 'vinyl': panelCoverage = 12; break;
      case 'aluminum': panelCoverage = 12; break;
      case 'wood': panelCoverage = 32; break;
      case 'fiber': panelCoverage = 16; break; // Fiber cement 4x4
      default: panelCoverage = 12;
    }

    // Add 10% waste
    final panelsNeeded = ((soffitArea / panelCoverage) * 1.10).ceil();

    // J-channel at wall edge
    final jChannelLF = perimeter.ceil();

    // F-channel or frieze at fascia edge
    final fChannelLF = perimeter.ceil();

    setState(() { _soffitArea = soffitArea; _panelsNeeded = panelsNeeded; _jChannelLF = jChannelLF; _fChannelLF = fChannelLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _widthController.text = '12'; setState(() { _soffitType = 'vinyl'; _ventType = 'vented'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Soffit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SOFFIT TYPE', ['vinyl', 'aluminum', 'wood', 'fiber'], _soffitType, (v) { setState(() => _soffitType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'VENTILATION', ['vented', 'solid', 'center'], _ventType, (v) { setState(() => _ventType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Eave Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Soffit Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_panelsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PANELS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_panelsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Soffit Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soffitArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('J-Channel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_jChannelLF LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('F-Channel/Frieze', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fChannelLF LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getVentNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getVentNote() {
    switch (_ventType) {
      case 'vented': return 'Fully vented soffit: 1 sq ft NFA per 150 sq ft attic. Use with ridge vents.';
      case 'solid': return 'Solid soffit: Use only with gable vents or when attic has other ventilation.';
      case 'center': return 'Center vent strip: Combines appearance of solid with ventilation. 3" vent strip.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'vinyl': 'Vinyl', 'aluminum': 'Aluminum', 'wood': 'Wood', 'fiber': 'Fiber', 'vented': 'Vented', 'solid': 'Solid', 'center': 'Center Vent'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
