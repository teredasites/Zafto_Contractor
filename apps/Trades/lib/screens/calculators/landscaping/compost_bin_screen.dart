import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compost Bin Calculator - Bin sizing
class CompostBinScreen extends ConsumerStatefulWidget {
  const CompostBinScreen({super.key});
  @override
  ConsumerState<CompostBinScreen> createState() => _CompostBinScreenState();
}

class _CompostBinScreenState extends ConsumerState<CompostBinScreen> {
  final _gardenSizeController = TextEditingController(text: '500');
  final _yardWasteController = TextEditingController(text: '3');

  double? _binCuFt;
  String? _recommendedSize;
  double? _compostYield;
  int? _turningWeeks;

  @override
  void dispose() { _gardenSizeController.dispose(); _yardWasteController.dispose(); super.dispose(); }

  void _calculate() {
    final gardenSize = double.tryParse(_gardenSizeController.text) ?? 500;
    final yardWasteBags = double.tryParse(_yardWasteController.text) ?? 3;

    // Weekly waste × 12 weeks = batch volume
    // 1 yard waste bag ≈ 3 cu ft
    final weeklyWaste = yardWasteBags * 3;
    final batchVolume = weeklyWaste * 12;

    // Bin should be at least 3'×3'×3' = 27 cu ft minimum for proper heating
    final minBin = 27.0;
    final recommendedBin = batchVolume > minBin ? batchVolume : minBin;

    String size;
    if (recommendedBin <= 27) {
      size = "3' × 3' × 3'";
    } else if (recommendedBin <= 48) {
      size = "4' × 4' × 3'";
    } else if (recommendedBin <= 64) {
      size = "4' × 4' × 4'";
    } else {
      size = "Multiple bins";
    }

    // Compost yield: ~50% of input volume
    final yield1 = recommendedBin * 0.5;

    // Turning schedule
    const weeks = 12; // 3 months typical

    setState(() {
      _binCuFt = recommendedBin;
      _recommendedSize = size;
      _compostYield = yield1;
      _turningWeeks = weeks;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _gardenSizeController.text = '500'; _yardWasteController.text = '3'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compost Bin', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Garden Size', unit: 'sq ft', controller: _gardenSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Weekly Yard Waste', unit: 'bags', controller: _yardWasteController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_binCuFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_recommendedSize', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_binCuFt!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Compost yield', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_compostYield!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ready in', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_turningWeeks weeks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCompostGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCompostGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMPOSTING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Browns:Greens', '3:1 ratio'),
        _buildTableRow(colors, 'Turn pile', 'Every 1-2 weeks'),
        _buildTableRow(colors, 'Moisture', 'Damp sponge feel'),
        _buildTableRow(colors, 'Min size', "3' × 3' × 3'"),
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
