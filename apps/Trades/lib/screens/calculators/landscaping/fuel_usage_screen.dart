import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fuel Usage Calculator - Equipment fuel estimates
class FuelUsageScreen extends ConsumerStatefulWidget {
  const FuelUsageScreen({super.key});
  @override
  ConsumerState<FuelUsageScreen> createState() => _FuelUsageScreenState();
}

class _FuelUsageScreenState extends ConsumerState<FuelUsageScreen> {
  final _hoursController = TextEditingController(text: '8');

  String _equipment = 'mower_ztr';

  double? _gallonsUsed;
  double? _fuelCost;
  double? _gphRate;

  @override
  void dispose() { _hoursController.dispose(); super.dispose(); }

  void _calculate() {
    final hours = double.tryParse(_hoursController.text) ?? 8;

    // Gallons per hour by equipment type
    double gph;
    switch (_equipment) {
      case 'mower_push':
        gph = 0.3;
        break;
      case 'mower_ride':
        gph = 1.0;
        break;
      case 'mower_ztr':
        gph = 1.5;
        break;
      case 'trimmer':
        gph = 0.25;
        break;
      case 'blower':
        gph = 0.4;
        break;
      case 'chainsaw':
        gph = 0.5;
        break;
      case 'skidsteer':
        gph = 2.0;
        break;
      case 'excavator':
        gph = 4.0;
        break;
      default:
        gph = 1.0;
    }

    final gallons = hours * gph;
    final cost = gallons * 3.50; // Assume $3.50/gal

    setState(() {
      _gallonsUsed = gallons;
      _fuelCost = cost;
      _gphRate = gph;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _hoursController.text = '8'; setState(() { _equipment = 'mower_ztr'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fuel Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EQUIPMENT', ['mower_push', 'mower_ride', 'mower_ztr', 'trimmer'], _equipment, {'mower_push': 'Push', 'mower_ride': 'Rider', 'mower_ztr': 'ZTR', 'trimmer': 'Trimmer'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['blower', 'chainsaw', 'skidsteer', 'excavator'], _equipment, {'blower': 'Blower', 'chainsaw': 'Chainsaw', 'skidsteer': 'Skid Steer', 'excavator': 'Excavator'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Operating Hours', unit: 'hrs', controller: _hoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallonsUsed != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FUEL USED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallonsUsed!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Consumption rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gphRate!.toStringAsFixed(2)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. cost (\$3.50/gal)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_fuelCost!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildFuelGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildFuelGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FUEL CONSUMPTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Push mower', '0.2-0.4 GPH'),
        _buildTableRow(colors, 'Zero-turn', '1.0-2.0 GPH'),
        _buildTableRow(colors, 'Skid steer', '1.5-3.0 GPH'),
        _buildTableRow(colors, 'Mini excavator', '2.0-5.0 GPH'),
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
