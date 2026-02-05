import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rip Rap Calculator - Stone for erosion control
class RipRapScreen extends ConsumerStatefulWidget {
  const RipRapScreen({super.key});
  @override
  ConsumerState<RipRapScreen> createState() => _RipRapScreenState();
}

class _RipRapScreenState extends ConsumerState<RipRapScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _widthController = TextEditingController(text: '6');

  String _stoneSize = 'medium';
  String _depthIn = '12';

  double? _areaSqFt;
  double? _volumeCuYd;
  double? _tonsNeeded;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final width = double.tryParse(_widthController.text) ?? 6;
    final depth = double.tryParse(_depthIn) ?? 12;

    final area = length * width;
    final depthFt = depth / 12;
    final volumeCuFt = area * depthFt;
    final volumeCuYd = volumeCuFt / 27;

    // Rip rap weight varies by size (tons per cubic yard)
    double tonsPerCuYd;
    switch (_stoneSize) {
      case 'small': // 4-8"
        tonsPerCuYd = 1.3;
        break;
      case 'medium': // 8-12"
        tonsPerCuYd = 1.25;
        break;
      case 'large': // 12-18"
        tonsPerCuYd = 1.2;
        break;
      default:
        tonsPerCuYd = 1.25;
    }

    final tons = volumeCuYd * tonsPerCuYd;

    setState(() {
      _areaSqFt = area;
      _volumeCuYd = volumeCuYd;
      _tonsNeeded = tons;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _widthController.text = '6'; setState(() { _stoneSize = 'medium'; _depthIn = '12'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rip Rap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STONE SIZE', ['small', 'medium', 'large'], _stoneSize, {'small': '4-8\"', 'medium': '8-12\"', 'large': '12-18\"'}, (v) { setState(() => _stoneSize = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'DEPTH', ['6', '12', '18', '24'], _depthIn, {'6': '6\"', '12': '12\"', '18': '18\"', '24': '24\"'}, (v) { setState(() => _depthIn = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_tonsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RIP RAP NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tonsNeeded!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_areaSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRipRapGuide(colors),
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

  Widget _buildRipRapGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Drainage swales', '8-12\" stone'),
        _buildTableRow(colors, 'Stream banks', '12-18\" stone'),
        _buildTableRow(colors, 'Culvert outlets', '12-24\" stone'),
        _buildTableRow(colors, 'Filter fabric', 'Required under'),
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
