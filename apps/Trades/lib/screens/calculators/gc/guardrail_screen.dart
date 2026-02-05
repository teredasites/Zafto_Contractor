import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Guardrail Calculator - Protective guardrail systems
class GuardrailScreen extends ConsumerStatefulWidget {
  const GuardrailScreen({super.key});
  @override
  ConsumerState<GuardrailScreen> createState() => _GuardrailScreenState();
}

class _GuardrailScreenState extends ConsumerState<GuardrailScreen> {
  final _linearFeetController = TextEditingController(text: '40');
  final _heightController = TextEditingController(text: '36');

  String _guardrailType = 'residential';
  String _infillType = 'baluster';

  int? _postsNeeded;
  double? _topRailLF;
  int? _infillCount;
  int? _midRails;

  @override
  void dispose() { _linearFeetController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final heightInches = double.tryParse(_heightController.text);

    if (linearFeet == null || heightInches == null) {
      setState(() { _postsNeeded = null; _topRailLF = null; _infillCount = null; _midRails = null; });
      return;
    }

    // Post spacing based on type
    double postSpacing;
    switch (_guardrailType) {
      case 'residential': postSpacing = 6; break;  // 6' typical
      case 'commercial': postSpacing = 5; break;  // 5' for strength
      case 'industrial': postSpacing = 8; break;  // With mid-rail
      default: postSpacing = 6;
    }

    final postsNeeded = (linearFeet / postSpacing).ceil() + 1;
    final topRailLF = linearFeet;

    // Infill based on type
    int infillCount;
    int midRails;
    switch (_infillType) {
      case 'baluster':
        // 4" max sphere spacing = ~3 balusters per foot
        infillCount = (linearFeet * 3).ceil();
        midRails = 0;
        break;
      case 'cable':
        // Cables at 3" spacing
        infillCount = (heightInches / 3).ceil();
        midRails = 0;
        break;
      case 'glass':
        // Glass panels between posts
        infillCount = postsNeeded - 1;
        midRails = 0;
        break;
      case 'midrail':
        // Industrial style with mid-rail only (not residential)
        infillCount = 0;
        midRails = postsNeeded - 1;
        break;
      default:
        infillCount = (linearFeet * 3).ceil();
        midRails = 0;
    }

    setState(() { _postsNeeded = postsNeeded; _topRailLF = topRailLF; _infillCount = infillCount; _midRails = midRails; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _linearFeetController.text = '40'; _heightController.text = '36'; setState(() { _guardrailType = 'residential'; _infillType = 'baluster'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Guardrail', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['residential', 'commercial', 'industrial'], _guardrailType, (v) { setState(() => _guardrailType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'INFILL TYPE', ['baluster', 'cable', 'glass', 'midrail'], _infillType, (v) { setState(() => _infillType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Linear Feet', unit: 'ft', controller: _linearFeetController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_postsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('POSTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_postsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Top Rail', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_topRailLF!.toStringAsFixed(0)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                if (_infillType != 'midrail')
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_getInfillLabel(), style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_infillCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if ((_midRails ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mid-Rails', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_midRails sections', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getGuardrailNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getInfillLabel() {
    switch (_infillType) {
      case 'baluster': return 'Balusters';
      case 'cable': return 'Cable Runs';
      case 'glass': return 'Glass Panels';
      default: return 'Infill';
    }
  }

  String _getGuardrailNote() {
    switch (_guardrailType) {
      case 'residential': return 'IRC: 36" min height, 4" max sphere passage. Required when drop >30".';
      case 'commercial': return 'IBC: 42" min height, 4" max sphere passage. 200 lb point load at top.';
      case 'industrial': return 'OSHA: 42" top rail, 21" mid-rail. For employee protection only.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'residential': 'Residential', 'commercial': 'Commercial', 'industrial': 'Industrial', 'baluster': 'Baluster', 'cable': 'Cable', 'glass': 'Glass', 'midrail': 'Mid-Rail'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
