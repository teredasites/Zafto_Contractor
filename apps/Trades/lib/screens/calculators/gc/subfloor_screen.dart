import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Subfloor Calculator - OSB/plywood floor sheathing
class SubfloorScreen extends ConsumerStatefulWidget {
  const SubfloorScreen({super.key});
  @override
  ConsumerState<SubfloorScreen> createState() => _SubfloorScreenState();
}

class _SubfloorScreenState extends ConsumerState<SubfloorScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');

  String _sheathingType = 'osb';
  String _thickness = '3/4';
  String _joistSpacing = '16';

  double? _floorArea;
  int? _sheetsNeeded;
  int? _glueTubes;
  int? _screwsLbs;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);

    if (length == null || width == null) {
      setState(() { _floorArea = null; _sheetsNeeded = null; _glueTubes = null; _screwsLbs = null; });
      return;
    }

    final floorArea = length * width;

    // 4x8 sheet = 32 sq ft, add 5% waste (floors have less waste than roofs)
    final sheetsNeeded = ((floorArea / 32) * 1.05).ceil();

    // Subfloor adhesive: one 28oz tube per ~25-30 sq ft
    final glueTubes = (floorArea / 25).ceil();

    // Screws: approximately 1.5 lbs per 100 sq ft (2" deck screws)
    final screwsLbs = (floorArea / 100 * 1.5).ceil();

    setState(() { _floorArea = floorArea; _sheetsNeeded = sheetsNeeded; _glueTubes = glueTubes; _screwsLbs = screwsLbs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _widthController.text = '30'; setState(() { _sheathingType = 'osb'; _thickness = '3/4'; _joistSpacing = '16'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Subfloor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SHEATHING TYPE', ['osb', 'plywood', 'advantech'], _sheathingType, (v) { setState(() => _sheathingType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'THICKNESS', ['5/8', '3/4', '1-1/8'], _thickness, (v) { setState(() => _thickness = v); _calculate(); }, suffix: '"'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'JOIST SPACING', ['12', '16', '19.2', '24'], _joistSpacing, (v) { setState(() => _joistSpacing = v); _calculate(); }, suffix: '" OC'),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sheetsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHEETS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sheetsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_floorArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subfloor Adhesive', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_glueTubes tubes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Screws (2")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_screwsLbs lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getThicknessNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getThicknessNote() {
    if (_joistSpacing == '24') {
      return '24" OC requires min 3/4" T&G. Use 1-1/8" for tile floors. Glue + screw all panels.';
    } else if (_joistSpacing == '19.2') {
      return '19.2" OC (5 sheets span): Min 23/32" T&G. Common with I-joists.';
    }
    return '16" OC: Min 5/8" for carpet, 3/4" for tile. Use T&G edges. Glue + screw.';
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    final labels = {'osb': 'OSB', 'plywood': 'Plywood', 'advantech': 'AdvanTech'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        final displayText = labels[o] ?? o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$displayText$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
