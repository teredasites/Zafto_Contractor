import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bathtub Calculator - Tub sizing and requirements
class BathtubScreen extends ConsumerStatefulWidget {
  const BathtubScreen({super.key});
  @override
  ConsumerState<BathtubScreen> createState() => _BathtubScreenState();
}

class _BathtubScreenState extends ConsumerState<BathtubScreen> {
  final _alcoveWidthController = TextEditingController(text: '60');
  final _floorLoadController = TextEditingController(text: '40');

  String _tubType = 'alcove';

  bool? _fitsStandard;
  double? _waterWeight;
  bool? _needsReinforce;
  String? _recommendation;

  @override
  void dispose() { _alcoveWidthController.dispose(); _floorLoadController.dispose(); super.dispose(); }

  void _calculate() {
    final alcoveWidth = double.tryParse(_alcoveWidthController.text) ?? 60;
    final floorLoad = double.tryParse(_floorLoadController.text) ?? 40;

    // Standard alcove tub is 60"
    final fitsStandard = alcoveWidth >= 60;

    // Water weight calculation
    double gallons;
    switch (_tubType) {
      case 'alcove': gallons = 40; break;
      case 'freestanding': gallons = 60; break;
      case 'soaking': gallons = 80; break;
      case 'whirlpool': gallons = 70; break;
      default: gallons = 40;
    }

    // Water weighs 8.34 lbs/gallon + tub (~100-300 lbs) + person (~200 lbs)
    final waterWeight = gallons * 8.34;
    final tubWeight = _tubType == 'freestanding' ? 300.0 : 100.0;
    final totalWeight = waterWeight + tubWeight + 200;

    // Floor area (estimate ~15 sqft)
    final loadPerSqft = totalWeight / 15;
    final needsReinforce = loadPerSqft > floorLoad;

    String recommendation;
    if (alcoveWidth >= 72) {
      recommendation = '72\" soaking tub available';
    } else if (alcoveWidth >= 60) {
      recommendation = 'Standard 60\" alcove tub';
    } else if (alcoveWidth >= 54) {
      recommendation = '54\" compact tub';
    } else if (alcoveWidth >= 48) {
      recommendation = '48\" corner or Japanese tub';
    } else {
      recommendation = 'Shower only - too narrow for tub';
    }

    setState(() { _fitsStandard = fitsStandard; _waterWeight = waterWeight; _needsReinforce = needsReinforce; _recommendation = recommendation; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _alcoveWidthController.text = '60'; _floorLoadController.text = '40'; setState(() => _tubType = 'alcove'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bathtub Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Alcove Width', unit: 'inches', controller: _alcoveWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Floor Rating', unit: 'psf', controller: _floorLoadController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_fitsStandard != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STANDARD TUB', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_fitsStandard! ? 'FITS' : 'NO FIT', style: TextStyle(color: _fitsStandard! ? colors.accentSuccess : colors.accentError, fontSize: 20, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water Weight', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_waterWeight!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Reinforcement', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_needsReinforce! ? 'NEEDED' : 'OK', style: TextStyle(color: _needsReinforce! ? colors.accentWarning : colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['alcove', 'freestanding', 'soaking', 'whirlpool'];
    final labels = {'alcove': 'Alcove', 'freestanding': 'Freestand', 'soaking': 'Soaking', 'whirlpool': 'Whirlpool'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TUB TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _tubType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _tubType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATHTUB DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard alcove', '60\" x 30-32\"'),
        _buildTableRow(colors, 'Compact', '54\" x 30\"'),
        _buildTableRow(colors, 'Freestanding', '55-72\" x 27-32\"'),
        _buildTableRow(colors, 'Soaking depth', '14-22\" water'),
        _buildTableRow(colors, 'Access clearance', '21\" min front'),
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
