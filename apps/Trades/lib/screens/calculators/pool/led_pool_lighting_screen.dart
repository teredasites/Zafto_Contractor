import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool LED Lighting Calculator
class LedPoolLightingScreen extends ConsumerStatefulWidget {
  const LedPoolLightingScreen({super.key});
  @override
  ConsumerState<LedPoolLightingScreen> createState() => _LedPoolLightingScreenState();
}

class _LedPoolLightingScreenState extends ConsumerState<LedPoolLightingScreen> {
  final _poolSqFtController = TextEditingController();
  final _poolDepthController = TextEditingController(text: '5');
  bool _hasSpa = false;
  bool _wantColorChanging = true;
  String _lightType = 'LED';

  int? _lightsNeeded;
  double? _totalWatts;
  String? _recommendation;

  void _calculate() {
    final poolSqFt = double.tryParse(_poolSqFtController.text);
    final poolDepth = double.tryParse(_poolDepthController.text);

    if (poolSqFt == null || poolDepth == null || poolSqFt <= 0) {
      setState(() { _lightsNeeded = null; });
      return;
    }

    // Pool lighting rule: 1 light per 400-600 sq ft
    // Deeper pools need more lights, color-changing need proper coverage
    double coveragePerLight = poolDepth > 6 ? 400 : 500;
    if (_wantColorChanging) coveragePerLight *= 0.8; // Better coverage for color blending

    int poolLights = (poolSqFt / coveragePerLight).ceil();
    if (poolLights < 1) poolLights = 1;

    // Spa always needs at least 1 light
    int spaLights = _hasSpa ? 1 : 0;
    int totalLights = poolLights + spaLights;

    // Wattage by type
    double wattsPerLight;
    if (_lightType == 'LED') {
      wattsPerLight = _wantColorChanging ? 35 : 25;
    } else if (_lightType == 'Fiber Optic') {
      wattsPerLight = 50; // Illuminator wattage
    } else {
      wattsPerLight = 300; // Incandescent (not recommended)
    }

    final totalWatts = totalLights * wattsPerLight;

    String recommendation;
    if (_lightType == 'LED') {
      recommendation = _wantColorChanging
          ? 'Color-changing LEDs: Pentair IntelliBrite, Hayward ColorLogic'
          : 'White LEDs provide 80% energy savings vs incandescent';
    } else if (_lightType == 'Fiber Optic') {
      recommendation = 'Fiber optic allows multiple light points from one illuminator';
    } else {
      recommendation = 'Consider upgrading to LED for 80% energy savings';
    }

    setState(() {
      _lightsNeeded = totalLights;
      _totalWatts = totalWatts;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _poolSqFtController.clear();
    _poolDepthController.text = '5';
    _hasSpa = false;
    _wantColorChanging = true;
    setState(() { _lightsNeeded = null; });
  }

  @override
  void dispose() {
    _poolSqFtController.dispose();
    _poolDepthController.dispose();
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
        title: Text('Pool LED Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('LIGHT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Area', unit: 'sq ft', hint: 'Surface area', controller: _poolSqFtController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'ft', hint: 'Pool depth', controller: _poolDepthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildOptionsToggles(colors),
            const SizedBox(height: 32),
            if (_lightsNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['LED', 'Fiber Optic', 'Incandescent'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 12)),
        selected: _lightType == type,
        onSelected: (_) => setState(() { _lightType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildOptionsToggles(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Has Spa'), selected: _hasSpa, onSelected: (_) => setState(() { _hasSpa = !_hasSpa; _calculate(); })),
        ChoiceChip(label: const Text('Color-Changing'), selected: _wantColorChanging, onSelected: (_) => setState(() { _wantColorChanging = !_wantColorChanging; _calculate(); })),
      ],
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('1 Light per 400-500 sq ft', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('NEC 680 requires GFCI protection', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Lights Needed', '$_lightsNeeded', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Wattage', '${_totalWatts!.toStringAsFixed(0)} W'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
        const SizedBox(height: 12),
        Text('Install lights at least 4" below waterline', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
