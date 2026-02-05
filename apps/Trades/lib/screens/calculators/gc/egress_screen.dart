import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Egress Calculator - Emergency egress window requirements
class EgressScreen extends ConsumerStatefulWidget {
  const EgressScreen({super.key});
  @override
  ConsumerState<EgressScreen> createState() => _EgressScreenState();
}

class _EgressScreenState extends ConsumerState<EgressScreen> {
  final _widthController = TextEditingController(text: '32');
  final _heightController = TextEditingController(text: '48');
  final _sillController = TextEditingController(text: '24');

  String? _openingArea;
  bool? _meetsWidth;
  bool? _meetsHeight;
  bool? _meetsSill;
  bool? _meetsArea;
  bool? _passesAll;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _sillController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final sill = double.tryParse(_sillController.text);

    if (width == null || height == null || sill == null) {
      setState(() { _openingArea = null; _meetsWidth = null; _meetsHeight = null; _meetsSill = null; _meetsArea = null; _passesAll = null; });
      return;
    }

    // Calculate clear opening area in square feet
    final openingAreaSqIn = width * height;
    final openingAreaSqFt = openingAreaSqIn / 144;

    // IRC R310.2 requirements
    final meetsWidth = width >= 20;        // 20" min width
    final meetsHeight = height >= 24;       // 24" min height
    final meetsSill = sill <= 44;          // 44" max sill height
    final meetsArea = openingAreaSqFt >= 5.7; // 5.7 sq ft min area

    final passesAll = meetsWidth && meetsHeight && meetsSill && meetsArea;

    setState(() {
      _openingArea = '${openingAreaSqFt.toStringAsFixed(2)} sq ft';
      _meetsWidth = meetsWidth;
      _meetsHeight = meetsHeight;
      _meetsSill = meetsSill;
      _meetsArea = meetsArea;
      _passesAll = passesAll;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '32'; _heightController.text = '48'; _sillController.text = '24'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Egress Window', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Clear Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Clear Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Sill Height from Floor', unit: 'inches', controller: _sillController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_openingArea != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('EGRESS', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  Text(_passesAll! ? 'COMPLIANT' : 'NON-COMPLIANT', style: TextStyle(color: _passesAll! ? colors.accentSuccess : colors.accentError, fontSize: 20, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildCheckRow(colors, 'Clear Opening Area', _openingArea!, '5.7 sq ft min', _meetsArea!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Clear Width', '${_widthController.text}"', '20" min', _meetsWidth!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Clear Height', '${_heightController.text}"', '24" min', _meetsHeight!),
                const SizedBox(height: 8),
                _buildCheckRow(colors, 'Sill Height', '${_sillController.text}"', '44" max', _meetsSill!),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _passesAll! ? colors.accentSuccess.withValues(alpha: 0.1) : colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_passesAll! ? 'Meets IRC R310.2 egress requirements for sleeping rooms.' : 'Does not meet egress requirements. Check failed items above.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRequirementsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCheckRow(ZaftoColors colors, String label, String value, String requirement, bool passes) {
    return Row(children: [
      Icon(passes ? LucideIcons.checkCircle : LucideIcons.xCircle, color: passes ? colors.accentSuccess : colors.accentError, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(width: 8),
      Text('($requirement)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
    ]);
  }

  Widget _buildRequirementsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IRC R310.2 REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Clear Opening Area', '5.7 sq ft min'),
        _buildTableRow(colors, 'Clear Opening Width', '20" minimum'),
        _buildTableRow(colors, 'Clear Opening Height', '24" minimum'),
        _buildTableRow(colors, 'Sill Height', '44" max from floor'),
        _buildTableRow(colors, 'Grade Floor Egress', '5.0 sq ft min'),
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
