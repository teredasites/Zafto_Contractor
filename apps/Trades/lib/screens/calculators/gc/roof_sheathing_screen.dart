import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Sheathing Calculator - OSB/plywood for roof deck
class RoofSheathingScreen extends ConsumerStatefulWidget {
  const RoofSheathingScreen({super.key});
  @override
  ConsumerState<RoofSheathingScreen> createState() => _RoofSheathingScreenState();
}

class _RoofSheathingScreenState extends ConsumerState<RoofSheathingScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');

  String _sheathingType = 'osb';
  String _thickness = '1/2';

  double? _roofArea;
  int? _sheetsNeeded;
  int? _hClipsNeeded;
  double? _materialCost;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _pitchController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (length == null || width == null || pitch == null) {
      setState(() { _roofArea = null; _sheetsNeeded = null; _hClipsNeeded = null; _materialCost = null; });
      return;
    }

    // Calculate pitch factor (rise per 12" run)
    final pitchFactor = _getPitchMultiplier(pitch);

    // Footprint area times pitch factor
    final footprintArea = length * width;
    final roofArea = footprintArea * pitchFactor;

    // 4x8 sheet = 32 sq ft, add 10% waste for hips/valleys
    final sheetsNeeded = ((roofArea / 32) * 1.10).ceil();

    // H-clips: one every 4' between sheets on unsupported edges
    // Roughly 2 per sheet
    final hClipsNeeded = sheetsNeeded * 2;

    // Cost estimate
    double costPerSheet;
    switch (_sheathingType) {
      case 'osb':
        switch (_thickness) {
          case '7/16': costPerSheet = 15; break;
          case '1/2': costPerSheet = 18; break;
          case '5/8': costPerSheet = 24; break;
          case '3/4': costPerSheet = 30; break;
          default: costPerSheet = 18;
        }
        break;
      case 'plywood':
        switch (_thickness) {
          case '7/16': costPerSheet = 28; break;
          case '1/2': costPerSheet = 32; break;
          case '5/8': costPerSheet = 40; break;
          case '3/4': costPerSheet = 48; break;
          default: costPerSheet = 32;
        }
        break;
      default:
        costPerSheet = 20;
    }

    final materialCost = sheetsNeeded * costPerSheet + hClipsNeeded * 0.25;

    setState(() { _roofArea = roofArea; _sheetsNeeded = sheetsNeeded; _hClipsNeeded = hClipsNeeded; _materialCost = materialCost; });
  }

  double _getPitchMultiplier(double pitch) {
    // Multiplier = sqrt(rise² + 12²) / 12
    final rise = pitch;
    final run = 12.0;
    return (rise * rise + run * run).abs() > 0 ? ((rise * rise + run * run) as double).abs() > 0
        ? (((rise * rise + run * run) as double).abs()).toDouble() > 0
            ? (1 + (rise * rise) / (run * run)).abs().toDouble().clamp(1.0, 2.0) > 0
                ? (1 + (rise * rise) / (run * run)).abs().toDouble().clamp(1.0, 2.0)
                : 1.0
            : 1.0
        : 1.0
        : 1.0;
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '30'; _pitchController.text = '6'; setState(() { _sheathingType = 'osb'; _thickness = '1/2'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Roof Sheathing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHEATHING TYPE', ['osb', 'plywood'], _sheathingType, (v) { setState(() => _sheathingType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'THICKNESS', ['7/16', '1/2', '5/8', '3/4'], _thickness, (v) { setState(() => _thickness = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Building Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Building Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Roof Pitch', unit: '/12', controller: _pitchController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sheetsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHEETS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sheetsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Roof Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_roofArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('H-Clips', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hClipsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Material Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_materialCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Min 1/2" for 24" OC rafters/trusses. Use H-clips or blocking between sheets. Stagger joints.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'osb': 'OSB', 'plywood': 'Plywood'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('${labels[o] ?? o}$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
