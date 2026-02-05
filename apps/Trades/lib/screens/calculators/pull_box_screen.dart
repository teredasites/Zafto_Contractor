import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Pull Box / Junction Box Sizing Calculator - Design System v2.6
enum PullType { straight, angle }

class PullBoxScreen extends ConsumerStatefulWidget {
  const PullBoxScreen({super.key});
  @override
  ConsumerState<PullBoxScreen> createState() => _PullBoxScreenState();
}

class _PullBoxScreenState extends ConsumerState<PullBoxScreen> {
  PullType _pullType = PullType.straight;
  final _largestController = TextEditingController();
  final _sumOthersController = TextEditingController();
  int _raceways = 1;
  Map<String, double>? _results;

  @override
  void dispose() { _largestController.dispose(); _sumOthersController.dispose(); super.dispose(); }

  void _calculate() {
    final largest = double.tryParse(_largestController.text);
    if (largest == null || largest <= 0) { _showError('Enter largest raceway size'); return; }
    if (_pullType == PullType.straight) {
      setState(() => _results = {'length': largest * 8});
    } else {
      final sumOthers = double.tryParse(_sumOthersController.text) ?? 0;
      setState(() => _results = {'distance': (largest * 6) + sumOthers, 'spacing': largest * 6});
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ref.read(zaftoColorsProvider).accentError));
  void _reset() { _largestController.clear(); _sumOthersController.clear(); setState(() { _pullType = PullType.straight; _raceways = 1; _results = null; }); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pull Box Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildNecCard(colors),
        const SizedBox(height: 24),
        _buildPullTypeSelector(colors),
        const SizedBox(height: 24),
        Text('RACEWAY DIMENSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ZaftoInputField(label: 'Largest Trade Size', unit: 'in', hint: 'Largest raceway', controller: _largestController),
        if (_pullType == PullType.angle) ...[
          const SizedBox(height: 12),
          ZaftoInputField(label: 'Sum of Others', unit: 'in', hint: 'Same wall', controller: _sumOthersController),
          const SizedBox(height: 12),
          _buildStepperRow(colors),
        ],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
        const SizedBox(height: 24),
        if (_results != null) _buildResults(colors),
        const SizedBox(height: 24),
        _buildRulesCard(colors),
      ]))),
    );
  }

  Widget _buildNecCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NEC 314.28', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          Text('Pull and junction boxes for #4 AWG and larger', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildPullTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _buildTypeButton(colors, 'STRAIGHT PULL', '314.28(A)(1)', _pullType == PullType.straight, () => setState(() { _pullType = PullType.straight; _results = null; })),
        _buildTypeButton(colors, 'ANGLE PULL', '314.28(A)(2)', _pullType == PullType.angle, () => setState(() { _pullType = PullType.angle; _results = null; })),
      ]),
    );
  }

  Widget _buildTypeButton(ZaftoColors colors, String label, String sublabel, bool isSelected, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Column(children: [
        Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
        Text(sublabel, style: TextStyle(color: isSelected ? Colors.white70 : colors.textTertiary, fontSize: 10)),
      ])),
    ));
  }

  Widget _buildStepperRow(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text('Rows of Raceways', style: TextStyle(color: colors.textSecondary))),
        IconButton(icon: Icon(LucideIcons.minusCircle, color: _raceways > 1 ? colors.accentPrimary : colors.textTertiary), onPressed: _raceways > 1 ? () => setState(() => _raceways--) : null),
        Text('$_raceways', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
        IconButton(icon: Icon(LucideIcons.plusCircle, color: _raceways < 6 ? colors.accentPrimary : colors.textTertiary), onPressed: _raceways < 6 ? () => setState(() => _raceways++) : null),
      ]),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(children: [Icon(LucideIcons.square, color: colors.accentSuccess, size: 24), const SizedBox(width: 8), Text('MINIMUM BOX DIMENSIONS', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1))]),
        const SizedBox(height: 20),
        if (_pullType == PullType.straight) _buildDimensionResult(colors, 'Length (pull direction)', _results!['length']!)
        else ...[
          _buildDimensionResult(colors, 'Distance to opposite wall', _results!['distance']!),
          const SizedBox(height: 12),
          _buildDimensionResult(colors, 'Conductor spacing', _results!['spacing']!, subtitle: 'Between raceway entries'),
        ],
      ]),
    );
  }

  Widget _buildDimensionResult(ZaftoColors colors, String label, double value, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          if (subtitle != null) Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ])),
        Text('${value.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentSuccess, fontSize: 28, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildRulesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_pullType == PullType.straight ? 'STRAIGHT PULL RULE' : 'ANGLE PULL RULES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (_pullType == PullType.straight) ...[
          Text('Length = 8 × largest raceway trade size', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Example: 2" conduit → 8 × 2 = 16" minimum', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ] else ...[
          Text('Distance = 6 × largest + sum of others (same wall)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text('Spacing = 6 × raceway trade size (between entries)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ]),
    );
  }
}
