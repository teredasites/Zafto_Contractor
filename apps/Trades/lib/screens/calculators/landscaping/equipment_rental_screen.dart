import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Equipment Rental Calculator - Rental costs and markup
class EquipmentRentalScreen extends ConsumerStatefulWidget {
  const EquipmentRentalScreen({super.key});
  @override
  ConsumerState<EquipmentRentalScreen> createState() => _EquipmentRentalScreenState();
}

class _EquipmentRentalScreenState extends ConsumerState<EquipmentRentalScreen> {
  final _daysController = TextEditingController(text: '1');

  String _equipment = 'skidsteer';
  String _rentalPeriod = 'day';

  double? _rentalCost;
  double? _deliveryCost;
  double? _fuelCost;
  double? _customerCharge;

  @override
  void dispose() { _daysController.dispose(); super.dispose(); }

  void _calculate() {
    final days = double.tryParse(_daysController.text) ?? 1;

    // Base rental rates (daily)
    double dailyRate;
    double delivery;
    double fuelPerDay;

    switch (_equipment) {
      case 'skidsteer':
        dailyRate = 275;
        delivery = 150;
        fuelPerDay = 50;
        break;
      case 'mini_ex':
        dailyRate = 325;
        delivery = 175;
        fuelPerDay = 40;
        break;
      case 'dingo':
        dailyRate = 175;
        delivery = 100;
        fuelPerDay = 25;
        break;
      case 'sod_cutter':
        dailyRate = 95;
        delivery = 50;
        fuelPerDay = 15;
        break;
      case 'stump_grinder':
        dailyRate = 200;
        delivery = 75;
        fuelPerDay = 20;
        break;
      case 'aerator':
        dailyRate = 85;
        delivery = 50;
        fuelPerDay = 10;
        break;
      default:
        dailyRate = 200;
        delivery = 100;
        fuelPerDay = 30;
    }

    // Period discounts
    double periodMult;
    switch (_rentalPeriod) {
      case 'half':
        periodMult = 0.6;
        break;
      case 'day':
        periodMult = 1.0;
        break;
      case 'week':
        periodMult = 4.0; // Week = 4 day rate
        break;
      case 'month':
        periodMult = 12.0; // Month = 12 day rate
        break;
      default:
        periodMult = 1.0;
    }

    final actualDays = _rentalPeriod == 'half' ? 0.5 : (_rentalPeriod == 'week' ? 7 : (_rentalPeriod == 'month' ? 30 : days));
    final rental = dailyRate * periodMult * days;
    final fuel = fuelPerDay * actualDays * days;
    final total = rental + delivery + fuel;
    final customerCharge = total * 1.25; // 25% markup

    setState(() {
      _rentalCost = rental;
      _deliveryCost = delivery;
      _fuelCost = fuel;
      _customerCharge = customerCharge;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _daysController.text = '1'; setState(() { _equipment = 'skidsteer'; _rentalPeriod = 'day'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Equipment Rental', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EQUIPMENT', ['skidsteer', 'mini_ex', 'dingo'], _equipment, {'skidsteer': 'Skid Steer', 'mini_ex': 'Mini Ex', 'dingo': 'Dingo'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['sod_cutter', 'stump_grinder', 'aerator'], _equipment, {'sod_cutter': 'Sod Cutter', 'stump_grinder': 'Stump Grind', 'aerator': 'Aerator'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'RENTAL PERIOD', ['half', 'day', 'week', 'month'], _rentalPeriod, {'half': 'Half Day', 'day': 'Day', 'week': 'Week', 'month': 'Month'}, (v) { setState(() => _rentalPeriod = v); _calculate(); }),
            const SizedBox(height: 20),
            if (_rentalPeriod == 'day') ZaftoInputField(label: 'Number of Days', unit: 'days', controller: _daysController, onChanged: (_) => _calculate()),
            if (_rentalPeriod == 'day') const SizedBox(height: 32),
            if (_rentalPeriod != 'day') const SizedBox(height: 12),
            if (_customerCharge != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CHARGE CUSTOMER', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_customerCharge!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rental cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_rentalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_deliveryCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. fuel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_fuelCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Markup', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('25%', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRentalGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildRentalGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RENTAL TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Book ahead', 'Weekends fill fast'),
        _buildTableRow(colors, 'Weekly rate', 'Usually 4x daily'),
        _buildTableRow(colors, 'Damage waiver', 'Consider 10-15%'),
        _buildTableRow(colors, 'Fuel policy', 'Return full'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
