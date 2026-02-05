import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Service Pricing Calculator - Job pricing helper
class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});
  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _lotSizeController = TextEditingController(text: '10000');

  String _serviceType = 'mowing';
  String _difficulty = 'average';

  double? _basePrice;
  double? _adjustedPrice;
  double? _perSqFtRate;

  @override
  void dispose() { _lotSizeController.dispose(); super.dispose(); }

  void _calculate() {
    final lotSize = double.tryParse(_lotSizeController.text) ?? 10000;

    // Base rate per 1000 sq ft
    double basePer1000;
    switch (_serviceType) {
      case 'mowing':
        basePer1000 = 5.0; // $5 per 1000
        break;
      case 'fertilizing':
        basePer1000 = 8.0;
        break;
      case 'aeration':
        basePer1000 = 12.0;
        break;
      case 'mulching':
        basePer1000 = 25.0;
        break;
      case 'cleanup':
        basePer1000 = 10.0;
        break;
      default:
        basePer1000 = 5.0;
    }

    final basePrice = (lotSize / 1000) * basePer1000;

    // Difficulty multiplier
    double multiplier;
    switch (_difficulty) {
      case 'easy':
        multiplier = 0.85;
        break;
      case 'average':
        multiplier = 1.0;
        break;
      case 'difficult':
        multiplier = 1.25;
        break;
      default:
        multiplier = 1.0;
    }

    final adjusted = basePrice * multiplier;

    // Minimum pricing
    final minPrice = _serviceType == 'mowing' ? 35.0 : 50.0;
    final finalPrice = adjusted < minPrice ? minPrice : adjusted;

    setState(() {
      _basePrice = basePrice;
      _adjustedPrice = finalPrice;
      _perSqFtRate = finalPrice / lotSize * 1000;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lotSizeController.text = '10000'; setState(() { _serviceType = 'mowing'; _difficulty = 'average'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Service Pricing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SERVICE', ['mowing', 'fertilizing', 'aeration', 'mulching'], _serviceType, {'mowing': 'Mowing', 'fertilizing': 'Fertilize', 'aeration': 'Aeration', 'mulching': 'Mulch'}, (v) { setState(() => _serviceType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'DIFFICULTY', ['easy', 'average', 'difficult'], _difficulty, {'easy': 'Easy', 'average': 'Average', 'difficult': 'Difficult'}, (v) { setState(() => _difficulty = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lot Size', unit: 'sq ft', controller: _lotSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_adjustedPrice != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SUGGESTED PRICE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_adjustedPrice!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base price', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_basePrice!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rate per 1K sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_perSqFtRate!.toStringAsFixed(2)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Prices are guidelines. Adjust for local market conditions.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 20),
            _buildPricingGuide(colors),
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

  Widget _buildPricingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MARKET RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mowing', '\$35-75 (1/4 acre)'),
        _buildTableRow(colors, 'Fertilizing', '\$60-150'),
        _buildTableRow(colors, 'Aeration', '\$100-200'),
        _buildTableRow(colors, 'Mulch install', '\$3-6 per sq ft'),
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
