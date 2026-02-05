import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gutter Sizing Calculator - Gutter capacity estimation
class GutterSizingScreen extends ConsumerStatefulWidget {
  const GutterSizingScreen({super.key});
  @override
  ConsumerState<GutterSizingScreen> createState() => _GutterSizingScreenState();
}

class _GutterSizingScreenState extends ConsumerState<GutterSizingScreen> {
  final _roofAreaController = TextEditingController(text: '1500');
  final _roofPitchController = TextEditingController(text: '6');

  String _rainIntensity = 'moderate';
  String _material = 'aluminum';

  String? _gutterSize;
  String? _downspoutSize;
  int? _downspouts;
  double? _gutterFeet;

  @override
  void dispose() { _roofAreaController.dispose(); _roofPitchController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 1500;
    final roofPitch = double.tryParse(_roofPitchController.text) ?? 6;

    // Adjust for roof pitch (steeper = faster runoff)
    double pitchFactor;
    if (roofPitch <= 4) {
      pitchFactor = 1.0;
    } else if (roofPitch <= 6) {
      pitchFactor = 1.05;
    } else if (roofPitch <= 9) {
      pitchFactor = 1.1;
    } else {
      pitchFactor = 1.2;
    }

    // Rain intensity factor
    double rainFactor;
    switch (_rainIntensity) {
      case 'light':
        rainFactor = 1.0;
        break;
      case 'moderate':
        rainFactor = 1.5;
        break;
      case 'heavy':
        rainFactor = 2.0;
        break;
      default:
        rainFactor = 1.5;
    }

    final adjustedArea = roofArea * pitchFactor * rainFactor;

    // Gutter sizing
    String gutterSize;
    String downspoutSize;
    if (adjustedArea < 1500) {
      gutterSize = '5\" K-style';
      downspoutSize = '2\" x 3\"';
    } else if (adjustedArea < 3000) {
      gutterSize = '6\" K-style';
      downspoutSize = '3\" x 4\"';
    } else {
      gutterSize = '7\" commercial';
      downspoutSize = '4\" round';
    }

    // Downspouts: 1 per 40' of gutter or fraction thereof
    final gutterFeet = roofArea / 15; // Rough estimate
    final downspouts = (gutterFeet / 40).ceil();

    setState(() { _gutterSize = gutterSize; _downspoutSize = downspoutSize; _downspouts = downspouts < 2 ? 2 : downspouts; _gutterFeet = gutterFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '1500'; _roofPitchController.text = '6'; setState(() { _rainIntensity = 'moderate'; _material = 'aluminum'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Gutter Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'RAIN INTENSITY', ['light', 'moderate', 'heavy'], _rainIntensity, {'light': 'Light', 'moderate': 'Moderate', 'heavy': 'Heavy'}, (v) { setState(() => _rainIntensity = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['aluminum', 'vinyl', 'copper', 'steel'], _material, {'aluminum': 'Aluminum', 'vinyl': 'Vinyl', 'copper': 'Copper', 'steel': 'Steel'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Roof Area', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Roof Pitch', unit: '/12', controller: _roofPitchController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gutterSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_gutterSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Downspout Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_downspoutSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min Downspouts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_downspouts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Gutter Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_gutterFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Slope gutters 1/4\" per 10\'. Max run to downspout: 40\'. Add gutter guards for less maintenance.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCapacityTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCapacityTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GUTTER CAPACITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '5\" K-style', '1,200 sq ft roof'),
        _buildTableRow(colors, '6\" K-style', '2,500 sq ft roof'),
        _buildTableRow(colors, '6\" half-round', '2,000 sq ft roof'),
        _buildTableRow(colors, '7\" commercial', '4,000+ sq ft roof'),
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
