import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Headlight Aim Calculator
class HeadlightAimScreen extends ConsumerStatefulWidget {
  const HeadlightAimScreen({super.key});
  @override
  ConsumerState<HeadlightAimScreen> createState() => _HeadlightAimScreenState();
}

class _HeadlightAimScreenState extends ConsumerState<HeadlightAimScreen> {
  final _distanceController = TextEditingController(text: '25');
  final _heightController = TextEditingController();
  String _headlightType = 'Halogen';

  double? _dropInches;
  String? _recommendation;

  void _calculate() {
    final distance = double.tryParse(_distanceController.text);
    final height = double.tryParse(_heightController.text);

    if (distance == null || height == null || distance <= 0 || height <= 0) {
      setState(() { _dropInches = null; });
      return;
    }

    // Standard: 2" drop at 25 feet (most states)
    // HID/LED: Often require 2-4" drop due to intensity
    double dropPerFoot;
    if (_headlightType == 'Halogen') {
      dropPerFoot = 2.0 / 25.0;
    } else if (_headlightType == 'HID/Xenon') {
      dropPerFoot = 3.0 / 25.0;
    } else {
      dropPerFoot = 2.5 / 25.0; // LED
    }

    final totalDrop = distance * dropPerFoot;
    final targetHeight = height - totalDrop;

    String recommendation;
    if (_headlightType == 'HID/Xenon') {
      recommendation = 'HID: Auto-leveling required by law in many states';
    } else if (_headlightType == 'LED') {
      recommendation = 'LED: Ensure proper housing for pattern control';
    } else {
      recommendation = 'Aim hotspot at target height on wall';
    }

    setState(() {
      _dropInches = totalDrop;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _distanceController.text = '25';
    _heightController.clear();
    setState(() { _dropInches = null; });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _heightController.dispose();
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
        title: Text('Headlight Aim', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('HEADLIGHT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Distance to Wall', unit: 'ft', hint: 'Standard: 25ft', controller: _distanceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Headlight Height', unit: 'in', hint: 'From ground', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_dropInches != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Halogen', 'HID/Xenon', 'LED'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _headlightType == type,
        onSelected: (_) => setState(() { _headlightType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Drop = ~2" at 25 ft (standard)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Hotspot should be below headlight center', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Target Drop', '${_dropInches!.toStringAsFixed(1)}"', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
