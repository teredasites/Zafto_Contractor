import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Purlin Spacing Calculator - Calculate purlin requirements for metal roofing
class PurlinSpacingScreen extends ConsumerStatefulWidget {
  const PurlinSpacingScreen({super.key});
  @override
  ConsumerState<PurlinSpacingScreen> createState() => _PurlinSpacingScreenState();
}

class _PurlinSpacingScreenState extends ConsumerState<PurlinSpacingScreen> {
  final _rafterLengthController = TextEditingController(text: '16');
  final _roofLengthController = TextEditingController(text: '40');
  final _spacingController = TextEditingController(text: '24');

  String _purlinSize = '2×4';
  String _panelType = '26 Gauge';

  int? _purlinsPerRafter;
  int? _totalPurlins;
  int? _boardFeet;
  double? _totalLinearFeet;

  @override
  void dispose() {
    _rafterLengthController.dispose();
    _roofLengthController.dispose();
    _spacingController.dispose();
    super.dispose();
  }

  void _calculate() {
    final rafterLength = double.tryParse(_rafterLengthController.text);
    final roofLength = double.tryParse(_roofLengthController.text);
    final spacing = double.tryParse(_spacingController.text);

    if (rafterLength == null || roofLength == null || spacing == null) {
      setState(() {
        _purlinsPerRafter = null;
        _totalPurlins = null;
        _boardFeet = null;
        _totalLinearFeet = null;
      });
      return;
    }

    // Purlins per rafter run
    final rafterInches = rafterLength * 12;
    final purlinsPerRafter = (rafterInches / spacing).ceil() + 1; // +1 for eave

    // Number of rafter bays (for gable roof, both sides)
    // Assume purlins run perpendicular to rafters
    final totalPurlins = purlinsPerRafter * 2; // Both roof planes

    // Total linear feet
    final totalLinearFeet = totalPurlins * roofLength;

    // Board feet calculation
    double thickness;
    double width;
    switch (_purlinSize) {
      case '2×4':
        thickness = 1.5;
        width = 3.5;
        break;
      case '2×6':
        thickness = 1.5;
        width = 5.5;
        break;
      case '2×8':
        thickness = 1.5;
        width = 7.25;
        break;
      default:
        thickness = 1.5;
        width = 3.5;
    }

    final boardFeet = (totalLinearFeet * thickness * width / 144).ceil();

    setState(() {
      _purlinsPerRafter = purlinsPerRafter;
      _totalPurlins = totalPurlins;
      _boardFeet = boardFeet;
      _totalLinearFeet = totalLinearFeet;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _rafterLengthController.text = '16';
    _roofLengthController.text = '40';
    _spacingController.text = '24';
    setState(() {
      _purlinSize = '2×4';
      _panelType = '26 Gauge';
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
        title: Text('Purlin Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PURLIN & PANEL'),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
              const SizedBox(height: 12),
              _buildPanelSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rafter Length',
                      unit: 'ft',
                      hint: 'Eave to ridge',
                      controller: _rafterLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Length',
                      unit: 'ft',
                      hint: 'Ridge length',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Purlin Spacing',
                unit: 'in',
                hint: '24" typical',
                controller: _spacingController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalPurlins != null) ...[
                _buildSectionHeader(colors, 'PURLIN REQUIREMENTS'),
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
              Icon(LucideIcons.alignJustify, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Purlin Spacing Calculator',
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
            'Calculate purlins for metal panel roofing',
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

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['2×4', '2×6', '2×8'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _purlinSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _purlinSize = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPanelSelector(ZaftoColors colors) {
    final panels = ['29 Gauge', '26 Gauge', '24 Gauge'];
    return Row(
      children: panels.map((panel) {
        final isSelected = _panelType == panel;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _panelType = panel);
            },
            child: Container(
              margin: EdgeInsets.only(right: panel != panels.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    panel,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    panel == '29 Gauge' ? 'Light' : (panel == '26 Gauge' ? 'Standard' : 'Heavy'),
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
          _buildResultRow(colors, 'Purlins Per Side', '$_purlinsPerRafter'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'TOTAL PURLINS', '$_totalPurlins rows', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'LINEAR FEET', '${_totalLinearFeet!.toStringAsFixed(0)} ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Board Feet', '$_boardFeet BF'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('Purlin Spacing Guide', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('29 ga: Max 24" o.c.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('26 ga: Max 36" o.c.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('24 ga: Max 48" o.c.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
