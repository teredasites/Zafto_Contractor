import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Horsepower Calculator - HP from Torque x RPM
class HorsepowerScreen extends ConsumerStatefulWidget {
  const HorsepowerScreen({super.key});
  @override
  ConsumerState<HorsepowerScreen> createState() => _HorsepowerScreenState();
}

class _HorsepowerScreenState extends ConsumerState<HorsepowerScreen> {
  final _torqueController = TextEditingController();
  final _rpmController = TextEditingController();

  double? _horsepower;
  double? _kilowatts;

  @override
  void dispose() {
    _torqueController.dispose();
    _rpmController.dispose();
    super.dispose();
  }

  void _calculate() {
    final torque = double.tryParse(_torqueController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (torque == null || rpm == null || rpm <= 0) {
      setState(() { _horsepower = null; _kilowatts = null; });
      return;
    }

    // HP = Torque × RPM / 5252
    final hp = (torque * rpm) / 5252;
    final kw = hp * 0.7457;

    setState(() {
      _horsepower = hp;
      _kilowatts = kw;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _torqueController.clear();
    _rpmController.clear();
    setState(() { _horsepower = null; _kilowatts = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Horsepower', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              ZaftoInputField(label: 'Torque', unit: 'lb-ft', hint: 'Engine torque output', controller: _torqueController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Engine Speed', unit: 'RPM', hint: 'Revolutions per minute', controller: _rpmController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_horsepower != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('HP = Torque × RPM / 5252', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
          const SizedBox(height: 8),
          Text('The constant 5252 is where HP and torque curves cross', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          _buildResultRow(colors, 'Horsepower', '${_horsepower!.toStringAsFixed(1)} HP', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Kilowatts', '${_kilowatts!.toStringAsFixed(1)} kW'),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
