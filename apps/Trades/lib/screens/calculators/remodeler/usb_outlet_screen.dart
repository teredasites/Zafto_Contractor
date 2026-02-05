import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// USB Outlet Calculator - USB outlet planning estimation
class UsbOutletScreen extends ConsumerStatefulWidget {
  const UsbOutletScreen({super.key});
  @override
  ConsumerState<UsbOutletScreen> createState() => _UsbOutletScreenState();
}

class _UsbOutletScreenState extends ConsumerState<UsbOutletScreen> {
  final _bedroomController = TextEditingController(text: '2');
  final _livingController = TextEditingController(text: '2');
  final _kitchenController = TextEditingController(text: '1');
  final _officeController = TextEditingController(text: '2');

  String _usbType = 'a_c';
  String _amperage = '4.8';

  int? _totalOutlets;
  double? _totalAmps;
  String? _bestLocations;

  @override
  void dispose() { _bedroomController.dispose(); _livingController.dispose(); _kitchenController.dispose(); _officeController.dispose(); super.dispose(); }

  void _calculate() {
    final bedroom = int.tryParse(_bedroomController.text) ?? 2;
    final living = int.tryParse(_livingController.text) ?? 2;
    final kitchen = int.tryParse(_kitchenController.text) ?? 1;
    final office = int.tryParse(_officeController.text) ?? 2;

    final totalOutlets = bedroom + living + kitchen + office;

    // USB amperage
    final amps = double.tryParse(_amperage) ?? 4.8;
    final totalAmps = totalOutlets * amps;

    // Best locations based on counts
    final locations = <String>[];
    if (bedroom > 0) locations.add('bedside tables');
    if (living > 0) locations.add('near seating');
    if (kitchen > 0) locations.add('counter charging spot');
    if (office > 0) locations.add('desk area');
    final bestLocations = locations.join(', ');

    setState(() { _totalOutlets = totalOutlets; _totalAmps = totalAmps; _bestLocations = bestLocations; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _bedroomController.text = '2'; _livingController.text = '2'; _kitchenController.text = '1'; _officeController.text = '2'; setState(() { _usbType = 'a_c'; _amperage = '4.8'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('USB Outlet', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'USB PORTS', ['a_only', 'c_only', 'a_c'], _usbType, {'a_only': 'USB-A Only', 'c_only': 'USB-C Only', 'a_c': 'USB-A + C'}, (v) { setState(() => _usbType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'AMPERAGE', ['3.6', '4.8', '6.0'], _amperage, {'3.6': '3.6A', '4.8': '4.8A', '6.0': '6.0A'}, (v) { setState(() => _amperage = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bedrooms', unit: 'qty', controller: _bedroomController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Living Areas', unit: 'qty', controller: _livingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Kitchen', unit: 'qty', controller: _kitchenController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Office', unit: 'qty', controller: _officeController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalOutlets != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('USB OUTLETS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalOutlets', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total USB Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalAmps!.toStringAsFixed(1)}A', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Best Locations', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_bestLocations!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpecsTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_usbType) {
      case 'a_only':
        return 'USB-A: compatible with most cables. Being phased out. Good for older devices.';
      case 'c_only':
        return 'USB-C: future-proof, faster charging. Supports USB-PD for laptops. Recommended for new installs.';
      case 'a_c':
        return 'USB-A+C combo: best versatility. Covers all current devices. Most popular choice.';
      default:
        return 'USB outlets fit standard boxes. Replace existing outlets for easy upgrade.';
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSpecsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('USB CHARGING SPEEDS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '2.4A', 'Standard phone'),
        _buildTableRow(colors, '3.6A', 'Fast charge'),
        _buildTableRow(colors, '4.8A', 'Dual device fast'),
        _buildTableRow(colors, '6.0A / PD', 'Tablet/laptop'),
        _buildTableRow(colors, 'USB-C PD', 'Up to 100W'),
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
