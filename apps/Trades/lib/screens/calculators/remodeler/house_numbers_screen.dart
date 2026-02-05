import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// House Numbers Calculator - Address number sizing and installation
class HouseNumbersScreen extends ConsumerStatefulWidget {
  const HouseNumbersScreen({super.key});
  @override
  ConsumerState<HouseNumbersScreen> createState() => _HouseNumbersScreenState();
}

class _HouseNumbersScreenState extends ConsumerState<HouseNumbersScreen> {
  final _addressController = TextEditingController(text: '1234');
  final _distanceController = TextEditingController(text: '50');

  String _style = 'floating';
  String _material = 'metal';

  int? _digitCount;
  double? _recommendedHeight;
  double? _totalWidth;
  int? _mountingHardware;

  @override
  void dispose() { _addressController.dispose(); _distanceController.dispose(); super.dispose(); }

  void _calculate() {
    final address = _addressController.text;
    final distance = double.tryParse(_distanceController.text) ?? 50;

    final digitCount = address.length;

    // Visibility rule: 1\" height per 30' of viewing distance
    // Minimum 4\" for residential
    var recommendedHeight = distance / 30;
    if (recommendedHeight < 4) recommendedHeight = 4;
    if (recommendedHeight > 12) recommendedHeight = 12;

    // Total width: digit width (60% of height) + spacing (20% of height)
    final digitWidth = recommendedHeight * 0.6;
    final spacing = recommendedHeight * 0.2;
    final totalWidth = (digitWidth * digitCount) + (spacing * (digitCount - 1));

    // Mounting hardware
    int mountingHardware;
    switch (_style) {
      case 'floating':
        mountingHardware = digitCount * 2; // 2 standoffs per digit
        break;
      case 'flush':
        mountingHardware = digitCount * 2; // 2 screws per digit
        break;
      case 'plaque':
        mountingHardware = 4; // 4 screws for plaque
        break;
      case 'stake':
        mountingHardware = 0; // ground stake
        break;
      default:
        mountingHardware = digitCount * 2;
    }

    setState(() { _digitCount = digitCount; _recommendedHeight = recommendedHeight; _totalWidth = totalWidth; _mountingHardware = mountingHardware; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _addressController.text = '1234'; _distanceController.text = '50'; setState(() { _style = 'floating'; _material = 'metal'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('House Numbers', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MOUNTING STYLE', ['floating', 'flush', 'plaque', 'stake'], _style, {'floating': 'Floating', 'flush': 'Flush', 'plaque': 'Plaque', 'stake': 'Stake'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['metal', 'brass', 'ceramic', 'acrylic'], _material, {'metal': 'Metal', 'brass': 'Brass', 'ceramic': 'Ceramic', 'acrylic': 'Acrylic'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Address Number', unit: '#', controller: _addressController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Viewing Distance', unit: 'feet', controller: _distanceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_digitCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED HEIGHT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_recommendedHeight!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Digits', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_digitCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalWidth!.toStringAsFixed(1)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mounting Hardware', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_mountingHardware! > 0 ? '$_mountingHardware pcs' : 'Included', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Position at 4-5\' height. Contrast with background color. Consider solar-lit numbers for visibility. Check HOA rules.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildVisibilityTable(colors),
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

  Widget _buildVisibilityTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SIZE GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Close walk-up', '4\" height'),
        _buildTableRow(colors, '50\' (driveway)', '4-5\" height'),
        _buildTableRow(colors, '100\' (street)', '6-8\" height'),
        _buildTableRow(colors, '200\' (far view)', '10-12\" height'),
        _buildTableRow(colors, 'Minimum', '4\" per most codes'),
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
