import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Blend Door Calculator - HVAC actuator diagnostics
class BlendDoorScreen extends ConsumerStatefulWidget {
  const BlendDoorScreen({super.key});
  @override
  ConsumerState<BlendDoorScreen> createState() => _BlendDoorScreenState();
}

class _BlendDoorScreenState extends ConsumerState<BlendDoorScreen> {
  String _selectedSymptom = 'stuck_hot';

  final Map<String, Map<String, String>> _symptoms = {
    'stuck_hot': {
      'title': 'Stuck on Heat',
      'cause': 'Blend door stuck in full heat position or actuator failed',
      'tests': '• Listen for actuator clicking\n• Check actuator power/ground\n• Perform actuator calibration\n• Manually test door movement',
      'fix': 'Replace blend door actuator or repair broken door/linkage',
    },
    'stuck_cold': {
      'title': 'Stuck on Cold',
      'cause': 'Blend door stuck in full AC position, low coolant, or heater core issue',
      'tests': '• Check coolant level\n• Feel heater hoses (both hot?)\n• Listen for actuator\n• Check for airlocked heater core',
      'fix': 'Bleed cooling system, replace actuator, or flush heater core',
    },
    'clicking': {
      'title': 'Clicking Noise',
      'cause': 'Actuator motor stripping gears or door binding',
      'tests': '• Locate clicking actuator\n• Check door movement manually\n• Verify no debris blocking door\n• Check for broken tabs',
      'fix': 'Replace actuator, repair door pivot points, clear debris',
    },
    'no_defrost': {
      'title': 'Defrost Not Working',
      'cause': 'Mode door actuator failure or vacuum leak (older vehicles)',
      'tests': '• Check mode door actuator\n• Test vacuum lines (if equipped)\n• Verify control head output\n• Check for broken door',
      'fix': 'Replace mode door actuator, repair vacuum lines',
    },
    'wrong_side': {
      'title': 'One Side Different Temp',
      'cause': 'Dual-zone blend door or actuator issue',
      'tests': '• Identify which side is affected\n• Test both blend actuators\n• Check temperature sensors\n• Verify control module',
      'fix': 'Replace affected actuator, calibrate system',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Blend Door', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            _buildSymptomSelector(colors),
            const SizedBox(height: 24),
            _buildDiagnosticCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('HVAC Blend Door Diagnostics', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Blend doors control hot/cold air mix, mode selection, and recirculation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSymptomSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT SYMPTOM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._symptoms.keys.map((key) => _buildSymptomOption(colors, key)),
      ]),
    );
  }

  Widget _buildSymptomOption(ZaftoColors colors, String key) {
    final isSelected = _selectedSymptom == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedSymptom = key; });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.accentPrimary : Colors.transparent,
              border: Border.all(color: isSelected ? colors.accentPrimary : colors.textTertiary, width: 2),
            ),
            child: isSelected ? Icon(LucideIcons.check, size: 12, color: colors.bgBase) : null,
          ),
          const SizedBox(width: 12),
          Text(_symptoms[key]!['title']!, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildDiagnosticCard(ZaftoColors colors) {
    final symptom = _symptoms[_selectedSymptom]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(symptom['title']!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('LIKELY CAUSE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(symptom['cause']!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        const SizedBox(height: 16),
        Text('DIAGNOSTIC TESTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(symptom['tests']!, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('TYPICAL FIX', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(symptom['fix']!, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
