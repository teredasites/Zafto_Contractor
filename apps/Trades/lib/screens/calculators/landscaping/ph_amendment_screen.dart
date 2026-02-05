import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// pH Amendment Calculator - Lime or sulfur application
class PhAmendmentScreen extends ConsumerStatefulWidget {
  const PhAmendmentScreen({super.key});
  @override
  ConsumerState<PhAmendmentScreen> createState() => _PhAmendmentScreenState();
}

class _PhAmendmentScreenState extends ConsumerState<PhAmendmentScreen> {
  final _currentPhController = TextEditingController(text: '5.5');
  final _targetPhController = TextEditingController(text: '6.5');
  final _areaController = TextEditingController(text: '1000');

  String _soilType = 'loam';

  String? _amendment;
  double? _lbsPerK;
  double? _totalLbs;
  double? _bagsNeeded;

  @override
  void dispose() { _currentPhController.dispose(); _targetPhController.dispose(); _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final currentPh = double.tryParse(_currentPhController.text) ?? 5.5;
    final targetPh = double.tryParse(_targetPhController.text) ?? 6.5;
    final area = double.tryParse(_areaController.text) ?? 1000;

    final phDiff = targetPh - currentPh;

    String amendment;
    double lbsPerK;
    double bagSize;

    if (phDiff > 0) {
      // Need to raise pH - use lime
      amendment = 'Pelletized Lime';
      // Lime rates vary by soil type (lbs per 1000 sq ft to raise 1 pH point)
      double baseRate;
      switch (_soilType) {
        case 'sandy':
          baseRate = 25;
          break;
        case 'loam':
          baseRate = 50;
          break;
        case 'clay':
          baseRate = 75;
          break;
        default:
          baseRate = 50;
      }
      lbsPerK = baseRate * phDiff;
      bagSize = 40;
    } else if (phDiff < 0) {
      // Need to lower pH - use sulfur
      amendment = 'Eleite Sulfur';
      // Sulfur rates (lbs per 1000 sq ft to lower 1 pH point)
      double baseRate;
      switch (_soilType) {
        case 'sandy':
          baseRate = 5;
          break;
        case 'loam':
          baseRate = 10;
          break;
        case 'clay':
          baseRate = 15;
          break;
        default:
          baseRate = 10;
      }
      lbsPerK = baseRate * phDiff.abs();
      bagSize = 25;
    } else {
      setState(() {
        _amendment = null;
        _lbsPerK = null;
        _totalLbs = null;
        _bagsNeeded = null;
      });
      return;
    }

    final totalLbs = (area / 1000) * lbsPerK;
    final bags = totalLbs / bagSize;

    setState(() {
      _amendment = amendment;
      _lbsPerK = lbsPerK;
      _totalLbs = totalLbs;
      _bagsNeeded = bags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _currentPhController.text = '5.5'; _targetPhController.text = '6.5'; _areaController.text = '1000'; setState(() { _soilType = 'loam'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('pH Amendment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SOIL TYPE', ['sandy', 'loam', 'clay'], _soilType, {'sandy': 'Sandy', 'loam': 'Loam', 'clay': 'Clay'}, (v) { setState(() => _soilType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Current pH', unit: '', controller: _currentPhController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target pH', unit: '', controller: _targetPhController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Treatment Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_amendment != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_amendment!.toUpperCase(), style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_lbsPerK!.toStringAsFixed(1)} lbs/1000 sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bagsNeeded!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            if (_amendment == null && _currentPhController.text.isNotEmpty) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('pH is already at target level', style: TextStyle(color: colors.accentSuccess, fontSize: 14)),
            ),
            const SizedBox(height: 20),
            _buildPhGuide(colors),
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

  Widget _buildPhGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Max lime/app', '50 lbs/1000 sq ft'),
        _buildTableRow(colors, 'Max sulfur/app', '10 lbs/1000 sq ft'),
        _buildTableRow(colors, 'Best time', 'Fall'),
        _buildTableRow(colors, 'Retest after', '6-12 months'),
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
