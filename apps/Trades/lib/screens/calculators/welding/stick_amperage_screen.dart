import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stick Amperage Calculator - SMAW amperage settings
class StickAmperageScreen extends ConsumerStatefulWidget {
  const StickAmperageScreen({super.key});
  @override
  ConsumerState<StickAmperageScreen> createState() => _StickAmperageScreenState();
}

class _StickAmperageScreenState extends ConsumerState<StickAmperageScreen> {
  final _thicknessController = TextEditingController();
  String _electrodeSize = '1/8';
  String _electrodeType = '6011';
  String _position = 'Flat';

  int? _minAmps;
  int? _maxAmps;
  int? _recommendedAmps;
  String? _notes;

  // Amperage ranges by electrode size (diameter in 32nds x 1 amp rule of thumb)
  static const Map<String, List<int>> _amperageRanges = {
    '3/32': [40, 90],
    '1/8': [75, 130],
    '5/32': [110, 170],
    '3/16': [140, 215],
    '7/32': [170, 250],
    '1/4': [210, 300],
  };

  // Position adjustments
  static const Map<String, double> _positionFactor = {
    'Flat': 1.0,
    'Horizontal': 0.90,
    'Vertical Up': 0.85,
    'Vertical Down': 0.95,
    'Overhead': 0.80,
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    final range = _amperageRanges[_electrodeSize] ?? [75, 130];
    final positionFactor = _positionFactor[_position] ?? 1.0;

    int minAmps = (range[0] * positionFactor).round();
    int maxAmps = (range[1] * positionFactor).round();

    // Calculate recommended based on thickness if provided
    int recommended;
    if (thickness != null && thickness > 0) {
      // Rule of thumb: ~1 amp per 0.001" for the electrode diameter
      final electrodeDecimal = _electrodeSize == '1/8' ? 0.125 :
                               _electrodeSize == '3/32' ? 0.09375 :
                               _electrodeSize == '5/32' ? 0.15625 :
                               _electrodeSize == '3/16' ? 0.1875 :
                               _electrodeSize == '7/32' ? 0.21875 : 0.25;
      recommended = ((electrodeDecimal * 1000) * positionFactor).round();
      recommended = recommended.clamp(minAmps, maxAmps);
    } else {
      recommended = ((minAmps + maxAmps) / 2).round();
    }

    String notes = '';
    if (_electrodeType == '6010' || _electrodeType == '6011') {
      notes = 'Deep penetration, all position, DC+ preferred';
    } else if (_electrodeType == '7018') {
      notes = 'Low hydrogen, smooth arc, DC+ or AC';
    } else if (_electrodeType == '7024') {
      notes = 'High deposition, flat/horizontal only';
    }

    setState(() {
      _minAmps = minAmps;
      _maxAmps = maxAmps;
      _recommendedAmps = recommended;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _minAmps = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('Stick Amperage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Electrode Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            Text('Electrode Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            Text('Position', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildPositionSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Optional', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minAmps != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _amperageRanges.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _electrodeSize == size,
        onSelected: (_) => setState(() { _electrodeSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['6010', '6011', '6013', '7014', '7018', '7024'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) => ChoiceChip(
        label: Text(type),
        selected: _electrodeType == type,
        onSelected: (_) => setState(() { _electrodeType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildPositionSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _positionFactor.keys.map((pos) => ChoiceChip(
        label: Text(pos, style: const TextStyle(fontSize: 11)),
        selected: _position == pos,
        onSelected: (_) => setState(() { _position = pos; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('SMAW Amperage Settings', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Rule of thumb: 1 amp per 0.001" electrode diameter', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended', '$_recommendedAmps A', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Range', '$_minAmps - $_maxAmps A'),
        if (_notes != null && _notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
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
