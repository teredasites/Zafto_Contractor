import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cooling Capacity Calculator - System adequacy check
class CoolingCapacityScreen extends ConsumerStatefulWidget {
  const CoolingCapacityScreen({super.key});
  @override
  ConsumerState<CoolingCapacityScreen> createState() => _CoolingCapacityScreenState();
}

class _CoolingCapacityScreenState extends ConsumerState<CoolingCapacityScreen> {
  final _radiatorBtuController = TextEditingController();
  final _engineHpController = TextEditingController();

  double? _requiredBtu;
  double? _surplusDeficit;
  String? _status;

  void _calculate() {
    final radiatorBtu = double.tryParse(_radiatorBtuController.text);
    final engineHp = double.tryParse(_engineHpController.text);

    if (engineHp == null) {
      setState(() { _requiredBtu = null; });
      return;
    }

    // Required cooling: ~840 BTU/min per HP at full load
    // = ~33% of fuel energy at 25% thermal efficiency
    final requiredBtu = engineHp * 840;

    double? surplus;
    String status;

    if (radiatorBtu != null) {
      surplus = radiatorBtu - requiredBtu;
      if (surplus >= requiredBtu * 0.2) {
        status = 'Adequate capacity with margin';
      } else if (surplus >= 0) {
        status = 'Borderline - may overheat in extreme conditions';
      } else {
        status = 'Insufficient - upgrade cooling system';
      }
    } else {
      surplus = null;
      status = 'Enter radiator capacity for comparison';
    }

    setState(() {
      _requiredBtu = requiredBtu;
      _surplusDeficit = surplus;
      _status = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _radiatorBtuController.clear();
    _engineHpController.clear();
    setState(() { _requiredBtu = null; });
  }

  @override
  void dispose() {
    _radiatorBtuController.dispose();
    _engineHpController.dispose();
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
        title: Text('Cooling Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Radiator Capacity', unit: 'BTU/min', hint: 'From manufacturer', controller: _radiatorBtuController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'hp', hint: 'Peak output', controller: _engineHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredBtu != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTroubleshootCard(colors),
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
        Text('~840 BTU/min per HP required', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Verify radiator can handle engine heat load', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_surplusDeficit == null) {
      statusColor = colors.textSecondary;
    } else if (_surplusDeficit! >= _requiredBtu! * 0.2) {
      statusColor = colors.accentSuccess;
    } else if (_surplusDeficit! >= 0) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('COOLING ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Required Capacity', '${(_requiredBtu! / 1000).toStringAsFixed(0)}k BTU/min'),
        if (_surplusDeficit != null) ...[
          const SizedBox(height: 8),
          _buildResultRow(colors, _surplusDeficit! >= 0 ? 'Surplus' : 'Deficit', '${(_surplusDeficit!.abs() / 1000).toStringAsFixed(0)}k BTU/min'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildTroubleshootCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IMPROVING COOLING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Larger/thicker radiator core', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Better radiator material (aluminum)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Higher CFM electric fan(s)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Full shroud for proper airflow', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Water wetter additive', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Lower thermostat (racing only)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Oil cooler (reduces coolant load)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
