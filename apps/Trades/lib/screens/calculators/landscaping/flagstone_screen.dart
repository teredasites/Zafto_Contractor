import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flagstone Calculator - Coverage and tons
class FlagstoneScreen extends ConsumerStatefulWidget {
  const FlagstoneScreen({super.key});
  @override
  ConsumerState<FlagstoneScreen> createState() => _FlagstoneScreenState();
}

class _FlagstoneScreenState extends ConsumerState<FlagstoneScreen> {
  final _areaController = TextEditingController(text: '200');

  String _thickness = '1.5';
  String _pattern = 'tight';
  double _wasteFactor = 15;

  double? _sqFtNeeded;
  double? _tons;
  double? _sandTons;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 200;
    final thickness = double.tryParse(_thickness) ?? 1.5;

    // Coverage factor for gaps
    double coverageFactor;
    switch (_pattern) {
      case 'tight': coverageFactor = 0.95; break;
      case 'standard': coverageFactor = 0.85; break;
      case 'wide': coverageFactor = 0.75; break;
      default: coverageFactor = 0.85;
    }

    final sqFtNeeded = area / coverageFactor * (1 + _wasteFactor / 100);

    // Weight: ~15 lbs per sq ft per inch of thickness
    final lbsPerSqFt = 15 * thickness;
    final totalLbs = sqFtNeeded * lbsPerSqFt;
    final tons = totalLbs / 2000;

    // Sand: 1" bed, 100 lbs per sq ft
    final sandLbs = area * 0.5; // ~0.5 lbs per sq ft for bedding
    final sandTons = sandLbs / 2000;

    setState(() {
      _sqFtNeeded = sqFtNeeded;
      _tons = tons;
      _sandTons = sandTons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '200'; setState(() { _thickness = '1.5'; _pattern = 'standard'; _wasteFactor = 15; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Flagstone', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'THICKNESS', ['1', '1.5', '2'], _thickness, {'1': '1"', '1.5': '1.5"', '2': '2"'}, (v) { setState(() => _thickness = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'JOINT SPACING', ['tight', 'standard', 'wide'], _pattern, {'tight': 'Tight (0.5")', 'standard': 'Standard (1")', 'wide': 'Wide (2"+)'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Patio/Walkway Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Text('Waste factor:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Expanded(child: Slider(value: _wasteFactor, min: 10, max: 25, divisions: 3, label: '${_wasteFactor.toInt()}%', onChanged: (v) { setState(() => _wasteFactor = v); _calculate(); })),
              Text('${_wasteFactor.toInt()}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 24),
            if (_sqFtNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FLAGSTONE NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqFtNeeded!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sand bedding', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_sandTons! * 2000).toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
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

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'On sand', '1-2" leveling sand'),
        _buildTableRow(colors, 'On concrete', 'Mortar bed'),
        _buildTableRow(colors, 'Joint fill', 'Polymeric sand or gravel'),
        _buildTableRow(colors, 'Coverage', '~80-120 sq ft/ton'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
