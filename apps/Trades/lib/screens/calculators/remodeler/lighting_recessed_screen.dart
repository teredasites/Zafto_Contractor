import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Recessed Lighting Calculator - Can light layout estimation
class LightingRecessedScreen extends ConsumerStatefulWidget {
  const LightingRecessedScreen({super.key});
  @override
  ConsumerState<LightingRecessedScreen> createState() => _LightingRecessedScreenState();
}

class _LightingRecessedScreenState extends ConsumerState<LightingRecessedScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '12');
  final _ceilingController = TextEditingController(text: '8');

  String _size = '6inch';
  String _purpose = 'general';

  int? _lights;
  double? _spacing;
  double? _wallOffset;
  int? _rows;
  int? _cols;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _ceilingController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final ceiling = double.tryParse(_ceilingController.text) ?? 8;

    // Spacing rule: ceiling height / 2 for general, closer for task
    double spacingMultiplier;
    switch (_purpose) {
      case 'general':
        spacingMultiplier = 0.5;
        break;
      case 'task':
        spacingMultiplier = 0.4;
        break;
      case 'accent':
        spacingMultiplier = 0.6;
        break;
      default:
        spacingMultiplier = 0.5;
    }

    final spacing = ceiling * spacingMultiplier;

    // Wall offset: spacing / 2
    final wallOffset = spacing / 2;

    // Calculate grid
    final effectiveLength = length - (wallOffset * 2);
    final effectiveWidth = width - (wallOffset * 2);

    final cols = (effectiveLength / spacing).ceil() + 1;
    final rows = (effectiveWidth / spacing).ceil() + 1;

    final lights = rows * cols;

    setState(() { _lights = lights; _spacing = spacing; _wallOffset = wallOffset; _rows = rows; _cols = cols; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '12'; _ceilingController.text = '8'; setState(() { _size = '6inch'; _purpose = 'general'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Recessed Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SIZE', ['4inch', '5inch', '6inch'], _size, {'4inch': '4\"', '5inch': '5\"', '6inch': '6\"'}, (v) { setState(() => _size = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PURPOSE', ['general', 'task', 'accent'], _purpose, {'general': 'General', 'task': 'Task', 'accent': 'Accent'}, (v) { setState(() => _purpose = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Room Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _ceilingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lights != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LIGHTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_lights', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grid Layout', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rows x $_cols', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_spacing!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Offset', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallOffset!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Rule: Spacing = ceiling height / 2. Wall offset = spacing / 2. Use IC rated if insulation above.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTrimTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTrimTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRIM TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Baffle', 'General, reduces glare'),
        _buildTableRow(colors, 'Reflector', 'Max light output'),
        _buildTableRow(colors, 'Eyeball', 'Directional, accent'),
        _buildTableRow(colors, 'Wall wash', 'Even wall illumination'),
        _buildTableRow(colors, 'Pinhole', 'Accent, display'),
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
