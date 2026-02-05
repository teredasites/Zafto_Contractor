import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cistern Calculator - Underground water storage sizing
class CisternScreen extends ConsumerStatefulWidget {
  const CisternScreen({super.key});
  @override
  ConsumerState<CisternScreen> createState() => _CisternScreenState();
}

class _CisternScreenState extends ConsumerState<CisternScreen> {
  final _roofAreaController = TextEditingController(text: '2000');
  final _daysSupplyController = TextEditingController(text: '14');
  final _dailyUseController = TextEditingController(text: '50');

  double? _collectionCapacity;
  double? _usageCapacity;
  double? _recommendedSize;

  @override
  void dispose() { _roofAreaController.dispose(); _daysSupplyController.dispose(); _dailyUseController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 2000;
    final daysSupply = double.tryParse(_daysSupplyController.text) ?? 14;
    final dailyUse = double.tryParse(_dailyUseController.text) ?? 50;

    // Collection capacity: 1" rain on roof area
    // 1" on 1 sq ft = 0.623 gallons × 80% efficiency
    final collectionPerInch = roofArea * 0.623 * 0.8;

    // Usage capacity needed
    final usageNeeded = daysSupply * dailyUse;

    // Recommend the larger of: 2" collection or usage need
    final collectionBased = collectionPerInch * 2;
    final recommended = collectionBased > usageNeeded ? collectionBased : usageNeeded;

    setState(() {
      _collectionCapacity = collectionPerInch;
      _usageCapacity = usageNeeded;
      _recommendedSize = recommended;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '2000'; _daysSupplyController.text = '14'; _dailyUseController.text = '50'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Cistern Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Roof Collection Area', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Days Supply', unit: 'days', controller: _daysSupplyController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Daily Use', unit: 'gal', controller: _dailyUseController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_recommendedSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_recommendedSize!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per 1" rain', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_collectionCapacity!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Usage storage need', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_usageCapacity!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCisternGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCisternGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CISTERN TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Polyethylene', '500-10,000 gal'),
        _buildTableRow(colors, 'Concrete', '1,000-50,000 gal'),
        _buildTableRow(colors, 'Fiberglass', '500-15,000 gal'),
        _buildTableRow(colors, 'Burial depth', '12-24" cover'),
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
