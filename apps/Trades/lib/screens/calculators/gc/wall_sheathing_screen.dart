import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wall Sheathing Calculator - OSB/plywood for wall covering
class WallSheathingScreen extends ConsumerStatefulWidget {
  const WallSheathingScreen({super.key});
  @override
  ConsumerState<WallSheathingScreen> createState() => _WallSheathingScreenState();
}

class _WallSheathingScreenState extends ConsumerState<WallSheathingScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _heightController = TextEditingController(text: '9');

  String _sheathingType = 'osb';
  String _thickness = '7/16';

  double? _wallArea;
  int? _sheetsNeeded;
  int? _nailsLbs;
  double? _materialCost;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final height = double.tryParse(_heightController.text);

    if (perimeter == null || height == null) {
      setState(() { _wallArea = null; _sheetsNeeded = null; _nailsLbs = null; _materialCost = null; });
      return;
    }

    final wallArea = perimeter * height;

    // 4x8 sheet = 32 sq ft, add 10% waste
    final sheetsNeeded = ((wallArea / 32) * 1.10).ceil();

    // Nails: approximately 1 lb per 100 sq ft (8d nails)
    final nailsLbs = (wallArea / 100).ceil();

    // Cost estimate
    double costPerSheet;
    switch (_sheathingType) {
      case 'osb':
        switch (_thickness) {
          case '7/16': costPerSheet = 15; break;
          case '1/2': costPerSheet = 18; break;
          case '5/8': costPerSheet = 24; break;
          default: costPerSheet = 15;
        }
        break;
      case 'plywood':
        switch (_thickness) {
          case '7/16': costPerSheet = 28; break;
          case '1/2': costPerSheet = 32; break;
          case '5/8': costPerSheet = 40; break;
          default: costPerSheet = 28;
        }
        break;
      case 'zip':
        costPerSheet = 35; break;
      default:
        costPerSheet = 20;
    }

    final materialCost = sheetsNeeded * costPerSheet;

    setState(() { _wallArea = wallArea; _sheetsNeeded = sheetsNeeded; _nailsLbs = nailsLbs; _materialCost = materialCost; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _heightController.text = '9'; setState(() { _sheathingType = 'osb'; _thickness = '7/16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wall Sheathing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHEATHING TYPE', ['osb', 'plywood', 'zip'], _sheathingType, (v) { setState(() => _sheathingType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'THICKNESS', ['7/16', '1/2', '5/8'], _thickness, (v) { setState(() => _thickness = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sheetsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHEETS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sheetsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('8d Nails', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_nailsLbs lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Material Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_materialCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSheathingNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getSheathingNote() {
    switch (_sheathingType) {
      case 'osb': return 'OSB: Nail 6" OC at edges, 12" OC in field. Stagger joints. Store flat and dry.';
      case 'plywood': return 'Plywood: Better moisture resistance than OSB. Use CDX grade exterior.';
      case 'zip': return 'ZIP System: Integrated WRB. Tape all seams with ZIP tape for air barrier.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'osb': 'OSB', 'plywood': 'Plywood', 'zip': 'ZIP'};
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
