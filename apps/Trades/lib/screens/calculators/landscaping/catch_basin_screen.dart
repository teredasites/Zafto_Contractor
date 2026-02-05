import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Catch Basin Calculator - Drainage basin sizing
class CatchBasinScreen extends ConsumerStatefulWidget {
  const CatchBasinScreen({super.key});
  @override
  ConsumerState<CatchBasinScreen> createState() => _CatchBasinScreenState();
}

class _CatchBasinScreenState extends ConsumerState<CatchBasinScreen> {
  final _drainageAreaController = TextEditingController(text: '2000');
  final _rainfallIntensityController = TextEditingController(text: '2');

  String _surfaceType = 'lawn';

  double? _flowGpm;
  String? _recommendedSize;
  String? _pipeSize;

  @override
  void dispose() { _drainageAreaController.dispose(); _rainfallIntensityController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_drainageAreaController.text) ?? 2000;
    final rainfallIn = double.tryParse(_rainfallIntensityController.text) ?? 2;

    // Runoff coefficient
    double coefficient;
    switch (_surfaceType) {
      case 'lawn':
        coefficient = 0.35;
        break;
      case 'gravel':
        coefficient = 0.5;
        break;
      case 'pavement':
        coefficient = 0.9;
        break;
      case 'roof':
        coefficient = 0.95;
        break;
      default:
        coefficient = 0.35;
    }

    // Q = C × I × A (rational method)
    // Q in cu ft/sec, I in in/hr, A in acres
    final areaAcres = area / 43560;
    final flowCfs = coefficient * rainfallIn * areaAcres;
    final flowGpm = flowCfs * 448.8;

    // Recommend basin size
    String basinSize;
    String pipeSize;
    if (flowGpm < 30) {
      basinSize = '9\" round';
      pipeSize = '3\" pipe';
    } else if (flowGpm < 75) {
      basinSize = '12\" square';
      pipeSize = '4\" pipe';
    } else if (flowGpm < 150) {
      basinSize = '18\" square';
      pipeSize = '6\" pipe';
    } else {
      basinSize = '24\"+ square';
      pipeSize = '8\"+ pipe';
    }

    setState(() {
      _flowGpm = flowGpm;
      _recommendedSize = basinSize;
      _pipeSize = pipeSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _drainageAreaController.text = '2000'; _rainfallIntensityController.text = '2'; setState(() { _surfaceType = 'lawn'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Catch Basin', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SURFACE TYPE', ['lawn', 'gravel', 'pavement', 'roof'], _surfaceType, {'lawn': 'Lawn', 'gravel': 'Gravel', 'pavement': 'Paved', 'roof': 'Roof'}, (v) { setState(() => _surfaceType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Drainage Area', unit: 'sq ft', controller: _drainageAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rainfall Intensity', unit: 'in/hr', controller: _rainfallIntensityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_flowGpm != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BASIN SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_recommendedSize', style: TextStyle(color: colors.accentPrimary, fontSize: 22, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Peak flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_flowGpm!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Outlet pipe', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pipeSize', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBasinGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildBasinGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RUNOFF COEFFICIENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Lawn', '0.30-0.40'),
        _buildTableRow(colors, 'Gravel', '0.45-0.55'),
        _buildTableRow(colors, 'Pavement', '0.85-0.95'),
        _buildTableRow(colors, 'Roof', '0.90-0.95'),
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
