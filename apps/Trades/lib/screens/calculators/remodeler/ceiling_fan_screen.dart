import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ceiling Fan Calculator - Fan size and placement estimation
class CeilingFanScreen extends ConsumerStatefulWidget {
  const CeilingFanScreen({super.key});
  @override
  ConsumerState<CeilingFanScreen> createState() => _CeilingFanScreenState();
}

class _CeilingFanScreenState extends ConsumerState<CeilingFanScreen> {
  final _lengthController = TextEditingController(text: '14');
  final _widthController = TextEditingController(text: '12');
  final _ceilingController = TextEditingController(text: '9');

  String _mount = 'standard';

  int? _fanSize;
  int? _fanCount;
  double? _downrod;
  double? _clearance;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _ceilingController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final ceiling = double.tryParse(_ceilingController.text) ?? 9;

    final sqft = length * width;

    // Fan size based on room size
    int fanSize;
    if (sqft <= 75) {
      fanSize = 36;
    } else if (sqft <= 144) {
      fanSize = 42;
    } else if (sqft <= 225) {
      fanSize = 52;
    } else if (sqft <= 400) {
      fanSize = 56;
    } else {
      fanSize = 72;
    }

    // Multiple fans for large rooms
    int fanCount;
    if (sqft > 400) {
      fanCount = (sqft / 400).ceil();
    } else {
      fanCount = 1;
    }

    // Downrod length: blade bottom should be 8-9' from floor, 10-12" from ceiling
    // Target: 8.5' from floor
    double downrod;
    final targetHeight = 8.5;
    final mountHeight = ceiling - targetHeight;

    if (_mount == 'flush') {
      downrod = 0;
    } else if (_mount == 'standard') {
      downrod = mountHeight > 0 ? mountHeight * 12 : 0; // Convert to inches
      if (downrod < 3) downrod = 3; // Minimum standard
    } else {
      // Low profile for low ceilings
      downrod = 0;
    }

    // Blade clearance from floor
    final clearance = ceiling - (downrod / 12) - 1; // 1' for fan body

    setState(() { _fanSize = fanSize; _fanCount = fanCount; _downrod = downrod; _clearance = clearance; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '14'; _widthController.text = '12'; _ceilingController.text = '9'; setState(() => _mount = 'standard'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ceiling Fan', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Room Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Room Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _ceilingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fanSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fanSize\"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Number of Fans', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_fanCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Downrod Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_downrod!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Floor Clearance', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_clearance!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Min 7\' clearance from floor. 18\" from walls. Use fan-rated box (35 lb min).', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['flush', 'standard', 'low'];
    final labels = {'flush': 'Flush Mount', 'standard': 'Downrod', 'low': 'Low Profile'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MOUNT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _mount == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _mount = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
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
        Text('FAN SIZE BY ROOM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Up to 75 sq ft', '29-36\"'),
        _buildTableRow(colors, '76-144 sq ft', '36-42\"'),
        _buildTableRow(colors, '145-225 sq ft', '44-52\"'),
        _buildTableRow(colors, '225-400 sq ft', '52-56\"'),
        _buildTableRow(colors, '400+ sq ft', '56-72\" or 2 fans'),
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
