import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stair Calculator - Rise, run, and stair dimensions
class StairCalculatorScreen extends ConsumerStatefulWidget {
  const StairCalculatorScreen({super.key});
  @override
  ConsumerState<StairCalculatorScreen> createState() => _StairCalculatorScreenState();
}

class _StairCalculatorScreenState extends ConsumerState<StairCalculatorScreen> {
  final _totalRiseController = TextEditingController(text: '108');
  final _availableRunController = TextEditingController(text: '144');

  String _stairType = 'interior';

  int? _numberOfRisers;
  double? _riserHeight;
  double? _treadDepth;
  double? _totalRun;
  String? _codeCompliance;

  @override
  void dispose() { _totalRiseController.dispose(); _availableRunController.dispose(); super.dispose(); }

  void _calculate() {
    final totalRiseInches = double.tryParse(_totalRiseController.text);
    final availableRunInches = double.tryParse(_availableRunController.text);

    if (totalRiseInches == null) {
      setState(() { _numberOfRisers = null; _riserHeight = null; _treadDepth = null; _totalRun = null; _codeCompliance = null; });
      return;
    }

    // Target riser height based on type
    double targetRiser;
    double minTread;
    double maxRiser;

    switch (_stairType) {
      case 'interior':
        targetRiser = 7.5;
        minTread = 10.0;
        maxRiser = 7.75;
        break;
      case 'exterior':
        targetRiser = 7.0;
        minTread = 11.0;
        maxRiser = 7.75;
        break;
      case 'deck':
        targetRiser = 7.5;
        minTread = 10.0;
        maxRiser = 7.75;
        break;
      default:
        targetRiser = 7.5;
        minTread = 10.0;
        maxRiser = 7.75;
    }

    // Calculate number of risers
    final numberOfRisers = (totalRiseInches / targetRiser).round();
    final actualRiserHeight = totalRiseInches / numberOfRisers;

    // Treads = risers - 1
    final numberOfTreads = numberOfRisers - 1;

    // Calculate tread depth
    double treadDepth;
    if (availableRunInches != null && availableRunInches > 0) {
      treadDepth = availableRunInches / numberOfTreads;
    } else {
      // Use 2R + T = 25" rule
      treadDepth = 25 - (2 * actualRiserHeight);
    }

    final totalRun = treadDepth * numberOfTreads;

    // Check code compliance
    String compliance;
    final sum = (2 * actualRiserHeight) + treadDepth;
    if (actualRiserHeight > maxRiser) {
      compliance = 'FAIL: Riser exceeds ${maxRiser}" max';
    } else if (treadDepth < minTread) {
      compliance = 'FAIL: Tread under ${minTread.toStringAsFixed(0)}" min';
    } else if (sum < 24 || sum > 26) {
      compliance = 'WARNING: 2R+T = ${sum.toStringAsFixed(1)}" (ideal: 24-26)';
    } else {
      compliance = 'PASS: Meets IRC requirements';
    }

    setState(() {
      _numberOfRisers = numberOfRisers;
      _riserHeight = actualRiserHeight;
      _treadDepth = treadDepth;
      _totalRun = totalRun;
      _codeCompliance = compliance;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _totalRiseController.text = '108'; _availableRunController.text = '144'; setState(() => _stairType = 'interior'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stair Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STAIR TYPE', ['interior', 'exterior', 'deck'], _stairType, (v) { setState(() => _stairType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _totalRiseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Available Run', unit: 'inches', controller: _availableRunController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_numberOfRisers != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RISERS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_numberOfRisers', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Riser Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_riserHeight!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tread Depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_treadDepth!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Run', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalRun!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Treads', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_numberOfRisers! - 1}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _codeCompliance!.startsWith('PASS')
                        ? colors.accentSuccess.withValues(alpha: 0.1)
                        : _codeCompliance!.startsWith('WARNING')
                            ? colors.accentWarning.withValues(alpha: 0.1)
                            : colors.accentError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_codeCompliance!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'interior': 'Interior', 'exterior': 'Exterior', 'deck': 'Deck'};
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
