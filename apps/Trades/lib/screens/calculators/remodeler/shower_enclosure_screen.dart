import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shower Enclosure Calculator - Shower sizing and materials
class ShowerEnclosureScreen extends ConsumerStatefulWidget {
  const ShowerEnclosureScreen({super.key});
  @override
  ConsumerState<ShowerEnclosureScreen> createState() => _ShowerEnclosureScreenState();
}

class _ShowerEnclosureScreenState extends ConsumerState<ShowerEnclosureScreen> {
  final _widthController = TextEditingController(text: '36');
  final _depthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '84');

  String _type = 'alcove';

  double? _floorSqft;
  double? _wallSqft;
  double? _glassSqft;

  @override
  void dispose() { _widthController.dispose(); _depthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 36;
    final depth = double.tryParse(_depthController.text) ?? 36;
    final height = double.tryParse(_heightController.text) ?? 84;

    // Floor area in sqft
    final floorSqft = (width * depth) / 144;

    // Wall area (3 walls for alcove, 2 for corner, 0 for freestanding)
    int wallCount;
    switch (_type) {
      case 'alcove': wallCount = 3; break;
      case 'corner': wallCount = 2; break;
      case 'walkin': wallCount = 3; break;
      default: wallCount = 3;
    }

    final wallSqft = (((width + depth + (wallCount > 2 ? width : 0)) * height) / 144);

    // Glass for door/panel
    double glassSqft;
    switch (_type) {
      case 'alcove':
        glassSqft = (width * height) / 144; // Door
        break;
      case 'corner':
        glassSqft = ((width + depth) * height) / 144; // Two panels
        break;
      case 'walkin':
        glassSqft = (width * height) / 144 * 0.5; // Partial panel
        break;
      default:
        glassSqft = (width * height) / 144;
    }

    setState(() { _floorSqft = floorSqft; _wallSqft = wallSqft; _glassSqft = glassSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _depthController.text = '36'; _heightController.text = '84'; setState(() => _type = 'alcove'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Shower Enclosure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_floorSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FLOOR AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_floorSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Tile Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Glass Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_glassSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Minimum 30\"x30\" per code. Recommend 36\"x36\". Curbless needs linear drain.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['alcove', 'corner', 'walkin'];
    final labels = {'alcove': 'Alcove', 'corner': 'Corner', 'walkin': 'Walk-in'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SHOWER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SHOWER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Code minimum', '30\" x 30\"'),
        _buildTableRow(colors, 'Standard', '36\" x 36\"'),
        _buildTableRow(colors, 'Comfortable', '42\" x 36\"'),
        _buildTableRow(colors, 'Spacious', '48\" x 36\"'),
        _buildTableRow(colors, 'ADA accessible', '36\" x 60\"'),
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
