import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// TIG Amperage Calculator - GTAW amperage settings
class TigAmperageScreen extends ConsumerStatefulWidget {
  const TigAmperageScreen({super.key});
  @override
  ConsumerState<TigAmperageScreen> createState() => _TigAmperageScreenState();
}

class _TigAmperageScreenState extends ConsumerState<TigAmperageScreen> {
  final _thicknessController = TextEditingController();
  String _material = 'Steel';
  String _tungstenSize = '3/32';
  String _polarity = 'DCEN';

  int? _minAmps;
  int? _maxAmps;
  int? _recommendedAmps;
  String? _cupSize;
  double? _gasFlow;

  // Tungsten amperage ranges
  static const Map<String, List<int>> _tungstenRanges = {
    '0.040': [15, 80],
    '1/16': [50, 100],
    '3/32': [80, 160],
    '1/8': [130, 230],
    '5/32': [180, 300],
    '3/16': [250, 400],
  };

  // Material factors for amperage
  static const Map<String, double> _materialFactor = {
    'Steel': 1.0,
    'Stainless': 0.9,
    'Aluminum': 1.3,
    'Titanium': 0.8,
    'Copper': 1.5,
    'Nickel': 0.85,
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    final range = _tungstenRanges[_tungstenSize] ?? [80, 160];
    final materialFactor = _materialFactor[_material] ?? 1.0;

    // AC for aluminum, adjust range
    double polarityFactor = 1.0;
    if (_polarity == 'AC') {
      polarityFactor = 0.85; // AC runs cooler
    }

    int minAmps = (range[0] * materialFactor * polarityFactor).round();
    int maxAmps = (range[1] * materialFactor * polarityFactor).round();

    int recommended;
    if (thickness != null && thickness > 0) {
      // Rule of thumb: ~1 amp per 0.001" for steel
      recommended = ((thickness * 1000) * materialFactor * polarityFactor).round();
      recommended = recommended.clamp(minAmps, maxAmps);
    } else {
      recommended = ((minAmps + maxAmps) / 2).round();
    }

    // Cup size recommendation
    String cupSize;
    double gasFlow;
    if (recommended < 100) {
      cupSize = '#5 or #6 (5/16" - 3/8")';
      gasFlow = 10;
    } else if (recommended < 200) {
      cupSize = '#7 or #8 (7/16" - 1/2")';
      gasFlow = 15;
    } else {
      cupSize = '#10 or #12 (5/8" - 3/4")';
      gasFlow = 20;
    }

    setState(() {
      _minAmps = minAmps;
      _maxAmps = maxAmps;
      _recommendedAmps = recommended;
      _cupSize = cupSize;
      _gasFlow = gasFlow;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _minAmps = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('TIG Amperage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            Text('Tungsten Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTungstenSelector(colors),
            const SizedBox(height: 16),
            Text('Polarity', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildPolaritySelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'For amp calculation', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minAmps != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _materialFactor.keys.map((mat) => ChoiceChip(
        label: Text(mat, style: const TextStyle(fontSize: 12)),
        selected: _material == mat,
        onSelected: (_) => setState(() { _material = mat; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildTungstenSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tungstenRanges.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _tungstenSize == size,
        onSelected: (_) => setState(() { _tungstenSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPolaritySelector(ZaftoColors colors) {
    final polarities = ['DCEN', 'DCEP', 'AC'];
    return Wrap(
      spacing: 8,
      children: polarities.map((pol) => ChoiceChip(
        label: Text(pol),
        selected: _polarity == pol,
        onSelected: (_) => setState(() { _polarity = pol; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('GTAW Amperage Settings', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Rule of thumb: 1 amp per 0.001" thickness (steel)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended', '$_recommendedAmps A', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Range', '$_minAmps - $_maxAmps A'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cup Size', _cupSize!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gas Flow', '${_gasFlow!.toStringAsFixed(0)} CFH'),
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
