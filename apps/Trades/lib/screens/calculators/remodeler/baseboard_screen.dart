import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Baseboard Calculator - Trim and molding estimation
class BaseboardScreen extends ConsumerStatefulWidget {
  const BaseboardScreen({super.key});
  @override
  ConsumerState<BaseboardScreen> createState() => _BaseboardScreenState();
}

class _BaseboardScreenState extends ConsumerState<BaseboardScreen> {
  final _perimeterController = TextEditingController(text: '120');
  final _doorsController = TextEditingController(text: '5');
  final _openingsController = TextEditingController(text: '2');

  String _profile = 'colonial';

  double? _linearFeet;
  int? _pieces8ft;
  int? _pieces16ft;
  int? _insideCorners;
  int? _outsideCorners;

  @override
  void dispose() { _perimeterController.dispose(); _doorsController.dispose(); _openingsController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final openings = int.tryParse(_openingsController.text) ?? 0;

    // Subtract door openings (avg 3' each) and openings (avg 4' each)
    final deductions = (doors * 3.0) + (openings * 4.0);
    var linearFeet = perimeter - deductions;
    if (linearFeet < 0) linearFeet = 0;

    // Add 10% waste
    final withWaste = linearFeet * 1.10;

    // Pieces needed
    final pieces8ft = (withWaste / 8).ceil();
    final pieces16ft = (withWaste / 16).ceil();

    // Estimate corners (assume 4 inside corners per room avg)
    final insideCorners = 4;
    final outsideCorners = 0;

    setState(() { _linearFeet = linearFeet; _pieces8ft = pieces8ft; _pieces16ft = pieces16ft; _insideCorners = insideCorners; _outsideCorners = outsideCorners; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '120'; _doorsController.text = '5'; _openingsController.text = '2'; setState(() => _profile = 'colonial'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Baseboard', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Openings', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Other Openings', unit: 'qty', controller: _openingsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_linearFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LINEAR FEET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('8\' Pieces (+10%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces8ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('16\' Pieces (+10%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces16ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Inside Corners (est)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_insideCorners', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Use coping or miter for inside corners. 45° miter for outside corners.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildProfileTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['colonial', 'craftsman', 'modern', 'ranch'];
    final labels = {'colonial': 'Colonial', 'craftsman': 'Craftsman', 'modern': 'Modern', 'ranch': 'Ranch'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PROFILE STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _profile == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _profile = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildProfileTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON HEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Budget/modern', '3-4\"'),
        _buildTableRow(colors, 'Standard', '5-6\"'),
        _buildTableRow(colors, 'Traditional', '7-8\"'),
        _buildTableRow(colors, 'Historic/high ceiling', '10-12\"'),
        _buildTableRow(colors, 'Rule of thumb', '1\" per foot ceiling'),
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
