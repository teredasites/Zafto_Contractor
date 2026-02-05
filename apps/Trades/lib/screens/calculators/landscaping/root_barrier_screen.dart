import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Root Barrier Calculator - Linear feet needed
class RootBarrierScreen extends ConsumerStatefulWidget {
  const RootBarrierScreen({super.key});
  @override
  ConsumerState<RootBarrierScreen> createState() => _RootBarrierScreenState();
}

class _RootBarrierScreenState extends ConsumerState<RootBarrierScreen> {
  final _lengthController = TextEditingController(text: '30');

  String _barrierDepth = '24';

  double? _linearFt;
  double? _rollsNeeded;
  String? _application;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final depth = int.tryParse(_barrierDepth) ?? 24;

    // Standard roll: 24" or 36" × 100'
    final rollLength = 100.0;
    final rolls = length / rollLength;

    String application;
    switch (depth) {
      case 18:
        application = 'Small trees, shrubs';
        break;
      case 24:
        application = 'Medium trees, bamboo';
        break;
      case 36:
        application = 'Large trees, aggressive roots';
        break;
      default:
        application = 'General use';
    }

    setState(() {
      _linearFt = length;
      _rollsNeeded = rolls;
      _application = application;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; setState(() { _barrierDepth = '24'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Root Barrier', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BARRIER DEPTH', ['18', '24', '36'], _barrierDepth, {'18': '18\"', '24': '24\"', '36': '36\"'}, (v) { setState(() => _barrierDepth = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Linear Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linearFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BARRIER NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFt!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('100\' rolls', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rollsNeeded!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Best for', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_application', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBarrierGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildBarrierGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Leave exposed', '1-2\" above grade'),
        _buildTableRow(colors, 'Overlap seams', '12\"'),
        _buildTableRow(colors, 'Distance from tree', '3-5 ft'),
        _buildTableRow(colors, 'Bamboo barrier', '30\"+ depth'),
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
