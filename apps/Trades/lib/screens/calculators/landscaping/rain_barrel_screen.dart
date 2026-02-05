import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rain Barrel Calculator - Sizing for rainwater harvesting
class RainBarrelScreen extends ConsumerStatefulWidget {
  const RainBarrelScreen({super.key});
  @override
  ConsumerState<RainBarrelScreen> createState() => _RainBarrelScreenState();
}

class _RainBarrelScreenState extends ConsumerState<RainBarrelScreen> {
  final _roofAreaController = TextEditingController(text: '1000');
  final _rainfallController = TextEditingController(text: '1');

  String _barrelSize = '55';

  double? _gallonsCollected;
  int? _barrelsNeeded;
  double? _annualGallons;

  @override
  void dispose() { _roofAreaController.dispose(); _rainfallController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 1000;
    final rainfall = double.tryParse(_rainfallController.text) ?? 1;
    final barrelGal = double.tryParse(_barrelSize) ?? 55;

    // 1" rain on 1 sq ft = 0.623 gallons
    // Account for ~80% collection efficiency
    final gallonsPerInch = roofArea * 0.623 * 0.8;
    final collected = gallonsPerInch * rainfall;
    final barrels = (collected / barrelGal).ceil();

    // Annual estimate (average 40" rainfall)
    final annual = gallonsPerInch * 40;

    setState(() {
      _gallonsCollected = collected;
      _barrelsNeeded = barrels;
      _annualGallons = annual;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '1000'; _rainfallController.text = '1'; setState(() { _barrelSize = '55'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rain Barrel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'BARREL SIZE', ['35', '55', '100'], _barrelSize, {'35': '35 gal', '55': '55 gal', '100': '100 gal'}, (v) { setState(() => _barrelSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Collection Area', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rainfall Amount', unit: 'in', controller: _rainfallController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallonsCollected != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BARRELS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_barrelsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Water collected', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallonsCollected!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Annual potential', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_annualGallons!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRainGuide(colors),
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

  Widget _buildRainGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COLLECTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1" on 1000 sq ft', '~500 gallons'),
        _buildTableRow(colors, 'Downspout filter', 'Required'),
        _buildTableRow(colors, 'First flush', 'Divert first 10 gal'),
        _buildTableRow(colors, 'Overflow', 'Route away from foundation'),
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
