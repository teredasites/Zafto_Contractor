import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Window Film Calculator - Window tint/film estimation
class WindowFilmScreen extends ConsumerStatefulWidget {
  const WindowFilmScreen({super.key});
  @override
  ConsumerState<WindowFilmScreen> createState() => _WindowFilmScreenState();
}

class _WindowFilmScreenState extends ConsumerState<WindowFilmScreen> {
  final _windowsController = TextEditingController(text: '6');
  final _heightController = TextEditingController(text: '48');
  final _widthController = TextEditingController(text: '36');

  String _type = 'privacy';

  double? _totalSqft;
  double? _rollLength;
  int? _rolls;

  @override
  void dispose() { _windowsController.dispose(); _heightController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 48;
    final width = double.tryParse(_widthController.text) ?? 36;

    final heightFt = height / 12;
    final widthFt = width / 12;

    // Area per window
    final areaPerWindow = heightFt * widthFt;
    var totalSqft = areaPerWindow * windows;

    // Add 10% waste for trimming
    totalSqft *= 1.10;

    // Rolls: standard is 36" wide x 6.5' long (~19.5 sqft)
    // Some are 36" x 15' (~45 sqft)
    final rollSqft = 19.5;
    final rolls = (totalSqft / rollSqft).ceil();

    // Linear feet needed if buying by the foot
    final rollLength = totalSqft / 3; // Assuming 36" (3') wide

    setState(() { _totalSqft = totalSqft; _rollLength = rollLength; _rolls = rolls; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowsController.text = '6'; _heightController.text = '48'; _widthController.text = '36'; setState(() => _type = 'privacy'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Window Film', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FILM NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Small Rolls (6.5\')', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rolls', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Linear Feet (36\" wide)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rollLength!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Spray soapy water on glass for positioning. Squeegee from center out. Trim with razor blade.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['privacy', 'solar', 'decorative', 'security'];
    final labels = {'privacy': 'Privacy', 'solar': 'Solar', 'decorative': 'Decorative', 'security': 'Security'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FILM TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FILM TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Privacy/frost', 'Blocks view, allows light'),
        _buildTableRow(colors, 'Solar/tint', 'Reduces heat, UV'),
        _buildTableRow(colors, 'Decorative', 'Patterns, stained glass'),
        _buildTableRow(colors, 'Security', 'Shatter resistant'),
        _buildTableRow(colors, 'Mirror', 'One-way daytime'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
