import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Storm Window Calculator - Storm window materials estimation
class StormWindowScreen extends ConsumerStatefulWidget {
  const StormWindowScreen({super.key});
  @override
  ConsumerState<StormWindowScreen> createState() => _StormWindowScreenState();
}

class _StormWindowScreenState extends ConsumerState<StormWindowScreen> {
  final _countController = TextEditingController(text: '8');
  final _widthController = TextEditingController(text: '32');
  final _heightController = TextEditingController(text: '54');

  String _type = 'triple_track';
  String _frame = 'aluminum';

  double? _totalSqft;
  double? _caulk;
  int? _screws;
  double? _weatherstrip;

  @override
  void dispose() { _countController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final count = int.tryParse(_countController.text) ?? 8;
    final width = double.tryParse(_widthController.text) ?? 32;
    final height = double.tryParse(_heightController.text) ?? 54;

    final widthFt = width / 12;
    final heightFt = height / 12;

    // Total square footage
    final totalSqft = widthFt * heightFt * count;

    // Caulk: perimeter of each window
    final perimeterFt = (widthFt + heightFt) * 2;
    final caulk = (perimeterFt * count) / 30; // ~30 lin ft per tube

    // Screws: 8-10 per window
    final screws = count * 10;

    // Weatherstrip if interior type
    double weatherstrip;
    if (_type == 'interior') {
      weatherstrip = perimeterFt * count;
    } else {
      weatherstrip = 0;
    }

    setState(() { _totalSqft = totalSqft; _caulk = caulk; _screws = screws; _weatherstrip = weatherstrip; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _countController.text = '8'; _widthController.text = '32'; _heightController.text = '54'; setState(() { _type = 'triple_track'; _frame = 'aluminum'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Storm Window', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['triple_track', 'double_track', 'interior'], _type, {'triple_track': 'Triple Track', 'double_track': 'Double Track', 'interior': 'Interior'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FRAME', ['aluminum', 'wood', 'vinyl'], _frame, {'aluminum': 'Aluminum', 'wood': 'Wood', 'vinyl': 'Vinyl'}, (v) { setState(() => _frame = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Windows', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Caulk', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_caulk!.toStringAsFixed(1)} tubes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mounting Screws', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_screws', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_type == 'interior') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weatherstrip', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weatherstrip!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBenefitsTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_type) {
      case 'triple_track':
        return 'Triple track: 2 glass + 1 screen panel. Full ventilation option. Most common exterior type.';
      case 'double_track':
        return 'Double track: fixed glass + sliding screen. More economical, limited ventilation.';
      case 'interior':
        return 'Interior: mounts inside, magnetic or compression fit. Invisible from outside. DIY-friendly.';
      default:
        return 'Measure window opening width and height. Order 1/8\" smaller for clearance.';
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildBenefitsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STORM WINDOW BENEFITS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Energy savings', '10-25%'),
        _buildTableRow(colors, 'Noise reduction', '25-50%'),
        _buildTableRow(colors, 'Draft blocking', 'Significant'),
        _buildTableRow(colors, 'UV protection', 'Preserves interiors'),
        _buildTableRow(colors, 'ROI', '5-7 years'),
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
