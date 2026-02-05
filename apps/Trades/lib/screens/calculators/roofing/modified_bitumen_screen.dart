import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Modified Bitumen Calculator - Calculate mod-bit roofing materials
class ModifiedBitumenScreen extends ConsumerStatefulWidget {
  const ModifiedBitumenScreen({super.key});
  @override
  ConsumerState<ModifiedBitumenScreen> createState() => _ModifiedBitumenScreenState();
}

class _ModifiedBitumenScreenState extends ConsumerState<ModifiedBitumenScreen> {
  final _roofAreaController = TextEditingController(text: '2500');
  final _flashingController = TextEditingController(text: '150');

  String _modType = 'SBS';
  String _application = 'Torch';

  double? _squares;
  int? _baseSheetRolls;
  int? _capSheetRolls;
  double? _primerGallons;
  int? _propaneTanks;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _flashingController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final flashing = double.tryParse(_flashingController.text);

    if (roofArea == null || flashing == null) {
      setState(() {
        _squares = null;
        _baseSheetRolls = null;
        _capSheetRolls = null;
        _primerGallons = null;
        _propaneTanks = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Roll coverage: 1 square per roll (33.3' × 3' = 100 sq ft)
    // With 3" side lap and 6" end lap
    final effectiveCoverage = 90.0; // sq ft per roll after overlaps

    // Base sheet rolls
    final baseSheetRolls = (roofArea * 1.1 / effectiveCoverage).ceil();

    // Cap sheet rolls (same coverage)
    final capSheetRolls = (roofArea * 1.1 / effectiveCoverage).ceil();

    // Flashing material (additional)
    final flashingRolls = (flashing * 1.5 / effectiveCoverage).ceil();

    // Primer (for cold-applied or adhesive)
    double primerGallons = 0;
    if (_application == 'Cold Applied' || _application == 'Self-Adhered') {
      primerGallons = roofArea / 200; // 200 sq ft/gal
    }

    // Propane for torch application
    int propaneTanks = 0;
    if (_application == 'Torch') {
      // ~1 tank per 10 squares
      propaneTanks = (squares / 10).ceil();
    }

    setState(() {
      _squares = squares;
      _baseSheetRolls = baseSheetRolls + flashingRolls;
      _capSheetRolls = capSheetRolls + flashingRolls;
      _primerGallons = primerGallons;
      _propaneTanks = propaneTanks;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2500';
    _flashingController.text = '150';
    setState(() {
      _modType = 'SBS';
      _application = 'Torch';
    });
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
        title: Text('Modified Bitumen', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MEMBRANE TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildApplicationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Total field',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Flashing',
                      unit: 'lin ft',
                      hint: 'Perimeter',
                      controller: _flashingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_baseSheetRolls != null) ...[
                _buildSectionHeader(colors, 'MATERIALS NEEDED'),
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Modified Bitumen Calculator',
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
            'Calculate mod-bit roofing materials',
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
    final types = ['SBS', 'APP'];
    return Row(
      children: types.map((type) {
        final isSelected = _modType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _modType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'SBS' ? 'Rubber-like' : 'Plastic-like',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    final apps = ['Torch', 'Cold Applied', 'Self-Adhered'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: apps.map((app) {
        final isSelected = _application == app;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _application = app);
            _calculate();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              app,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'BASE SHEET ROLLS', '$_baseSheetRolls', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'CAP SHEET ROLLS', '$_capSheetRolls', isHighlighted: true),
          if (_primerGallons! > 0) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, 'Primer', '${_primerGallons!.toStringAsFixed(0)} gal'),
          ],
          if (_propaneTanks! > 0) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, 'Propane Tanks', '$_propaneTanks'),
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
                Icon(LucideIcons.flame, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _application == 'Torch'
                        ? 'Torch applied: Fire watch required. Hot work permit needed.'
                        : 'Cold applied is safer but requires proper ventilation.',
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
