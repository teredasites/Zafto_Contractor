import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Offset Calculator - Offset to backspacing conversion
class WheelOffsetScreen extends ConsumerStatefulWidget {
  const WheelOffsetScreen({super.key});
  @override
  ConsumerState<WheelOffsetScreen> createState() => _WheelOffsetScreenState();
}

class _WheelOffsetScreenState extends ConsumerState<WheelOffsetScreen> {
  final _widthController = TextEditingController();
  final _offsetController = TextEditingController();

  double? _backspacing;
  double? _lipToHub;
  String? _offsetType;

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final offset = double.tryParse(_offsetController.text);

    if (width == null || offset == null) {
      setState(() { _backspacing = null; });
      return;
    }

    // Backspacing = (Width / 2) + (Offset / 25.4)
    final halfWidth = width / 2;
    final offsetInches = offset / 25.4;
    final backspace = halfWidth + offsetInches;
    final lip = halfWidth - offsetInches;

    String type;
    if (offset > 0) {
      type = 'Positive offset - wheel sits inward';
    } else if (offset < 0) {
      type = 'Negative offset - wheel pokes outward';
    } else {
      type = 'Zero offset - hub face centered';
    }

    setState(() {
      _backspacing = backspace;
      _lipToHub = lip;
      _offsetType = type;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.clear();
    _offsetController.clear();
    setState(() { _backspacing = null; });
  }

  @override
  void dispose() {
    _widthController.dispose();
    _offsetController.dispose();
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
        title: Text('Wheel Offset', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Wheel Width', unit: 'in', hint: 'e.g. 9.5', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Offset', unit: 'mm', hint: 'Positive or negative', controller: _offsetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_backspacing != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Backspacing = (Width/2) + (Offset/25.4)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Convert between offset (mm) and backspacing (in)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Backspacing', '${_backspacing!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Lip to Hub', '${_lipToHub!.toStringAsFixed(2)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_offsetType!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
