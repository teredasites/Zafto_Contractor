import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wall Cap Calculator - Caps for retaining/garden walls
class WallCapScreen extends ConsumerStatefulWidget {
  const WallCapScreen({super.key});
  @override
  ConsumerState<WallCapScreen> createState() => _WallCapScreenState();
}

class _WallCapScreenState extends ConsumerState<WallCapScreen> {
  final _lengthController = TextEditingController(text: '50');

  String _capType = 'standard';
  double _wasteFactor = 10;

  int? _capsNeeded;
  double? _adhesiveTubes;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;

    // Cap length by type (inches)
    double capLengthIn;
    switch (_capType) {
      case 'standard': capLengthIn = 12; break;
      case 'large': capLengthIn = 18; break;
      case 'natural': capLengthIn = 24; break; // Average for irregular
      default: capLengthIn = 12;
    }

    final lengthInches = length * 12;
    final baseCaps = (lengthInches / capLengthIn).ceil();
    final capsWithWaste = (baseCaps * (1 + _wasteFactor / 100)).ceil();

    // Adhesive: 1 tube per ~20 linear feet
    final adhesiveTubes = length / 20;

    setState(() {
      _capsNeeded = capsWithWaste;
      _adhesiveTubes = adhesiveTubes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; setState(() { _capType = 'standard'; _wasteFactor = 10; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wall Caps', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'CAP TYPE', ['standard', 'large', 'natural'], _capType, {'standard': '12" Block', 'large': '18" Block', 'natural': 'Natural Stone'}, (v) { setState(() => _capType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Wall Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 5, max: 15, divisions: 2, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_capsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CAPS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Adhesive tubes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_adhesiveTubes!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCapGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCapGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Adhesive', 'Landscape block adhesive'),
        _buildTableRow(colors, 'Coverage', '~20 lin ft per tube'),
        _buildTableRow(colors, 'Overhang', '1" front overhang typical'),
        _buildTableRow(colors, 'Cuts', 'Diamond blade saw'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
