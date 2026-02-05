import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Irrigation Valve Calculator - Valve sizing
class IrrigationValveScreen extends ConsumerStatefulWidget {
  const IrrigationValveScreen({super.key});
  @override
  ConsumerState<IrrigationValveScreen> createState() => _IrrigationValveScreenState();
}

class _IrrigationValveScreenState extends ConsumerState<IrrigationValveScreen> {
  final _gpmController = TextEditingController(text: '15');

  String _pipeSize = '1';

  String? _recommendedValve;
  String? _maxGpm;
  String? _notes;

  @override
  void dispose() { _gpmController.dispose(); super.dispose(); }

  void _calculate() {
    final gpm = double.tryParse(_gpmController.text) ?? 15;
    final pipeIn = double.tryParse(_pipeSize) ?? 1;

    // Valve sizing based on flow and pipe
    String valve;
    String maxGpm;
    String notes;

    if (pipeIn <= 0.75) {
      valve = '3/4\"';
      maxGpm = '12 GPM';
      notes = 'Small zones, drip systems';
    } else if (pipeIn <= 1) {
      if (gpm <= 20) {
        valve = '1\"';
        maxGpm = '20 GPM';
        notes = 'Standard residential';
      } else {
        valve = '1\" (multiple zones)';
        maxGpm = '20 GPM';
        notes = 'Split into multiple zones';
      }
    } else if (pipeIn <= 1.5) {
      valve = '1-1/2\"';
      maxGpm = '40 GPM';
      notes = 'Large residential, commercial';
    } else {
      valve = '2\"';
      maxGpm = '60 GPM';
      notes = 'Commercial, large areas';
    }

    setState(() {
      _recommendedValve = valve;
      _maxGpm = maxGpm;
      _notes = notes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _gpmController.text = '15'; setState(() { _pipeSize = '1'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Valve Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MAINLINE SIZE', ['0.75', '1', '1.5', '2'], _pipeSize, {'0.75': '3/4\"', '1': '1\"', '1.5': '1-1/2\"', '2': '2\"'}, (v) { setState(() => _pipeSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Zone Flow', unit: 'GPM', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedValve != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED VALVE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_recommendedValve', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max flow', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_maxGpm', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Application', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_notes', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildValveGuide(colors),
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

  Widget _buildValveGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VALVE FLOW CAPACITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '3/4\" valve', '5-12 GPM'),
        _buildTableRow(colors, '1\" valve', '10-20 GPM'),
        _buildTableRow(colors, '1-1/2\" valve', '20-40 GPM'),
        _buildTableRow(colors, '2\" valve', '35-60 GPM'),
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
