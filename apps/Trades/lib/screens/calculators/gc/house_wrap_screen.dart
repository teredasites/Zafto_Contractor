import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// House Wrap Calculator - Weather resistant barrier
class HouseWrapScreen extends ConsumerStatefulWidget {
  const HouseWrapScreen({super.key});
  @override
  ConsumerState<HouseWrapScreen> createState() => _HouseWrapScreenState();
}

class _HouseWrapScreenState extends ConsumerState<HouseWrapScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _heightController = TextEditingController(text: '9');

  String _wrapType = 'standard';
  String _overlap = '6';

  double? _wallArea;
  int? _rollsNeeded;
  int? _tapeRolls;
  int? _capNails;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final height = double.tryParse(_heightController.text);
    final overlapInches = int.tryParse(_overlap) ?? 6;

    if (perimeter == null || height == null) {
      setState(() { _wallArea = null; _rollsNeeded = null; _tapeRolls = null; _capNails = null; });
      return;
    }

    final wallArea = perimeter * height;

    // Roll sizes vary by type
    // Standard: 9' x 150' = 1350 sq ft
    // Premium: 9' x 100' = 900 sq ft
    // Drainable: 9' x 100' = 900 sq ft
    double rollCoverage;
    switch (_wrapType) {
      case 'standard': rollCoverage = 1350; break;
      case 'premium': rollCoverage = 900; break;
      case 'drainable': rollCoverage = 900; break;
      default: rollCoverage = 1350;
    }

    // Account for overlap waste
    final overlapFactor = 1 + (overlapInches / 12 / 9); // 9' roll width
    final effectiveArea = wallArea * overlapFactor;

    final rollsNeeded = (effectiveArea / rollCoverage).ceil();

    // Seam tape: ~60 LF per roll typical, seams every 9'
    final seamLength = (perimeter / 9).ceil() * height + perimeter; // Vertical seams + bottom
    final tapeRolls = (seamLength / 60).ceil();

    // Cap nails: 1 per sq ft
    final capNails = (wallArea / 100).ceil(); // Per 100 pack

    setState(() { _wallArea = wallArea; _rollsNeeded = rollsNeeded; _tapeRolls = tapeRolls; _capNails = capNails; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _heightController.text = '9'; setState(() { _wrapType = 'standard'; _overlap = '6'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('House Wrap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WRAP TYPE', ['standard', 'premium', 'drainable'], _wrapType, (v) { setState(() => _wrapType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'OVERLAP', ['4', '6', '12'], _overlap, (v) { setState(() => _overlap = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rollsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROLLS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rollsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Seam Tape', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tapeRolls rolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cap Nails (100pk)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_capNails', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getWrapNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getWrapNote() {
    switch (_wrapType) {
      case 'standard': return 'Standard WRB. Lap horizontal seams 4" min, vertical seams 6" min. Tape all seams.';
      case 'premium': return 'Premium (Tyvek HomeWrap/similar). Higher tear strength. Tape all seams and staples.';
      case 'drainable': return 'Drainable wrap has channels for moisture drainage. Required behind reservoir cladding.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'standard': 'Standard', 'premium': 'Premium', 'drainable': 'Drainable'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('${labels[o] ?? o}$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
