import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Caulking Calculator - Sealant and caulk estimation
class CaulkingScreen extends ConsumerStatefulWidget {
  const CaulkingScreen({super.key});
  @override
  ConsumerState<CaulkingScreen> createState() => _CaulkingScreenState();
}

class _CaulkingScreenState extends ConsumerState<CaulkingScreen> {
  final _windowsController = TextEditingController(text: '10');
  final _doorsController = TextEditingController(text: '4');
  final _trimController = TextEditingController(text: '200');

  String _application = 'exterior';

  int? _tubesNeeded;
  String? _caulkType;
  double? _linearFeet;

  @override
  void dispose() { _windowsController.dispose(); _doorsController.dispose(); _trimController.dispose(); super.dispose(); }

  void _calculate() {
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final trim = double.tryParse(_trimController.text) ?? 0;

    // Linear feet per window/door
    // Window perimeter: ~12 lf avg
    // Door perimeter: ~16 lf avg
    final windowLF = windows * 12.0;
    final doorLF = doors * 16.0;
    final totalLF = windowLF + doorLF + trim;

    // 1 tube = ~25-30 lf at 1/4" bead
    final tubesNeeded = (totalLF / 28).ceil();

    // Caulk type recommendation
    String caulkType;
    switch (_application) {
      case 'exterior':
        caulkType = 'Polyurethane or Silicone';
        break;
      case 'interior':
        caulkType = 'Latex or Acrylic';
        break;
      case 'bathroom':
        caulkType = 'Silicone (mold resistant)';
        break;
      case 'concrete':
        caulkType = 'Polyurethane';
        break;
      default:
        caulkType = 'Multi-purpose';
    }

    setState(() { _tubesNeeded = tubesNeeded < 1 ? 1 : tubesNeeded; _caulkType = caulkType; _linearFeet = totalLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowsController.text = '10'; _doorsController.text = '4'; _trimController.text = '200'; setState(() => _application = 'exterior'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Caulking', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Trim/Other Joints', unit: 'linear ft', controller: _trimController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tubesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TUBES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tubesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recommended Type', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_caulkType!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('1/4\" bead typical. Clean surfaces first. Backer rod for gaps > 1/2\".', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCaulkTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['exterior', 'interior', 'bathroom', 'concrete'];
    final labels = {'exterior': 'Exterior', 'interior': 'Interior', 'bathroom': 'Bath/Kitchen', 'concrete': 'Concrete'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('APPLICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _application == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _application = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildCaulkTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CAULK TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Latex/Acrylic', 'Interior, paintable'),
        _buildTableRow(colors, 'Silicone', 'Wet areas, flexible'),
        _buildTableRow(colors, 'Polyurethane', 'Exterior, durable'),
        _buildTableRow(colors, 'Butyl', 'Gutters, metal'),
        _buildTableRow(colors, 'Fire caulk', 'Penetrations, rated'),
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
