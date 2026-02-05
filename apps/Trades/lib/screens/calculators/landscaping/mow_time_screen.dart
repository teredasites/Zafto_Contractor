import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mow Time Calculator - Mowing time by equipment
class MowTimeScreen extends ConsumerStatefulWidget {
  const MowTimeScreen({super.key});
  @override
  ConsumerState<MowTimeScreen> createState() => _MowTimeScreenState();
}

class _MowTimeScreenState extends ConsumerState<MowTimeScreen> {
  final _areaController = TextEditingController(text: '20000');

  String _mowerType = 'zturn_52';
  String _terrain = 'open';

  double? _mowTime;
  double? _trimTime;
  double? _blowTime;
  double? _totalTime;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 20000;

    // Mower productivity (sq ft per hour)
    double sqFtPerHour;
    switch (_mowerType) {
      case 'push_21':
        sqFtPerHour = 10000;
        break;
      case 'wb_36':
        sqFtPerHour = 25000;
        break;
      case 'wb_48':
        sqFtPerHour = 35000;
        break;
      case 'zturn_52':
        sqFtPerHour = 60000;
        break;
      case 'zturn_60':
        sqFtPerHour = 75000;
        break;
      case 'zturn_72':
        sqFtPerHour = 90000;
        break;
      default:
        sqFtPerHour = 60000;
    }

    // Terrain multiplier
    double terrainMult;
    switch (_terrain) {
      case 'open':
        terrainMult = 1.0;
        break;
      case 'moderate':
        terrainMult = 1.3;
        break;
      case 'obstacles':
        terrainMult = 1.6;
        break;
      case 'hills':
        terrainMult = 1.8;
        break;
      default:
        terrainMult = 1.0;
    }

    final mowHours = (area / sqFtPerHour) * terrainMult;
    final mowMinutes = mowHours * 60;

    // Trim time: roughly 15% of mow time
    final trimMinutes = mowMinutes * 0.15;

    // Blow time: roughly 10% of mow time
    final blowMinutes = mowMinutes * 0.10;

    final totalMinutes = mowMinutes + trimMinutes + blowMinutes;

    setState(() {
      _mowTime = mowMinutes;
      _trimTime = trimMinutes;
      _blowTime = blowMinutes;
      _totalTime = totalMinutes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '20000'; setState(() { _mowerType = 'zturn_52'; _terrain = 'open'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mow Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MOWER TYPE', ['push_21', 'wb_36', 'wb_48'], _mowerType, {'push_21': 'Push 21\"', 'wb_36': 'WB 36\"', 'wb_48': 'WB 48\"'}, (v) { setState(() => _mowerType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['zturn_52', 'zturn_60', 'zturn_72'], _mowerType, {'zturn_52': 'ZTR 52\"', 'zturn_60': 'ZTR 60\"', 'zturn_72': 'ZTR 72\"'}, (v) { setState(() => _mowerType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'TERRAIN', ['open', 'moderate', 'obstacles', 'hills'], _terrain, {'open': 'Open', 'moderate': 'Moderate', 'obstacles': 'Obstacles', 'hills': 'Hilly'}, (v) { setState(() => _terrain = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalTime != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mowing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mowTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trimming', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_trimTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Blowing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_blowTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMowerGuide(colors),
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

  Widget _buildMowerGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MOWER PRODUCTIVITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Push 21\"', '~10K sq ft/hr'),
        _buildTableRow(colors, 'Walk-behind', '25-35K sq ft/hr'),
        _buildTableRow(colors, 'ZTR 52-60\"', '60-75K sq ft/hr'),
        _buildTableRow(colors, 'ZTR 72\"', '~90K sq ft/hr'),
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
