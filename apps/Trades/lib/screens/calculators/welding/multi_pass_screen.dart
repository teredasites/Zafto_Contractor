import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Multi-Pass Calculator - Number of passes for thick welds
class MultiPassScreen extends ConsumerStatefulWidget {
  const MultiPassScreen({super.key});
  @override
  ConsumerState<MultiPassScreen> createState() => _MultiPassScreenState();
}

class _MultiPassScreenState extends ConsumerState<MultiPassScreen> {
  final _thicknessController = TextEditingController();
  final _legSizeController = TextEditingController();
  String _weldType = 'Fillet';
  String _process = 'SMAW';

  int? _numberOfPasses;
  double? _areaPerPass;
  String? _sequence;
  String? _notes;

  // Typical single pass deposit area by process
  static const Map<String, double> _maxPassArea = {
    'SMAW': 0.04, // sq in per pass
    'GMAW': 0.05,
    'FCAW': 0.06,
    'SAW': 0.10,
    'GTAW': 0.02,
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final legSize = double.tryParse(_legSizeController.text);

    double totalArea;
    if (_weldType == 'Fillet') {
      if (legSize == null || legSize <= 0) {
        setState(() { _numberOfPasses = null; });
        return;
      }
      totalArea = (legSize * legSize) / 2;
    } else {
      if (thickness == null || thickness <= 0) {
        setState(() { _numberOfPasses = null; });
        return;
      }
      // V-groove approximate area
      final grooveAngle = 60 * (math.pi / 180);
      totalArea = thickness * thickness * math.tan(grooveAngle / 2);
    }

    final maxPassArea = _maxPassArea[_process] ?? 0.04;
    final numberOfPasses = (totalArea / maxPassArea).ceil();

    String sequence;
    String notes;
    if (_weldType == 'Fillet') {
      if (numberOfPasses <= 1) {
        sequence = 'Single pass';
        notes = 'Can complete in one pass';
      } else if (numberOfPasses <= 3) {
        sequence = 'Root + ${numberOfPasses - 1} fill pass(es)';
        notes = 'Standard multi-pass fillet sequence';
      } else {
        sequence = 'Root + ${numberOfPasses - 2} fill + cap';
        notes = 'Heavy fillet - consider stringer beads';
      }
    } else {
      if (numberOfPasses <= 2) {
        sequence = 'Root + hot pass';
        notes = 'Thin groove weld';
      } else if (numberOfPasses <= 5) {
        sequence = 'Root + hot + ${numberOfPasses - 3} fill + cap';
        notes = 'Standard groove weld sequence';
      } else {
        sequence = 'Root + hot + ${numberOfPasses - 3} fill + cap';
        notes = 'Heavy section - control interpass temp';
      }
    }

    setState(() {
      _numberOfPasses = numberOfPasses;
      _areaPerPass = totalArea / numberOfPasses;
      _sequence = sequence;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _legSizeController.clear();
    setState(() { _numberOfPasses = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _legSizeController.dispose();
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
        title: Text('Multi-Pass', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Weld Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            if (_weldType == 'Fillet')
              ZaftoInputField(label: 'Leg Size', unit: 'in', hint: 'Fillet leg size', controller: _legSizeController, onChanged: (_) => _calculate())
            else
              ZaftoInputField(label: 'Thickness', unit: 'in', hint: 'Material thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_numberOfPasses != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Fillet', 'V-Groove'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _weldType == t,
        onSelected: (_) => setState(() { _weldType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['SMAW', 'GMAW', 'FCAW', 'SAW', 'GTAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Passes = Total Area / Pass Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Estimate number of weld passes needed', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Number of Passes', '$_numberOfPasses', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Area per Pass', '${_areaPerPass!.toStringAsFixed(3)} sq in'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sequence:', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_sequence!, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              const SizedBox(height: 8),
              Text(_notes!, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
