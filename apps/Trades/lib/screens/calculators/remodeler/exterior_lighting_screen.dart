import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Exterior Lighting Calculator - Outdoor lighting installation estimation
class ExteriorLightingScreen extends ConsumerStatefulWidget {
  const ExteriorLightingScreen({super.key});
  @override
  ConsumerState<ExteriorLightingScreen> createState() => _ExteriorLightingScreenState();
}

class _ExteriorLightingScreenState extends ConsumerState<ExteriorLightingScreen> {
  final _fixtureCountController = TextEditingController(text: '4');
  final _wireRunController = TextEditingController(text: '50');

  String _voltage = 'low';
  String _fixtureType = 'path';

  double? _transformerWatts;
  double? _wireFeet;
  int? _junctionBoxes;
  int? _connectors;

  @override
  void dispose() { _fixtureCountController.dispose(); _wireRunController.dispose(); super.dispose(); }

  void _calculate() {
    final fixtureCount = int.tryParse(_fixtureCountController.text) ?? 4;
    final wireRun = double.tryParse(_wireRunController.text) ?? 50;

    // Watts per fixture based on type
    double wattsPerFixture;
    switch (_fixtureType) {
      case 'path':
        wattsPerFixture = 3; // LED path light
        break;
      case 'spot':
        wattsPerFixture = 7; // LED spotlight
        break;
      case 'flood':
        wattsPerFixture = 15; // LED flood
        break;
      case 'wall':
        wattsPerFixture = 10; // Wall sconce
        break;
      default:
        wattsPerFixture = 5;
    }

    // Transformer sizing (for low voltage)
    double transformerWatts;
    if (_voltage == 'low') {
      final totalWatts = fixtureCount * wattsPerFixture;
      // Size transformer at 1.25x load
      transformerWatts = totalWatts * 1.25;
      // Round up to standard sizes: 60, 100, 150, 200, 300
      if (transformerWatts <= 60) transformerWatts = 60;
      else if (transformerWatts <= 100) transformerWatts = 100;
      else if (transformerWatts <= 150) transformerWatts = 150;
      else if (transformerWatts <= 200) transformerWatts = 200;
      else transformerWatts = 300;
    } else {
      transformerWatts = 0; // Line voltage doesn't need transformer
    }

    // Wire calculation
    double wireFeet;
    if (_voltage == 'low') {
      // Low voltage: daisy chain from transformer
      wireFeet = wireRun * 1.2; // +20% for routing
    } else if (_voltage == 'solar') {
      wireFeet = 0;
    } else {
      // Line voltage: home run to each fixture
      wireFeet = wireRun * fixtureCount * 0.5; // Assume 50% shared runs
    }

    // Junction boxes (for line voltage)
    final junctionBoxes = _voltage == 'line' ? fixtureCount : 0;

    // Connectors
    final connectors = _voltage == 'low' ? fixtureCount : 0;

    setState(() { _transformerWatts = transformerWatts; _wireFeet = wireFeet; _junctionBoxes = junctionBoxes; _connectors = connectors; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _fixtureCountController.text = '4'; _wireRunController.text = '50'; setState(() { _voltage = 'low'; _fixtureType = 'path'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Exterior Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'VOLTAGE', ['low', 'line', 'solar'], _voltage, {'low': 'Low (12V)', 'line': 'Line (120V)', 'solar': 'Solar'}, (v) { setState(() => _voltage = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FIXTURE TYPE', ['path', 'spot', 'flood', 'wall'], _fixtureType, {'path': 'Path', 'spot': 'Spot', 'flood': 'Flood', 'wall': 'Wall'}, (v) { setState(() => _fixtureType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Fixtures', unit: 'qty', controller: _fixtureCountController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Total Run', unit: 'feet', controller: _wireRunController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_transformerWatts != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                if (_voltage == 'low') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TRANSFORMER', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_transformerWatts!.toStringAsFixed(0)}W', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ] else if (_voltage == 'solar') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SOLAR', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('No wiring', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ] else ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LINE VOLTAGE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('120V', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ],
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_wireFeet! > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_voltage == 'low' ? 'LV Wire (12/2)' : 'UF-B Wire', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wireFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                if (_voltage == 'low') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wire Connectors', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_connectors', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_voltage == 'line') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Junction Boxes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_junctionBoxes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getVoltageTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlacementTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getVoltageTip() {
    switch (_voltage) {
      case 'low':
        return 'Low voltage: safe DIY, bury wire 6\". Use 12 or 14 gauge wire. Max run depends on load.';
      case 'line':
        return 'Line voltage: requires permit, electrician recommended. Use UF-B wire buried 18-24\".';
      case 'solar':
        return 'Solar: no wiring needed. Requires 6+ hours sun. Battery backup varies by model.';
      default:
        return 'Outdoor fixtures must be rated for wet locations.';
    }
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildPlacementTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PLACEMENT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Path lights', '6-8\' apart'),
        _buildTableRow(colors, 'Spotlights', '1 per feature'),
        _buildTableRow(colors, 'Wall sconces', '66\" from floor'),
        _buildTableRow(colors, 'Security floods', 'At corners'),
        _buildTableRow(colors, 'Timer/sensor', 'Recommended'),
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
