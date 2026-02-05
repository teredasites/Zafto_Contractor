import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spray Foam Calculator - Spray foam insulation
class SprayFoamScreen extends ConsumerStatefulWidget {
  const SprayFoamScreen({super.key});
  @override
  ConsumerState<SprayFoamScreen> createState() => _SprayFoamScreenState();
}

class _SprayFoamScreenState extends ConsumerState<SprayFoamScreen> {
  final _areaController = TextEditingController(text: '1000');
  final _thicknessController = TextEditingController(text: '3');

  String _foamType = 'closed';

  double? _boardFeet;
  double? _rValue;
  double? _costEstimate;

  @override
  void dispose() { _areaController.dispose(); _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final thickness = double.tryParse(_thicknessController.text);

    if (area == null || thickness == null) {
      setState(() { _boardFeet = null; _rValue = null; _costEstimate = null; });
      return;
    }

    // Board feet = area × thickness
    final boardFeet = area * thickness;

    // R-value per inch
    double rPerInch;
    double costPerBF;
    switch (_foamType) {
      case 'open':
        rPerInch = 3.7;
        costPerBF = 0.50;
        break;
      case 'closed':
        rPerInch = 6.5;
        costPerBF = 1.25;
        break;
      default:
        rPerInch = 6.5;
        costPerBF = 1.25;
    }

    final rValue = rPerInch * thickness;
    final costEstimate = boardFeet * costPerBF;

    setState(() { _boardFeet = boardFeet; _rValue = rValue; _costEstimate = costEstimate; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '1000'; _thicknessController.text = '3'; setState(() => _foamType = 'closed'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Spray Foam', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FOAM TYPE', ['open', 'closed'], _foamType, (v) { setState(() => _foamType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_boardFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BOARD FEET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_boardFeet!.toStringAsFixed(0)} BF', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('R-Value', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('R-${_rValue!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Material Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_costEstimate!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getFoamNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getFoamNote() {
    switch (_foamType) {
      case 'open': return 'Open cell: R-3.7/inch, vapor permeable, sound absorption. Good for interior walls.';
      case 'closed': return 'Closed cell: R-6.5/inch, vapor barrier, structural strength. Required for exterior/below grade.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'open': 'Open Cell', 'closed': 'Closed Cell'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
