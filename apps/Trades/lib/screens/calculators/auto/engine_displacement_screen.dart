import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Engine Displacement Calculator - Bore x Stroke to CI/CC
class EngineDisplacementScreen extends ConsumerStatefulWidget {
  const EngineDisplacementScreen({super.key});
  @override
  ConsumerState<EngineDisplacementScreen> createState() => _EngineDisplacementScreenState();
}

class _EngineDisplacementScreenState extends ConsumerState<EngineDisplacementScreen> {
  final _boreController = TextEditingController();
  final _strokeController = TextEditingController();
  final _cylindersController = TextEditingController(text: '8');
  bool _isMetric = false;

  double? _displacementCi;
  double? _displacementCc;
  double? _displacementLiters;

  @override
  void dispose() {
    _boreController.dispose();
    _strokeController.dispose();
    _cylindersController.dispose();
    super.dispose();
  }

  void _calculate() {
    final bore = double.tryParse(_boreController.text);
    final stroke = double.tryParse(_strokeController.text);
    final cylinders = int.tryParse(_cylindersController.text);

    if (bore == null || stroke == null || cylinders == null || bore <= 0 || stroke <= 0) {
      setState(() {
        _displacementCi = null;
        _displacementCc = null;
        _displacementLiters = null;
      });
      return;
    }

    double boreInches = _isMetric ? bore / 25.4 : bore;
    double strokeInches = _isMetric ? stroke / 25.4 : stroke;

    // Displacement = (π/4) × Bore² × Stroke × Cylinders
    final ci = (3.14159 / 4) * (boreInches * boreInches) * strokeInches * cylinders;
    final cc = ci * 16.387;
    final liters = cc / 1000;

    setState(() {
      _displacementCi = ci;
      _displacementCc = cc;
      _displacementLiters = liters;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boreController.clear();
    _strokeController.clear();
    _cylindersController.text = '8';
    setState(() {
      _displacementCi = null;
      _displacementCc = null;
      _displacementLiters = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Engine Displacement', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildUnitToggle(colors),
              const SizedBox(height: 16),
              ZaftoInputField(
                label: 'Bore',
                unit: _isMetric ? 'mm' : 'in',
                hint: 'Cylinder bore diameter',
                controller: _boreController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Stroke',
                unit: _isMetric ? 'mm' : 'in',
                hint: 'Piston travel distance',
                controller: _strokeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Cylinders',
                unit: 'qty',
                hint: '4, 6, 8, etc.',
                controller: _cylindersController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_displacementCi != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Text('CI = (π/4) × Bore² × Stroke × Cylinders',
            style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Calculate total engine displacement from bore and stroke',
            style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(ZaftoColors colors) {
    return Row(
      children: [
        Text('Units:', style: TextStyle(color: colors.textSecondary)),
        const SizedBox(width: 12),
        ChoiceChip(
          label: Text('Inches'),
          selected: !_isMetric,
          onSelected: (_) => setState(() { _isMetric = false; _calculate(); }),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text('Metric'),
          selected: _isMetric,
          onSelected: (_) => setState(() { _isMetric = true; _calculate(); }),
        ),
      ],
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Cubic Inches', '${_displacementCi!.toStringAsFixed(1)} CI', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Cubic Centimeters', '${_displacementCc!.toStringAsFixed(0)} CC'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Liters', '${_displacementLiters!.toStringAsFixed(2)} L'),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(
          color: isPrimary ? colors.accentPrimary : colors.textPrimary,
          fontSize: isPrimary ? 20 : 16,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
        )),
      ],
    );
  }
}
