import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Outdoor Kitchen Calculator - Outdoor kitchen materials estimation
class OutdoorKitchenScreen extends ConsumerStatefulWidget {
  const OutdoorKitchenScreen({super.key});
  @override
  ConsumerState<OutdoorKitchenScreen> createState() => _OutdoorKitchenScreenState();
}

class _OutdoorKitchenScreenState extends ConsumerState<OutdoorKitchenScreen> {
  final _lengthController = TextEditingController(text: '8');
  final _depthController = TextEditingController(text: '3');
  final _heightController = TextEditingController(text: '36');

  String _layout = 'straight';
  String _material = 'block';

  int? _blocks;
  double? _counterSqft;
  int? _studs;
  double? _sheathingSqft;

  @override
  void dispose() { _lengthController.dispose(); _depthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 8;
    final depth = double.tryParse(_depthController.text) ?? 3;
    final height = double.tryParse(_heightController.text) ?? 36;

    final heightFt = height / 12;

    // Calculate linear feet based on layout
    double linearFeet;
    switch (_layout) {
      case 'straight':
        linearFeet = length;
        break;
      case 'l_shape':
        linearFeet = length + depth;
        break;
      case 'u_shape':
        linearFeet = length + (depth * 2);
        break;
      case 'island':
        linearFeet = (length + depth) * 2;
        break;
      default:
        linearFeet = length;
    }

    // Blocks for masonry construction
    // Standard block: 16\" x 8\" face
    final blocksPerLinFt = 12 / 16; // 0.75 blocks per foot horizontally
    final rows = (height / 8).ceil();
    final blocks = (linearFeet * blocksPerLinFt * rows * 1.10).ceil();

    // Counter surface
    final counterSqft = linearFeet * (depth > 2 ? 2.5 : 2); // 24-30\" depth

    // Metal stud frame alternative
    final studsPerFoot = 2; // front and back frame
    final studs = (linearFeet * studsPerFoot + 4).ceil(); // +4 for corners

    // Cement board sheathing
    final sheathingSqft = linearFeet * heightFt * 2 * 1.10; // both sides + waste

    setState(() { _blocks = blocks; _counterSqft = counterSqft; _studs = studs; _sheathingSqft = sheathingSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '8'; _depthController.text = '3'; _heightController.text = '36'; setState(() { _layout = 'straight'; _material = 'block'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Outdoor Kitchen', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LAYOUT', ['straight', 'l_shape', 'u_shape', 'island'], _layout, {'straight': 'Straight', 'l_shape': 'L-Shape', 'u_shape': 'U-Shape', 'island': 'Island'}, (v) { setState(() => _layout = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FRAME', ['block', 'steel_stud', 'wood'], _material, {'block': 'Block', 'steel_stud': 'Steel Stud', 'wood': 'Wood Frame'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'feet', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Counter Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_blocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_material == 'block' ? 'BLOCKS' : 'STUDS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_material == 'block' ? _blocks : _studs}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Counter Surface', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_counterSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_material != 'block') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cement Board', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sheathingSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard counter height: 36\". Bar height: 42\". Use weather-resistant materials. Plan for gas/electric/water runs.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildComponentsTable(colors),
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

  Widget _buildComponentsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Grill', '30-48\" cutout'),
        _buildTableRow(colors, 'Side burner', '12-18\" cutout'),
        _buildTableRow(colors, 'Sink', '15-20\" cutout'),
        _buildTableRow(colors, 'Fridge', '20-24\" cutout'),
        _buildTableRow(colors, 'Access door', '17-20\" cutout'),
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
