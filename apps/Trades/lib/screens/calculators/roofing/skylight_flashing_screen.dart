import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Skylight Flashing Calculator - Calculate skylight flashing materials
class SkylightFlashingScreen extends ConsumerStatefulWidget {
  const SkylightFlashingScreen({super.key});
  @override
  ConsumerState<SkylightFlashingScreen> createState() => _SkylightFlashingScreenState();
}

class _SkylightFlashingScreenState extends ConsumerState<SkylightFlashingScreen> {
  final _widthController = TextEditingController(text: '24');
  final _heightController = TextEditingController(text: '48');
  final _countController = TextEditingController(text: '2');

  String _flashingType = 'Step';

  double? _perimeter;
  int? _stepPieces;
  double? _headFlashing;
  double? _sillFlashing;
  int? _curbKits;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final count = int.tryParse(_countController.text);

    if (width == null || height == null || count == null) {
      setState(() {
        _perimeter = null;
        _stepPieces = null;
        _headFlashing = null;
        _sillFlashing = null;
        _curbKits = null;
      });
      return;
    }

    // Convert to feet
    final widthFt = width / 12;
    final heightFt = height / 12;

    // Perimeter per skylight
    final perimeter = 2 * (widthFt + heightFt);

    // Step flashing: one piece every 5" of side length
    final sidePieces = ((heightFt * 12 / 5) * 2).ceil();
    final stepPieces = sidePieces * count;

    // Head flashing: width + 6" overlap each side
    final headFlashing = (widthFt + 1) * count;

    // Sill/apron flashing: width + 6" overlap each side
    final sillFlashing = (widthFt + 1) * count;

    // Curb kits (if applicable)
    final curbKits = count;

    setState(() {
      _perimeter = perimeter * count;
      _stepPieces = stepPieces;
      _headFlashing = headFlashing;
      _sillFlashing = sillFlashing;
      _curbKits = curbKits;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.text = '24';
    _heightController.text = '48';
    _countController.text = '2';
    setState(() => _flashingType = 'Step');
    _calculate();
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
        title: Text('Skylight Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SKYLIGHT DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'in',
                      hint: 'Rough opening',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Height',
                      unit: 'in',
                      hint: 'Up slope',
                      controller: _heightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Quantity',
                unit: 'skylights',
                hint: 'Total count',
                controller: _countController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FLASHING TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 32),
              if (_perimeter != null) ...[
                _buildSectionHeader(colors, 'FLASHING MATERIALS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.sun, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Skylight Flashing Calculator',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate flashing materials for skylights',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Step', 'Continuous', 'Kit'];
    return Row(
      children: types.map((type) {
        final isSelected = _flashingType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _flashingType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Total Perimeter', '${_perimeter!.toStringAsFixed(1)} lin ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (_flashingType == 'Step') ...[
            _buildResultRow(colors, 'STEP FLASHING', '$_stepPieces pieces', isHighlighted: true),
            const SizedBox(height: 8),
          ],
          _buildResultRow(colors, 'Head Flashing', '${_headFlashing!.toStringAsFixed(1)} lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Sill/Apron Flashing', '${_sillFlashing!.toStringAsFixed(1)} lin ft'),
          if (_flashingType == 'Kit') ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Flashing Kits', '$_curbKits'),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Skylights are high-risk leak areas. Use ice & water shield under all flashing.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
