import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Orifice Tube Selection Calculator
/// Helps select proper orifice tube based on system specs
class OrificeTubeScreen extends ConsumerStatefulWidget {
  const OrificeTubeScreen({super.key});
  @override
  ConsumerState<OrificeTubeScreen> createState() => _OrificeTubeScreenState();
}

class _OrificeTubeScreenState extends ConsumerState<OrificeTubeScreen> {
  final _tonnageController = TextEditingController();
  final _evapTempController = TextEditingController(text: '40');
  final _condTempController = TextEditingController(text: '110');

  String? _recommendedTube;
  String? _tubeColor;
  String? _application;
  double? _flowRate;
  String? _alternateSize;

  // Orifice tube color coding (industry standard)
  final Map<String, Map<String, dynamic>> _tubeSpecs = {
    'White': {'size': 0.057, 'flow': 'Low', 'tons': '0.5-1.0', 'app': 'Small compacts, rear A/C'},
    'Orange': {'size': 0.062, 'flow': 'Med-Low', 'tons': '1.0-1.5', 'app': 'Small cars, economy vehicles'},
    'Brown': {'size': 0.067, 'flow': 'Medium', 'tons': '1.5-2.0', 'app': 'Mid-size sedans'},
    'Green': {'size': 0.072, 'flow': 'Med-High', 'tons': '2.0-2.5', 'app': 'Full-size sedans, small SUVs'},
    'Red': {'size': 0.077, 'flow': 'High', 'tons': '2.5-3.0', 'app': 'Large SUVs, trucks'},
    'Blue': {'size': 0.082, 'flow': 'Very High', 'tons': '3.0+', 'app': 'Heavy duty, dual A/C systems'},
    'Black': {'size': 0.087, 'flow': 'Max', 'tons': '3.5+', 'app': 'Commercial, RV applications'},
  };

  void _calculate() {
    final tonnage = double.tryParse(_tonnageController.text);
    final evapTemp = double.tryParse(_evapTempController.text) ?? 40;
    final condTemp = double.tryParse(_condTempController.text) ?? 110;

    if (tonnage == null) {
      setState(() { _recommendedTube = null; });
      return;
    }

    // Select tube based on tonnage
    String tube;
    if (tonnage <= 1.0) {
      tube = 'White';
    } else if (tonnage <= 1.5) {
      tube = 'Orange';
    } else if (tonnage <= 2.0) {
      tube = 'Brown';
    } else if (tonnage <= 2.5) {
      tube = 'Green';
    } else if (tonnage <= 3.0) {
      tube = 'Red';
    } else if (tonnage <= 3.5) {
      tube = 'Blue';
    } else {
      tube = 'Black';
    }

    // Adjust for temperature conditions
    final tempDiff = condTemp - evapTemp;
    String? alt;
    if (tempDiff > 80) {
      // High temperature differential - may need larger tube
      final tubes = _tubeSpecs.keys.toList();
      final idx = tubes.indexOf(tube);
      if (idx < tubes.length - 1) {
        alt = '${tubes[idx + 1]} (high temp diff)';
      }
    } else if (tempDiff < 50) {
      // Low temperature differential - may need smaller tube
      final tubes = _tubeSpecs.keys.toList();
      final idx = tubes.indexOf(tube);
      if (idx > 0) {
        alt = '${tubes[idx - 1]} (low temp diff)';
      }
    }

    final spec = _tubeSpecs[tube]!;
    // Approximate flow rate calculation (tons * 200 lbs/hr)
    final flow = tonnage * 200;

    setState(() {
      _recommendedTube = tube;
      _tubeColor = tube;
      _application = spec['app'] as String;
      _flowRate = flow;
      _alternateSize = alt;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _tonnageController.clear();
    _evapTempController.text = '40';
    _condTempController.text = '110';
    setState(() { _recommendedTube = null; });
  }

  @override
  void dispose() {
    _tonnageController.dispose();
    _evapTempController.dispose();
    _condTempController.dispose();
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
        title: Text('Orifice Tube', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'System Tonnage', unit: 'tons', hint: 'A/C system capacity', controller: _tonnageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Evaporator Temp', unit: 'F', hint: 'Target evaporator temperature', controller: _evapTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Condenser Temp', unit: 'F', hint: 'Expected condenser temperature', controller: _condTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedTube != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildColorGuide(colors),
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
        Text('Orifice tube sized by system tonnage', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Color-coded for easy identification', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Color _getTubeDisplayColor(String tube) {
    switch (tube) {
      case 'White': return Colors.white;
      case 'Orange': return Colors.orange;
      case 'Brown': return Colors.brown;
      case 'Green': return Colors.green;
      case 'Red': return Colors.red;
      case 'Blue': return Colors.blue;
      case 'Black': return Colors.black;
      default: return Colors.grey;
    }
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final tubeDisplayColor = _getTubeDisplayColor(_tubeColor!);
    final spec = _tubeSpecs[_tubeColor]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: tubeDisplayColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.textSecondary, width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Text('$_tubeColor Tube', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 24)),
        ]),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Orifice Size', '${spec['size']}" dia'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Rating', spec['flow'] as String),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tonnage Range', spec['tons'] as String),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Flow Rate', '${_flowRate!.toStringAsFixed(0)} lbs/hr'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_application!, style: TextStyle(color: colors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ),
        if (_alternateSize != null) ...[
          const SizedBox(height: 12),
          Text('Alternate: $_alternateSize', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ]),
    );
  }

  Widget _buildColorGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Color Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        ..._tubeSpecs.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: _getTubeDisplayColor(e.key),
                shape: BoxShape.circle,
                border: Border.all(color: colors.textTertiary),
              ),
            ),
            const SizedBox(width: 12),
            Text('${e.key}: ${e.value['tons']} tons', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ]),
        )),
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
