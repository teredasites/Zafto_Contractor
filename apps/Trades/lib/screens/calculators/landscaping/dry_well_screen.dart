import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dry Well Calculator - Size for roof runoff
class DryWellScreen extends ConsumerStatefulWidget {
  const DryWellScreen({super.key});
  @override
  ConsumerState<DryWellScreen> createState() => _DryWellScreenState();
}

class _DryWellScreenState extends ConsumerState<DryWellScreen> {
  final _roofAreaController = TextEditingController(text: '1500');
  final _rainfallController = TextEditingController(text: '1');

  String _wellType = 'plastic';

  double? _gallonsCapacity;
  int? _wellsNeeded;
  double? _gravelCuYd;

  @override
  void dispose() { _roofAreaController.dispose(); _rainfallController.dispose(); super.dispose(); }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 1500;
    final rainfallInches = double.tryParse(_rainfallController.text) ?? 1;

    // Runoff volume = roof area × rainfall × 0.623 gallons/sq ft/inch
    final runoffGallons = roofArea * rainfallInches * 0.623;

    // Well capacity by type
    double gallonsPerWell;
    switch (_wellType) {
      case 'plastic': // Standard 50-gallon dry well kit
        gallonsPerWell = 50;
        break;
      case 'large': // Large plastic unit
        gallonsPerWell = 100;
        break;
      case 'pit': // Gravel pit (4' x 4' x 3')
        gallonsPerWell = 48 * 7.48 * 0.4; // 40% void space
        break;
      default:
        gallonsPerWell = 50;
    }

    final wellsNeeded = (runoffGallons / gallonsPerWell).ceil();

    // Gravel surrounding well
    final gravelCuFt = wellsNeeded * 10; // ~10 cu ft per well
    final gravelCuYd = gravelCuFt / 27;

    setState(() {
      _gallonsCapacity = runoffGallons;
      _wellsNeeded = wellsNeeded;
      _gravelCuYd = gravelCuYd;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _roofAreaController.text = '1500'; _rainfallController.text = '1'; setState(() { _wellType = 'plastic'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dry Well', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WELL TYPE', ['plastic', 'large', 'pit'], _wellType, {'plastic': '50 gal Kit', 'large': '100 gal Unit', 'pit': 'Gravel Pit'}, (v) { setState(() => _wellType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Roof Area Draining', unit: 'sq ft', controller: _roofAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Design Rainfall', unit: 'inches', controller: _rainfallController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('1" design storm handles most events. Use 2" for larger storms.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_gallonsCapacity != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RUNOFF VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallonsCapacity!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wells needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_wellsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drainage gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildInstallGuide(colors),
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

  Widget _buildInstallGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Location', "10'+ from foundation"),
        _buildTableRow(colors, 'Depth', 'Below frost line'),
        _buildTableRow(colors, 'Fabric', 'Wrap gravel in filter fabric'),
        _buildTableRow(colors, 'Inlet', '4" solid pipe from gutter'),
        _buildTableRow(colors, 'Overflow', 'Daylight or secondary well'),
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
