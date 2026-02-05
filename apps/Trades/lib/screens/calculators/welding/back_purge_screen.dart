import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Back Purge Calculator - Inert gas purge for pipe welding
class BackPurgeScreen extends ConsumerStatefulWidget {
  const BackPurgeScreen({super.key});
  @override
  ConsumerState<BackPurgeScreen> createState() => _BackPurgeScreenState();
}

class _BackPurgeScreenState extends ConsumerState<BackPurgeScreen> {
  final _pipeDiameterController = TextEditingController();
  final _pipeLengthController = TextEditingController(text: '24');
  final _flowRateController = TextEditingController(text: '20');
  String _material = 'Stainless';

  double? _purgeVolume;
  double? _purgeTime;
  double? _gasNeeded;
  String? _notes;

  void _calculate() {
    final diameter = double.tryParse(_pipeDiameterController.text);
    final length = double.tryParse(_pipeLengthController.text) ?? 24;
    final flowRate = double.tryParse(_flowRateController.text) ?? 20;

    if (diameter == null || diameter <= 0 || flowRate <= 0) {
      setState(() { _purgeVolume = null; });
      return;
    }

    // Calculate pipe volume in cubic feet
    final radius = diameter / 2 / 12; // Convert to feet
    final lengthFt = length / 12;
    final volume = math.pi * radius * radius * lengthFt;

    // Need to exchange volume 5-7 times for proper purge
    final exchangeMultiplier = _material == 'Titanium' ? 7.0 : 5.0;
    final totalVolume = volume * exchangeMultiplier;

    // Time in minutes at given flow rate (CFH to CFM)
    final cfm = flowRate / 60;
    final purgeTime = totalVolume / cfm;

    // Total gas in cubic feet
    final gasNeeded = totalVolume * 1.2; // 20% safety factor

    String notes;
    if (_material == 'Stainless') {
      notes = 'Target <0.5% O2 before welding. Use oxygen analyzer';
    } else if (_material == 'Titanium') {
      notes = 'Target <50 ppm O2. Critical - use high purity argon';
    } else {
      notes = 'Maintain purge until root pass cools below oxidation temp';
    }

    setState(() {
      _purgeVolume = totalVolume;
      _purgeTime = purgeTime;
      _gasNeeded = gasNeeded;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeDiameterController.clear();
    _pipeLengthController.text = '24';
    _flowRateController.text = '20';
    setState(() { _purgeVolume = null; });
  }

  @override
  void dispose() {
    _pipeDiameterController.dispose();
    _pipeLengthController.dispose();
    _flowRateController.dispose();
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
        title: Text('Back Purge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pipe Diameter', unit: 'in', hint: 'ID or nominal', controller: _pipeDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Purge Length', unit: 'in', hint: 'Dam to dam', controller: _pipeLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Flow Rate', unit: 'CFH', hint: '20 CFH typical', controller: _flowRateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_purgeVolume != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Stainless', 'Titanium', 'Chrome-Moly', 'Nickel Alloy'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Purge = Volume x 5-7 exchanges', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Inert gas purge for root protection', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Purge Time', '${_purgeTime!.toStringAsFixed(1)} min', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gas Volume', '${_purgeVolume!.toStringAsFixed(2)} cf'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gas Needed', '${_gasNeeded!.toStringAsFixed(1)} cf'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
