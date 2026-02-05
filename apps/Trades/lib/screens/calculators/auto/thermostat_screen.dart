import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Thermostat Calculator - Operating temperature selection
class ThermostatScreen extends ConsumerStatefulWidget {
  const ThermostatScreen({super.key});
  @override
  ConsumerState<ThermostatScreen> createState() => _ThermostatScreenState();
}

class _ThermostatScreenState extends ConsumerState<ThermostatScreen> {
  final _currentTempController = TextEditingController();
  String _selectedRating = '195';

  final Map<String, Map<String, String>> _thermostatInfo = {
    '160': {
      'openTemp': '160°F',
      'fullOpen': '180°F',
      'use': 'Racing - no emissions controls needed',
      'note': 'May trigger check engine light on street vehicles',
    },
    '180': {
      'openTemp': '180°F',
      'fullOpen': '200°F',
      'use': 'Performance street - older vehicles',
      'note': 'Reduced emissions efficiency, may affect fuel economy',
    },
    '195': {
      'openTemp': '195°F',
      'fullOpen': '215°F',
      'use': 'Most modern vehicles - OEM standard',
      'note': 'Optimal for emissions and engine efficiency',
    },
    '203': {
      'openTemp': '203°F',
      'fullOpen': '223°F',
      'use': 'Some European vehicles, diesels',
      'note': 'Higher efficiency, reduced wear',
    },
  };

  void _calculate() {
    setState(() {});
  }

  @override
  void dispose() {
    _currentTempController.dispose();
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
        title: Text('Thermostat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildRatingSelector(colors),
            const SizedBox(height: 24),
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            _buildDiagnosticCard(colors),
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
        Text('Thermostat Selection Guide', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Rating = temperature at which thermostat begins to open', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRatingSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT RATING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: _thermostatInfo.keys.map((rating) => Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() { _selectedRating = rating; });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedRating == rating ? colors.accentPrimary : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _selectedRating == rating ? colors.accentPrimary : colors.borderSubtle),
                ),
                child: Text('$rating°F', style: TextStyle(
                  color: _selectedRating == rating ? colors.bgBase : colors.textPrimary,
                  fontSize: 14,
                  fontWeight: _selectedRating == rating ? FontWeight.w600 : FontWeight.normal,
                ), textAlign: TextAlign.center),
              ),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    final info = _thermostatInfo[_selectedRating]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('$_selectedRating°F THERMOSTAT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildInfoRow(colors, 'Opens At', info['openTemp']!),
        const SizedBox(height: 8),
        _buildInfoRow(colors, 'Fully Open', info['fullOpen']!),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BEST FOR:', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(info['use']!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            const SizedBox(height: 8),
            Text(info['note']!, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDiagnosticCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THERMOSTAT SYMPTOMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSymptomRow(colors, 'Stuck open', 'Slow warmup, low temps, poor heat'),
        _buildSymptomRow(colors, 'Stuck closed', 'Overheating, no coolant flow'),
        _buildSymptomRow(colors, 'Partially stuck', 'Erratic temps, intermittent overheating'),
        const SizedBox(height: 12),
        Text('Test: Thermostat should open when submerged in heated water at rated temp.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildSymptomRow(ZaftoColors colors, String symptom, String effect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(symptom, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(child: Text(effect, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
