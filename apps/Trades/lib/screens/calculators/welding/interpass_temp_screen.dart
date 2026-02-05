import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Interpass Temperature Calculator - Max interpass temp control
class InterpassTempScreen extends ConsumerStatefulWidget {
  const InterpassTempScreen({super.key});
  @override
  ConsumerState<InterpassTempScreen> createState() => _InterpassTempScreenState();
}

class _InterpassTempScreenState extends ConsumerState<InterpassTempScreen> {
  final _preheatController = TextEditingController(text: '200');
  final _carbonController = TextEditingController(text: '0.25');
  String _material = 'Carbon Steel';
  String _service = 'General';

  int? _maxInterpass;
  int? _recommendedInterpass;
  String? _notes;

  void _calculate() {
    final preheat = double.tryParse(_preheatController.text) ?? 200;
    final carbon = double.tryParse(_carbonController.text) ?? 0.25;

    int maxInterpass;
    int recommended;
    String notes;

    if (_material == 'Carbon Steel') {
      // AWS D1.1 typical max is 450-550F for structural
      if (_service == 'General') {
        maxInterpass = 550;
        recommended = 450;
        notes = 'Standard structural - maintain preheat throughout';
      } else if (_service == 'Low Temp') {
        maxInterpass = 400;
        recommended = 350;
        notes = 'Low temperature service requires lower interpass';
      } else {
        maxInterpass = 500;
        recommended = 400;
        notes = 'Impact critical - control grain growth';
      }

      // Adjust for carbon
      if (carbon > 0.30) {
        maxInterpass -= 50;
        recommended -= 50;
        notes = '$notes (reduced for high carbon)';
      }
    } else if (_material == 'Low Alloy') {
      maxInterpass = 500;
      recommended = 400;
      notes = 'Low alloy - strict interpass control required';
    } else if (_material == 'Stainless 300') {
      maxInterpass = 350;
      recommended = 300;
      notes = 'Austenitic SS - avoid sensitization (interpass critical)';
    } else if (_material == 'Stainless 400') {
      maxInterpass = 600;
      recommended = 500;
      notes = 'Martensitic SS - maintain elevated temperature';
    } else {
      maxInterpass = 400;
      recommended = 350;
      notes = 'Duplex SS - balance ferrite/austenite';
    }

    // Never below preheat
    if (recommended < preheat.round()) {
      recommended = preheat.round();
    }

    setState(() {
      _maxInterpass = maxInterpass;
      _recommendedInterpass = recommended;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _preheatController.text = '200';
    _carbonController.text = '0.25';
    setState(() { _maxInterpass = null; });
  }

  @override
  void dispose() {
    _preheatController.dispose();
    _carbonController.dispose();
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
        title: Text('Interpass Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            Text('Service Condition', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildServiceSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Preheat Temp', unit: 'F', hint: 'Minimum preheat', controller: _preheatController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Carbon Content', unit: '%', hint: '0.25 typical', controller: _carbonController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_maxInterpass != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Carbon Steel', 'Low Alloy', 'Stainless 300', 'Stainless 400', 'Duplex'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 11)),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildServiceSelector(ZaftoColors colors) {
    final services = ['General', 'Low Temp', 'Impact Critical'];
    return Wrap(
      spacing: 8,
      children: services.map((s) => ChoiceChip(
        label: Text(s),
        selected: _service == s,
        onSelected: (_) => setState(() { _service = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Maximum Interpass Temperature', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Controls HAZ properties and grain growth', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Max Interpass', '$_maxInterpass\u00B0F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended', '$_recommendedInterpass\u00B0F'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${((_maxInterpass! - 32) * 5 / 9).round()}\u00B0C max'),
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
