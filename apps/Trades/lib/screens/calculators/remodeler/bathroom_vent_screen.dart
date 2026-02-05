import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bathroom Vent Calculator - Exhaust fan sizing
class BathroomVentScreen extends ConsumerStatefulWidget {
  const BathroomVentScreen({super.key});
  @override
  ConsumerState<BathroomVentScreen> createState() => _BathroomVentScreenState();
}

class _BathroomVentScreenState extends ConsumerState<BathroomVentScreen> {
  final _lengthController = TextEditingController(text: '8');
  final _widthController = TextEditingController(text: '5');
  final _heightController = TextEditingController(text: '8');

  bool _hasShower = true;
  bool _hasJetTub = false;

  int? _cfmNeeded;
  int? _cfmRecommended;
  double? _sones;
  String? _ductSize;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;

    final cubicFeet = length * width * height;

    // HVI recommends 8 air changes per hour
    // CFM = (Volume x ACH) / 60
    var cfmNeeded = ((cubicFeet * 8) / 60).ceil();

    // Minimum 50 CFM per code
    if (cfmNeeded < 50) cfmNeeded = 50;

    // Add for shower/tub
    int additionalCfm = 0;
    if (_hasShower) additionalCfm += 50;
    if (_hasJetTub) additionalCfm += 100;

    final cfmRecommended = cfmNeeded + additionalCfm;

    // Sones (noise) recommendation
    double sones;
    if (cfmRecommended <= 80) {
      sones = 1.0;
    } else if (cfmRecommended <= 110) {
      sones = 1.5;
    } else {
      sones = 2.0;
    }

    // Duct size
    String ductSize;
    if (cfmRecommended <= 50) {
      ductSize = '3\" or 4\"';
    } else if (cfmRecommended <= 80) {
      ductSize = '4\"';
    } else if (cfmRecommended <= 125) {
      ductSize = '4\" or 6\"';
    } else {
      ductSize = '6\"';
    }

    setState(() { _cfmNeeded = cfmNeeded; _cfmRecommended = cfmRecommended; _sones = sones; _ductSize = ductSize; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '8'; _widthController.text = '5'; _heightController.text = '8'; setState(() { _hasShower = true; _hasJetTub = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bathroom Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Shower/Tub', _hasShower, (v) { setState(() => _hasShower = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Jetted Tub', _hasJetTub, (v) { setState(() => _hasJetTub = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_cfmRecommended != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FAN SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cfmRecommended CFM', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Minimum (code)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_cfmNeeded CFM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max Noise', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sones!.toStringAsFixed(1)} sones', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Duct Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_ductSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Vent to exterior, not attic. Use rigid duct when possible. Insulate in cold climates.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCodeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
          child: Center(child: Text(value ? 'Yes' : 'No', style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    ]);
  }

  Widget _buildCodeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CODE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Minimum', '50 CFM intermittent'),
        _buildTableRow(colors, 'Continuous', '20 CFM if always on'),
        _buildTableRow(colors, 'Window option', '3 sqft operable'),
        _buildTableRow(colors, 'Quiet fan', '<1.0 sones'),
        _buildTableRow(colors, 'Timer switch', 'Recommended'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
