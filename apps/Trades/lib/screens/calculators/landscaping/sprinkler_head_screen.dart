import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sprinkler Head Calculator - Coverage and GPM
class SprinklerHeadScreen extends ConsumerStatefulWidget {
  const SprinklerHeadScreen({super.key});
  @override
  ConsumerState<SprinklerHeadScreen> createState() => _SprinklerHeadScreenState();
}

class _SprinklerHeadScreenState extends ConsumerState<SprinklerHeadScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');

  String _headType = 'rotor';
  String _pattern = 'full';

  int? _headsNeeded;
  double? _totalGpm;
  double? _spacing;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final width = double.tryParse(_widthController.text) ?? 30;

    // Throw radius and GPM by head type
    double radius;
    double gpmPerHead;
    switch (_headType) {
      case 'rotor':
        radius = 35; // 35 ft throw
        gpmPerHead = 3.0;
        break;
      case 'spray':
        radius = 15; // 15 ft throw
        gpmPerHead = 1.5;
        break;
      case 'impact':
        radius = 45; // 45 ft throw
        gpmPerHead = 4.0;
        break;
      case 'mp':
        radius = 30; // MP Rotator
        gpmPerHead = 0.9;
        break;
      default:
        radius = 35;
        gpmPerHead = 3.0;
    }

    // Pattern adjustment
    double patternFactor;
    switch (_pattern) {
      case 'full': patternFactor = 1.0; break;
      case 'half': patternFactor = 0.5; break;
      case 'quarter': patternFactor = 0.25; break;
      default: patternFactor = 1.0;
    }

    // Head-to-head coverage (50% overlap)
    final spacing = radius;
    final headsAlongLength = (length / spacing).ceil() + 1;
    final headsAlongWidth = (width / spacing).ceil() + 1;
    final totalHeads = headsAlongLength * headsAlongWidth;

    // Adjust GPM for pattern
    final totalGpm = totalHeads * gpmPerHead * patternFactor;

    setState(() {
      _headsNeeded = totalHeads;
      _totalGpm = totalGpm;
      _spacing = spacing;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; setState(() { _headType = 'rotor'; _pattern = 'full'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sprinkler Heads', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HEAD TYPE', ['rotor', 'spray', 'impact', 'mp'], _headType, {'rotor': 'Rotor', 'spray': 'Spray', 'impact': 'Impact', 'mp': 'MP Rotator'}, (v) { setState(() => _headType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN', ['full', 'half', 'quarter'], _pattern, {'full': '360°', 'half': '180°', 'quarter': '90°'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_headsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('HEADS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_headsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total GPM', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalGpm!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Head spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_spacing!.toStringAsFixed(0)}' x ${_spacing!.toStringAsFixed(0)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(double.tryParse(_lengthController.text) ?? 50) * (double.tryParse(_widthController.text) ?? 30)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildHeadSpecs(colors),
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

  Widget _buildHeadSpecs(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEAD SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Rotor', "25-45' throw, 2-4 GPM"),
        _buildTableRow(colors, 'Spray', "8-15' throw, 1-2 GPM"),
        _buildTableRow(colors, 'Impact', "40-50' throw, 3-5 GPM"),
        _buildTableRow(colors, 'MP Rotator', "15-35' throw, 0.5-1.5 GPM"),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
