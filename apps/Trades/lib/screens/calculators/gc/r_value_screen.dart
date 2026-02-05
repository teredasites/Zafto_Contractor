import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// R-Value Calculator - Insulation R-value requirements
class RValueScreen extends ConsumerStatefulWidget {
  const RValueScreen({super.key});
  @override
  ConsumerState<RValueScreen> createState() => _RValueScreenState();
}

class _RValueScreenState extends ConsumerState<RValueScreen> {
  final _thicknessController = TextEditingController(text: '6');

  String _material = 'fiberglass_batt';
  String _application = 'wall';

  double? _totalRValue;
  double? _rPerInch;
  String? _codeRequirement;
  bool? _meetsCode;

  @override
  void dispose() { _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    if (thickness == null) {
      setState(() { _totalRValue = null; _rPerInch = null; _codeRequirement = null; _meetsCode = null; });
      return;
    }

    // R-value per inch by material
    double rPerInch;
    switch (_material) {
      case 'fiberglass_batt': rPerInch = 3.2; break;
      case 'fiberglass_blown': rPerInch = 2.5; break;
      case 'cellulose': rPerInch = 3.7; break;
      case 'mineral_wool': rPerInch = 3.3; break;
      case 'spray_open': rPerInch = 3.7; break;
      case 'spray_closed': rPerInch = 6.5; break;
      case 'xps_foam': rPerInch = 5.0; break;
      case 'polyiso': rPerInch = 6.0; break;
      default: rPerInch = 3.2;
    }

    final totalRValue = thickness * rPerInch;

    // Code requirements by application (Zone 4/5 typical)
    double codeRequired;
    switch (_application) {
      case 'wall': codeRequired = 20; break;
      case 'floor': codeRequired = 30; break;
      case 'attic': codeRequired = 49; break;
      case 'basement': codeRequired = 15; break;
      case 'crawl': codeRequired = 19; break;
      default: codeRequired = 20;
    }

    final meetsCode = totalRValue >= codeRequired;

    setState(() {
      _totalRValue = totalRValue;
      _rPerInch = rPerInch;
      _codeRequirement = 'R-${codeRequired.toStringAsFixed(0)}';
      _meetsCode = meetsCode;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _thicknessController.text = '6'; setState(() { _material = 'fiberglass_batt'; _application = 'wall'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('R-Value', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            _buildSelector(colors, 'APPLICATION', ['wall', 'floor', 'attic', 'basement'], _application, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Insulation Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalRValue != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL R-VALUE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('R-${_totalRValue!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R per Inch', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rPerInch!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Code Requirement', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_codeRequirement!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Meets Code', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_meetsCode! ? 'YES' : 'NO', style: TextStyle(color: _meetsCode! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _meetsCode! ? colors.accentSuccess.withValues(alpha: 0.1) : colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_meetsCode! ? 'Meets IECC Zone 4/5 requirements. Check local code for your zone.' : 'Below code minimum. Add more insulation or use higher R/inch material.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['fiberglass_batt', 'cellulose', 'spray_closed', 'xps_foam'];
    final labels = {'fiberglass_batt': 'FG Batt', 'cellulose': 'Cellulose', 'spray_closed': 'Spray', 'xps_foam': 'XPS'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: materials.map((o) {
        final isSelected = _material == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != materials.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'wall': 'Wall', 'floor': 'Floor', 'attic': 'Attic', 'basement': 'Basement'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
