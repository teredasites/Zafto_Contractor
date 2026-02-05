import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lime Calculator - pH adjustment
class LimeScreen extends ConsumerStatefulWidget {
  const LimeScreen({super.key});
  @override
  ConsumerState<LimeScreen> createState() => _LimeScreenState();
}

class _LimeScreenState extends ConsumerState<LimeScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _currentPhController = TextEditingController(text: '5.5');
  final _targetPhController = TextEditingController(text: '6.5');

  String _soilType = 'loam';

  double? _limeLbs;
  int? _bags40lb;

  @override
  void dispose() { _areaController.dispose(); _currentPhController.dispose(); _targetPhController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final currentPh = double.tryParse(_currentPhController.text) ?? 5.5;
    final targetPh = double.tryParse(_targetPhController.text) ?? 6.5;

    final phChange = targetPh - currentPh;
    if (phChange <= 0) {
      setState(() { _limeLbs = null; });
      return;
    }

    // Lbs of lime per 1000 sq ft per 1 pH point (varies by soil type)
    double lbsPerPhPoint;
    switch (_soilType) {
      case 'sandy': lbsPerPhPoint = 25; break;
      case 'loam': lbsPerPhPoint = 50; break;
      case 'clay': lbsPerPhPoint = 75; break;
      default: lbsPerPhPoint = 50;
    }

    final lbsPer1000 = lbsPerPhPoint * phChange;
    final totalLbs = lbsPer1000 * (area / 1000);

    setState(() {
      _limeLbs = totalLbs;
      _bags40lb = (totalLbs / 40).ceil();
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _currentPhController.text = '5.5'; _targetPhController.text = '6.5'; setState(() { _soilType = 'loam'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lime Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SOIL TYPE', ['sandy', 'loam', 'clay'], _soilType, {'sandy': 'Sandy', 'loam': 'Loam', 'clay': 'Clay'}, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Current pH', unit: '', controller: _currentPhController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target pH', unit: '', controller: _targetPhController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Most lawns prefer pH 6.0-7.0. Get a soil test for accurate pH reading.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_limeLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LIME NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_limeLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('40 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags40lb bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per 1000 sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_limeLbs! / (double.tryParse(_areaController.text) ?? 5000) * 1000).toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Apply max 50 lbs/1000 sq ft per application. Split larger amounts.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLimeGuide(colors),
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

  Widget _buildLimeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LIME TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Calcitic', 'High calcium, standard'),
        _buildTableRow(colors, 'Dolomitic', 'Calcium + magnesium'),
        _buildTableRow(colors, 'Pelletized', 'Easy spread, fast acting'),
        _buildTableRow(colors, 'Pulverized', 'Powder, dusty, cheapest'),
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
