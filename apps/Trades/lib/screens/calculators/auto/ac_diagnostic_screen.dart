import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AC Diagnostic Calculator - Symptom-based troubleshooting
class AcDiagnosticScreen extends ConsumerStatefulWidget {
  const AcDiagnosticScreen({super.key});
  @override
  ConsumerState<AcDiagnosticScreen> createState() => _AcDiagnosticScreenState();
}

class _AcDiagnosticScreenState extends ConsumerState<AcDiagnosticScreen> {
  String _selectedSymptom = 'no_cooling';

  final Map<String, Map<String, String>> _diagnostics = {
    'no_cooling': {
      'title': 'No Cooling At All',
      'causes': '• Compressor not engaging\n• Blown fuse or relay\n• Low refrigerant (pressure switch)\n• Clutch coil failure\n• Control module issue',
      'checks': '• Check fuses and relays\n• Verify compressor clutch engages\n• Check low-side pressure\n• Test clutch coil resistance',
    },
    'weak_cooling': {
      'title': 'Weak Cooling',
      'causes': '• Low refrigerant charge\n• Clogged cabin filter\n• Blend door issue\n• Condenser airflow blocked\n• Expansion valve restriction',
      'checks': '• Check refrigerant charge\n• Inspect cabin air filter\n• Verify condenser is clean\n• Check vent temperature\n• Measure pressures',
    },
    'intermittent': {
      'title': 'Intermittent Cooling',
      'causes': '• Cycling on low charge\n• Pressure switch failure\n• Loose electrical connection\n• Compressor clutch slipping\n• Icing at evaporator',
      'checks': '• Monitor cycling rate\n• Check connections\n• Verify charge level\n• Inspect clutch gap\n• Check evaporator drain',
    },
    'noise': {
      'title': 'AC Makes Noise',
      'causes': '• Compressor bearing failure\n• Loose mounting bracket\n• Belt squeal\n• Liquid refrigerant in compressor\n• Debris in blower',
      'checks': '• Isolate noise location\n• Check belt condition\n• Inspect compressor clutch\n• Verify superheat\n• Check blower motor',
    },
    'smell': {
      'title': 'Bad Smell from Vents',
      'causes': '• Mold in evaporator\n• Clogged drain tube\n• Dirty cabin filter\n• Dead rodent/debris\n• Water intrusion',
      'checks': '• Check evaporator drain\n• Replace cabin filter\n• Inspect for debris\n• Clean evaporator\n• Check door seals',
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
        title: Text('AC Diagnostic', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSymptomSelector(colors),
            const SizedBox(height: 24),
            _buildDiagnosticCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSymptomSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT SYMPTOM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._diagnostics.keys.map((key) => _buildSymptomOption(colors, key, _diagnostics[key]!['title']!)),
      ]),
    );
  }

  Widget _buildSymptomOption(ZaftoColors colors, String key, String title) {
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
          Text(title, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _buildDiagnosticCard(ZaftoColors colors) {
    final diagnostic = _diagnostics[_selectedSymptom]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(diagnostic['title']!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('POSSIBLE CAUSES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(diagnostic['causes']!, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Text('DIAGNOSTIC CHECKS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(diagnostic['checks']!, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
