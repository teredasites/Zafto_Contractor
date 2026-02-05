import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Standing Seam Calculator - Calculate standing seam metal roofing
class StandingSeamScreen extends ConsumerStatefulWidget {
  const StandingSeamScreen({super.key});
  @override
  ConsumerState<StandingSeamScreen> createState() => _StandingSeamScreenState();
}

class _StandingSeamScreenState extends ConsumerState<StandingSeamScreen> {
  final _roofLengthController = TextEditingController(text: '40');
  final _roofWidthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '4');

  String _panelWidth = '16"';
  String _seamType = 'Snap-Lock';

  double? _roofArea;
  double? _squares;
  int? _panelsNeeded;
  double? _panelLength;
  int? _clips;
  double? _ridgeCap;

  @override
  void dispose() {
    _roofLengthController.dispose();
    _roofWidthController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofLength = double.tryParse(_roofLengthController.text);
    final roofWidth = double.tryParse(_roofWidthController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (roofLength == null || roofWidth == null || pitch == null) {
      setState(() {
        _roofArea = null;
        _squares = null;
        _panelsNeeded = null;
        _panelLength = null;
        _clips = null;
        _ridgeCap = null;
      });
      return;
    }

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Panel length (eave to ridge on one side)
    final run = roofWidth / 2;
    final panelLength = run * pitchFactor;

    // Roof area (both sides)
    final roofArea = roofLength * panelLength * 2;
    final squares = roofArea / 100;

    // Panel width in feet
    double panelWidthFt;
    switch (_panelWidth) {
      case '12"':
        panelWidthFt = 1.0;
        break;
      case '16"':
        panelWidthFt = 16 / 12;
        break;
      case '18"':
        panelWidthFt = 1.5;
        break;
      default:
        panelWidthFt = 16 / 12;
    }

    // Panels per side
    final panelsPerSide = (roofLength / panelWidthFt).ceil();
    final panelsNeeded = panelsPerSide * 2; // Both sides

    // Clips: 2 per panel foot of length
    final clipsPerPanel = (panelLength * 2).ceil();
    final clips = panelsNeeded * clipsPerPanel;

    // Ridge cap
    final ridgeCap = roofLength * 1.1;

    setState(() {
      _roofArea = roofArea;
      _squares = squares;
      _panelsNeeded = panelsNeeded;
      _panelLength = panelLength;
      _clips = clips;
      _ridgeCap = ridgeCap;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofLengthController.text = '40';
    _roofWidthController.text = '30';
    _pitchController.text = '4';
    setState(() {
      _panelWidth = '16"';
      _seamType = 'Snap-Lock';
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
        title: Text('Standing Seam', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL SPECS'),
              const SizedBox(height: 12),
              _buildWidthSelector(colors),
              const SizedBox(height: 12),
              _buildSeamSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Ridge line',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Eave to eave',
                      controller: _roofWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Pitch',
                unit: '/12',
                hint: 'Roof slope',
                controller: _pitchController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_panelsNeeded != null) ...[
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
              Icon(LucideIcons.alignJustify, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Standing Seam Calculator',
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
            'Calculate standing seam metal roofing',
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

  Widget _buildWidthSelector(ZaftoColors colors) {
    final widths = ['12"', '16"', '18"'];
    return Row(
      children: widths.map((width) {
        final isSelected = _panelWidth == width;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _panelWidth = width);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: width != widths.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                width,
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

  Widget _buildSeamSelector(ZaftoColors colors) {
    final seams = ['Snap-Lock', 'Mechanical'];
    return Row(
      children: seams.map((seam) {
        final isSelected = _seamType == seam;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _seamType = seam);
            },
            child: Container(
              margin: EdgeInsets.only(right: seam != seams.last ? 8 : 0),
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
                    seam,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    seam == 'Snap-Lock' ? 'Min 3:12' : 'Low slope OK',
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
          _buildResultRow(colors, 'Roof Area', '${_roofArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'PANELS NEEDED', '$_panelsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Panel Length', '${_panelLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Clips', '$_clips'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Cap', '${_ridgeCap!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Standing seam panels run eave to ridge. Order field-measured lengths.',
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
