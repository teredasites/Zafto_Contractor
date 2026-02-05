import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rough Opening Calculator - Door/window rough openings
class RoughOpeningScreen extends ConsumerStatefulWidget {
  const RoughOpeningScreen({super.key});
  @override
  ConsumerState<RoughOpeningScreen> createState() => _RoughOpeningScreenState();
}

class _RoughOpeningScreenState extends ConsumerState<RoughOpeningScreen> {
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '80');

  String _unitType = 'door';
  String _frameType = 'standard';

  double? _roWidth;
  double? _roHeight;
  String? _headerSize;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final unitWidth = double.tryParse(_widthController.text);
    final unitHeight = double.tryParse(_heightController.text);

    if (unitWidth == null || unitHeight == null) {
      setState(() { _roWidth = null; _roHeight = null; _headerSize = null; });
      return;
    }

    double roWidth;
    double roHeight;

    switch (_unitType) {
      case 'door':
        // Standard prehung door: add 2" width, 2.5" height
        switch (_frameType) {
          case 'standard':
            roWidth = unitWidth + 2;
            roHeight = unitHeight + 2.5;
            break;
          case 'prehung':
            roWidth = unitWidth + 2.5;
            roHeight = unitHeight + 2.5;
            break;
          case 'pocket':
            roWidth = (unitWidth * 2) + 1;
            roHeight = unitHeight + 2;
            break;
          default:
            roWidth = unitWidth + 2;
            roHeight = unitHeight + 2.5;
        }
        break;
      case 'window':
        // Standard window: add 0.5" each side
        switch (_frameType) {
          case 'standard':
            roWidth = unitWidth + 0.5;
            roHeight = unitHeight + 0.5;
            break;
          case 'new_const':
            roWidth = unitWidth + 0.75;
            roHeight = unitHeight + 0.75;
            break;
          case 'replacement':
            roWidth = unitWidth; // Fit existing RO
            roHeight = unitHeight;
            break;
          default:
            roWidth = unitWidth + 0.5;
            roHeight = unitHeight + 0.5;
        }
        break;
      default:
        roWidth = unitWidth + 2;
        roHeight = unitHeight + 2.5;
    }

    // Header size based on width
    String headerSize;
    if (roWidth <= 36) {
      headerSize = '2-2x6';
    } else if (roWidth <= 48) {
      headerSize = '2-2x8';
    } else if (roWidth <= 60) {
      headerSize = '2-2x10';
    } else if (roWidth <= 72) {
      headerSize = '2-2x12';
    } else {
      headerSize = 'Engineered (LVL)';
    }

    setState(() { _roWidth = roWidth; _roHeight = roHeight; _headerSize = headerSize; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _heightController.text = '80'; setState(() { _unitType = 'door'; _frameType = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rough Opening', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'UNIT TYPE', ['door', 'window'], _unitType, (v) { setState(() { _unitType = v; _frameType = v == 'door' ? 'standard' : 'standard'; }); _calculate(); }),
            const SizedBox(height: 16),
            _buildFrameSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Unit Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Unit Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_roWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROUGH OPENING', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_roWidth!.toStringAsFixed(1)}" x ${_roHeight!.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 22, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RO Width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_roWidth!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RO Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_roHeight!.toStringAsFixed(2)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Header Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_headerSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Verify with manufacturer specs. Add shims for level/plumb. Header spans are for non-bearing walls.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFrameSelector(ZaftoColors colors) {
    List<String> options;
    Map<String, String> labels;
    if (_unitType == 'door') {
      options = ['standard', 'prehung', 'pocket'];
      labels = {'standard': 'Standard', 'prehung': 'Prehung', 'pocket': 'Pocket'};
    } else {
      options = ['standard', 'new_const', 'replacement'];
      labels = {'standard': 'Standard', 'new_const': 'New Const', 'replacement': 'Replacement'};
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FRAME TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _frameType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _frameType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'door': 'Door', 'window': 'Window'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
