import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sump Pump Calculator - Pump sizing estimation
class SumpPumpScreen extends ConsumerStatefulWidget {
  const SumpPumpScreen({super.key});
  @override
  ConsumerState<SumpPumpScreen> createState() => _SumpPumpScreenState();
}

class _SumpPumpScreenState extends ConsumerState<SumpPumpScreen> {
  final _basementSqftController = TextEditingController(text: '1000');
  final _headController = TextEditingController(text: '10');

  String _waterLevel = 'moderate';
  String _pumpType = 'submersible';

  double? _minGPH;
  double? _recommendedHP;
  double? _pitSize;

  @override
  void dispose() { _basementSqftController.dispose(); _headController.dispose(); super.dispose(); }

  void _calculate() {
    final basementSqft = double.tryParse(_basementSqftController.text) ?? 1000;
    final head = double.tryParse(_headController.text) ?? 10;

    // Base GPH calculation
    double baseGPH;
    switch (_waterLevel) {
      case 'light':
        baseGPH = basementSqft * 1.5;
        break;
      case 'moderate':
        baseGPH = basementSqft * 2.5;
        break;
      case 'heavy':
        baseGPH = basementSqft * 4.0;
        break;
      default:
        baseGPH = basementSqft * 2.5;
    }

    // Adjust for head (vertical lift)
    // Lose ~10% GPH capacity per 10 feet of head
    final headAdjustment = 1 + (head / 100);
    final minGPH = baseGPH * headAdjustment;

    // Recommended HP
    double recommendedHP;
    if (minGPH < 2000) {
      recommendedHP = 0.33;
    } else if (minGPH < 3000) {
      recommendedHP = 0.5;
    } else if (minGPH < 4500) {
      recommendedHP = 0.75;
      } else {
      recommendedHP = 1.0;
    }

    // Pit size: 18" diameter minimum, 24" for heavy duty
    final pitSize = _waterLevel == 'heavy' ? 24.0 : 18.0;

    setState(() { _minGPH = minGPH; _recommendedHP = recommendedHP; _pitSize = pitSize; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _basementSqftController.text = '1000'; _headController.text = '10'; setState(() { _waterLevel = 'moderate'; _pumpType = 'submersible'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sump Pump', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WATER LEVEL', ['light', 'moderate', 'heavy'], _waterLevel, {'light': 'Light', 'moderate': 'Moderate', 'heavy': 'Heavy'}, (v) { setState(() => _waterLevel = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PUMP TYPE', ['submersible', 'pedestal'], _pumpType, {'submersible': 'Submersible', 'pedestal': 'Pedestal'}, (v) { setState(() => _pumpType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Basement Size', unit: 'sq ft', controller: _basementSqftController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Vertical Lift', unit: 'feet', controller: _headController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_minGPH != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_recommendedHP!} HP', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_minGPH!.toStringAsFixed(0)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pit Diameter', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pitSize!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Add battery backup for power outages. Check valve prevents backflow. Test monthly!', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
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
        Text('PUMP SIZING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1/3 HP', '2,000-2,500 GPH'),
        _buildTableRow(colors, '1/2 HP', '2,500-3,500 GPH'),
        _buildTableRow(colors, '3/4 HP', '3,500-5,000 GPH'),
        _buildTableRow(colors, '1 HP', '5,000+ GPH'),
        _buildTableRow(colors, 'Battery backup', 'Strongly recommended'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
