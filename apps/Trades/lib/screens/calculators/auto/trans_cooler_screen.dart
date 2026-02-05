import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trans Cooler Sizing Calculator - Transmission cooler sizing
class TransCoolerScreen extends ConsumerStatefulWidget {
  const TransCoolerScreen({super.key});
  @override
  ConsumerState<TransCoolerScreen> createState() => _TransCoolerScreenState();
}

class _TransCoolerScreenState extends ConsumerState<TransCoolerScreen> {
  final _gvwController = TextEditingController();
  final _towingController = TextEditingController(text: '0');
  final _hpController = TextEditingController();

  String _useCase = 'street';

  double? _minBtu;
  double? _recommendedBtu;
  String? _coolerSize;
  String? _recommendation;

  void _calculate() {
    final gvw = double.tryParse(_gvwController.text);
    final towing = double.tryParse(_towingController.text) ?? 0;
    final hp = double.tryParse(_hpController.text);

    if (gvw == null) {
      setState(() { _minBtu = null; });
      return;
    }

    // Total weight factor
    final totalWeight = gvw + towing;

    // Base BTU calculation
    // Rule of thumb: ~1 BTU per pound of combined weight for basic cooling
    double baseBtu = totalWeight * 1.0;

    // Adjust for use case
    double multiplier;
    switch (_useCase) {
      case 'towing':
        multiplier = 1.5;
        break;
      case 'performance':
        multiplier = 1.75;
        break;
      case 'racing':
        multiplier = 2.0;
        break;
      default: // street
        multiplier = 1.0;
    }

    // Additional HP adjustment (high power = more heat)
    if (hp != null && hp > 300) {
      baseBtu += (hp - 300) * 15;
    }

    final minBtu = baseBtu;
    final recommendedBtu = baseBtu * multiplier;

    String size;
    String recommendation;

    if (recommendedBtu < 15000) {
      size = 'Small (8" x 5")';
      recommendation = 'Compact auxiliary cooler, light-duty use';
    } else if (recommendedBtu < 25000) {
      size = 'Medium (11" x 6")';
      recommendation = 'Standard auxiliary cooler, moderate towing';
    } else if (recommendedBtu < 40000) {
      size = 'Large (15" x 7.5")';
      recommendation = 'Heavy-duty cooler, regular towing/performance';
    } else {
      size = 'XL/Stacked (18"+ or dual)';
      recommendation = 'Maximum cooling for racing or heavy towing';
    }

    setState(() {
      _minBtu = minBtu;
      _recommendedBtu = recommendedBtu;
      _coolerSize = size;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gvwController.clear();
    _towingController.text = '0';
    _hpController.clear();
    setState(() {
      _useCase = 'street';
      _minBtu = null;
    });
  }

  @override
  void dispose() {
    _gvwController.dispose();
    _towingController.dispose();
    _hpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trans Cooler Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vehicle GVW', unit: 'lbs', hint: 'Gross vehicle weight', controller: _gvwController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Towing Weight', unit: 'lbs', hint: 'Trailer + cargo', controller: _towingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine HP', unit: 'HP', hint: 'Optional', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildUseCaseSelector(colors),
            const SizedBox(height: 32),
            if (_minBtu != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildUseCaseSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Primary Use', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        _buildUseCaseChip(colors, 'street', 'Street'),
        _buildUseCaseChip(colors, 'towing', 'Towing'),
        _buildUseCaseChip(colors, 'performance', 'Performance'),
        _buildUseCaseChip(colors, 'racing', 'Racing'),
      ]),
    ]);
  }

  Widget _buildUseCaseChip(ZaftoColors colors, String value, String label) {
    final isSelected = _useCase == value;
    return GestureDetector(
      onTap: () {
        setState(() { _useCase = value; });
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('BTU ≈ Total Weight × Use Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Keep trans temp under 200°F for longevity', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended Capacity', '${(_recommendedBtu! / 1000).toStringAsFixed(1)}k BTU', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Minimum Capacity', '${(_minBtu! / 1000).toStringAsFixed(1)}k BTU'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cooler Size', _coolerSize!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Always use a transmission temp gauge when towing', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
