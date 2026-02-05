import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Muffler Sizing Calculator - Flow capacity for mufflers
class MufflerSizingScreen extends ConsumerStatefulWidget {
  const MufflerSizingScreen({super.key});
  @override
  ConsumerState<MufflerSizingScreen> createState() => _MufflerSizingScreenState();
}

class _MufflerSizingScreenState extends ConsumerState<MufflerSizingScreen> {
  final _hpController = TextEditingController();
  final _inletDiameterController = TextEditingController(text: '2.5');
  final _maxRpmController = TextEditingController(text: '6500');

  double? _cfmRequired;
  double? _minInletArea;
  String? _mufflerType;
  String? _recommendation;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final inletD = double.tryParse(_inletDiameterController.text);
    final rpm = double.tryParse(_maxRpmController.text);

    if (hp == null || inletD == null || rpm == null) {
      setState(() { _cfmRequired = null; });
      return;
    }

    // CFM required = HP x 1.5 (approximate for NA engines)
    // For boosted engines, multiply by 2.0
    final cfm = hp * 1.5;

    // Inlet area calculation
    final inletArea = 3.14159 * (inletD / 2) * (inletD / 2);

    // Flow velocity = CFM / Area (want under 15,000 ft/min for low restriction)
    final flowVelocity = (cfm / inletArea) * 144; // Convert to ft/min

    // Muffler type recommendation based on HP and desired sound
    String type;
    String rec;
    if (hp < 250) {
      type = 'Chambered or turbo-style muffler';
      rec = 'Single 2.5" inlet/outlet sufficient';
    } else if (hp < 400) {
      type = 'Straight-through (glasspack) or chambered';
      rec = '2.5-3.0" inlet/outlet recommended';
    } else if (hp < 600) {
      type = 'Free-flow straight-through muffler';
      rec = '3.0" minimum, dual recommended';
    } else {
      type = 'Race muffler or straight pipe (track only)';
      rec = '3.5"+ or dual 3.0" required';
    }

    setState(() {
      _cfmRequired = cfm;
      _minInletArea = inletArea;
      _mufflerType = type;
      _recommendation = rec;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _inletDiameterController.text = '2.5';
    _maxRpmController.text = '6500';
    setState(() { _cfmRequired = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _inletDiameterController.dispose();
    _maxRpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Muffler Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Target Horsepower', unit: 'HP', hint: 'Crank HP', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Inlet Diameter', unit: 'in', hint: 'Exhaust pipe size', controller: _inletDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max RPM', unit: 'RPM', hint: 'Redline RPM', controller: _maxRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cfmRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('CFM = HP x 1.5 (NA)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Muffler must flow enough CFM without excessive restriction', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Required', '${_cfmRequired!.toStringAsFixed(0)} CFM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Inlet Area', '${_minInletArea!.toStringAsFixed(2)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recommended Type:', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(_mufflerType!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 12),
        _buildMufflerTypes(colors),
      ]),
    );
  }

  Widget _buildMufflerTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Muffler Types by Flow:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildTypeRow(colors, 'Turbo-style', 'Quiet, moderate flow'),
        _buildTypeRow(colors, 'Chambered', 'Classic muscle tone'),
        _buildTypeRow(colors, 'Glasspack', 'Loud, good flow'),
        _buildTypeRow(colors, 'Straight-through', 'Best flow, loud'),
      ]),
    );
  }

  Widget _buildTypeRow(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 110, child: Text(type, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
