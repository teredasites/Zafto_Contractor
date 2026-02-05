import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Contact Tip Life Calculator - MIG contact tip replacement
class ContactTipLifeScreen extends ConsumerStatefulWidget {
  const ContactTipLifeScreen({super.key});
  @override
  ConsumerState<ContactTipLifeScreen> createState() => _ContactTipLifeScreenState();
}

class _ContactTipLifeScreenState extends ConsumerState<ContactTipLifeScreen> {
  final _wireSpeedController = TextEditingController(text: '300');
  final _arcTimeController = TextEditingController(text: '30');
  String _tipMaterial = 'Copper';
  String _wireType = 'Solid';

  double? _tipsPerShift;
  double? _wirePerTip;
  double? _hoursPerTip;
  String? _notes;

  // Tip life in lbs of wire (approximate)
  static const Map<String, double> _tipLifeLbs = {
    'Copper': 100,
    'Chrome Zirconium': 200,
    'Heavy Duty': 300,
  };

  void _calculate() {
    final wireSpeed = double.tryParse(_wireSpeedController.text) ?? 300;
    final arcTimePercent = double.tryParse(_arcTimeController.text) ?? 30;

    if (wireSpeed <= 0) {
      setState(() { _tipsPerShift = null; });
      return;
    }

    // Wire consumption: IPM to lbs/hr (using 0.035" wire as reference)
    // 0.035" wire = ~0.00093 lbs/ft
    final feetPerHour = wireSpeed * 60 / 12;
    final lbsPerHour = feetPerHour * 0.00093;

    // Adjust arc time
    final actualLbsPerHour = lbsPerHour * (arcTimePercent / 100);

    // Get tip life based on material
    var tipLifeLbs = _tipLifeLbs[_tipMaterial] ?? 100.0;

    // Flux core is harder on tips
    if (_wireType == 'Flux Core') {
      tipLifeLbs *= 0.7;
    } else if (_wireType == 'Hard Wire') {
      tipLifeLbs *= 0.5;
    }

    final hoursPerTip = tipLifeLbs / actualLbsPerHour;
    final tipsPerShift = 8 / hoursPerTip;
    final wirePerTip = tipLifeLbs;

    String notes;
    if (tipsPerShift > 2) {
      notes = 'High tip consumption - consider upgrading tip material';
    } else if (tipsPerShift > 1) {
      notes = 'Normal consumption - keep spare tips on hand';
    } else {
      notes = 'Good tip life - check for proper tip-to-work distance';
    }

    setState(() {
      _tipsPerShift = tipsPerShift;
      _wirePerTip = wirePerTip;
      _hoursPerTip = hoursPerTip;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wireSpeedController.text = '300';
    _arcTimeController.text = '30';
    setState(() { _tipsPerShift = null; });
  }

  @override
  void dispose() {
    _wireSpeedController.dispose();
    _arcTimeController.dispose();
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
        title: Text('Contact Tip Life', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Tip Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTipSelector(colors),
            const SizedBox(height: 16),
            Text('Wire Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildWireSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Wire Feed Speed', unit: 'IPM', hint: '300 IPM typical', controller: _wireSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Arc-On Time', unit: '%', hint: '30% typical', controller: _arcTimeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tipsPerShift != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTipSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _tipLifeLbs.keys.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 12)),
        selected: _tipMaterial == m,
        onSelected: (_) => setState(() { _tipMaterial = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildWireSelector(ZaftoColors colors) {
    final types = ['Solid', 'Flux Core', 'Hard Wire'];
    return Wrap(
      spacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t),
        selected: _wireType == t,
        onSelected: (_) => setState(() { _wireType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Contact Tip Wear Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Plan tip replacement for production', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Tips per Shift', _tipsPerShift!.toStringAsFixed(1), isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hours per Tip', '${_hoursPerTip!.toStringAsFixed(1)} hrs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Wire per Tip', '${_wirePerTip!.toStringAsFixed(0)} lbs'),
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
