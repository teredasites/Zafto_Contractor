import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ramp Calculator - ADA ramp dimensions and materials
class RampScreen extends ConsumerStatefulWidget {
  const RampScreen({super.key});
  @override
  ConsumerState<RampScreen> createState() => _RampScreenState();
}

class _RampScreenState extends ConsumerState<RampScreen> {
  final _riseController = TextEditingController(text: '30');
  final _widthController = TextEditingController(text: '48');

  String _slopeRatio = '1:12';

  double? _rampLength;
  int? _landingsNeeded;
  double? _totalLength;
  double? _deckingArea;

  @override
  void dispose() { _riseController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final riseInches = double.tryParse(_riseController.text);
    final widthInches = double.tryParse(_widthController.text);

    if (riseInches == null || widthInches == null) {
      setState(() { _rampLength = null; _landingsNeeded = null; _totalLength = null; _deckingArea = null; });
      return;
    }

    // Slope ratio determines run per inch of rise
    int runPerInchRise;
    switch (_slopeRatio) {
      case '1:12': runPerInchRise = 12; break;  // ADA max
      case '1:16': runPerInchRise = 16; break;  // Easier
      case '1:20': runPerInchRise = 20; break;  // Comfortable
      default: runPerInchRise = 12;
    }

    // Calculate run
    final runInches = riseInches * runPerInchRise;
    final rampLengthFeet = runInches / 12;

    // ADA: max 30' run between landings
    // Actually max 30" rise between landings for 1:12
    final maxRisePerRun = 30.0; // inches
    final landingsNeeded = (riseInches / maxRisePerRun).ceil() - 1;

    // Each landing is 60" x width minimum
    final landingLength = 60.0 / 12; // 5 feet
    final totalLandingLength = landingsNeeded * landingLength;

    final totalLength = rampLengthFeet + totalLandingLength;

    // Decking area (ramp + landings)
    final widthFeet = widthInches / 12;
    final deckingArea = totalLength * widthFeet;

    setState(() {
      _rampLength = rampLengthFeet;
      _landingsNeeded = landingsNeeded;
      _totalLength = totalLength;
      _deckingArea = deckingArea;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _riseController.text = '30'; _widthController.text = '48'; setState(() => _slopeRatio = '1:12'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ramp Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SLOPE RATIO', ['1:12', '1:16', '1:20'], _slopeRatio, (v) { setState(() => _slopeRatio = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Total Rise', unit: 'inches', controller: _riseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Ramp Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rampLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ramp Run', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rampLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landings Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_landingsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Decking Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_deckingArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSlopeNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getSlopeNote() {
    switch (_slopeRatio) {
      case '1:12': return 'ADA max slope: 1:12 (8.33%). Requires 36" min width, 60" landings, handrails both sides.';
      case '1:16': return '1:16 slope (6.25%): Easier for manual wheelchair users. Recommended for long ramps.';
      case '1:20': return '1:20 slope (5%): Most comfortable. May not require handrails if under 6" rise.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
