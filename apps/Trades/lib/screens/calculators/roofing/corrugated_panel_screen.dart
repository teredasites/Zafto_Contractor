import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Corrugated Panel Calculator - Calculate corrugated metal roofing
class CorrugatedPanelScreen extends ConsumerStatefulWidget {
  const CorrugatedPanelScreen({super.key});
  @override
  ConsumerState<CorrugatedPanelScreen> createState() => _CorrugatedPanelScreenState();
}

class _CorrugatedPanelScreenState extends ConsumerState<CorrugatedPanelScreen> {
  final _roofLengthController = TextEditingController(text: '24');
  final _roofWidthController = TextEditingController(text: '20');
  final _pitchController = TextEditingController(text: '3');

  String _panelLength = '10 ft';
  String _overlap = '1 Rib';

  double? _roofArea;
  int? _panelsNeeded;
  int? _screwsNeeded;
  double? _closureFeet;
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
        _panelsNeeded = null;
        _screwsNeeded = null;
        _closureFeet = null;
        _ridgeCap = null;
      });
      return;
    }

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Rafter length (eave to ridge)
    final run = roofWidth / 2;
    final rafterLength = run * pitchFactor;

    // Roof area (both sides)
    final roofArea = roofLength * rafterLength * 2;

    // Panel coverage: 26" wide, with 1-2 rib overlap
    // Effective coverage: ~24" (1 rib) or ~22" (2 rib)
    double effectiveWidth;
    if (_overlap == '1 Rib') {
      effectiveWidth = 24.0 / 12;
    } else {
      effectiveWidth = 22.0 / 12;
    }

    // Panel length
    double panelLen;
    switch (_panelLength) {
      case '8 ft':
        panelLen = 8;
        break;
      case '10 ft':
        panelLen = 10;
        break;
      case '12 ft':
        panelLen = 12;
        break;
      default:
        panelLen = 10;
    }

    // Panels needed per side
    final panelsAcross = (roofLength / effectiveWidth).ceil();
    final panelsUp = (rafterLength / (panelLen - 0.5)).ceil(); // 6" end lap
    final panelsPerSide = panelsAcross * panelsUp;
    final panelsNeeded = panelsPerSide * 2;

    // Screws: ~15 per panel
    final screwsNeeded = (panelsNeeded * 15 * 1.1).ceil();

    // Closure strips (eave and ridge)
    final closureFeet = roofLength * 4; // Both eaves and ridges, both sides

    // Ridge cap
    final ridgeCap = roofLength * 1.1;

    setState(() {
      _roofArea = roofArea;
      _panelsNeeded = panelsNeeded;
      _screwsNeeded = screwsNeeded;
      _closureFeet = closureFeet;
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
    _roofLengthController.text = '24';
    _roofWidthController.text = '20';
    _pitchController.text = '3';
    setState(() {
      _panelLength = '10 ft';
      _overlap = '1 Rib';
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
        title: Text('Corrugated Panel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL OPTIONS'),
              const SizedBox(height: 12),
              _buildLengthSelector(colors),
              const SizedBox(height: 12),
              _buildOverlapSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Eave line',
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
              Icon(LucideIcons.waves, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Corrugated Panel Calculator',
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
            'Calculate corrugated metal roofing panels',
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

  Widget _buildLengthSelector(ZaftoColors colors) {
    final lengths = ['8 ft', '10 ft', '12 ft'];
    return Row(
      children: lengths.map((length) {
        final isSelected = _panelLength == length;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _panelLength = length);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: length != lengths.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                length,
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

  Widget _buildOverlapSelector(ZaftoColors colors) {
    final overlaps = ['1 Rib', '2 Rib'];
    return Row(
      children: overlaps.map((overlap) {
        final isSelected = _overlap == overlap;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _overlap = overlap);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: overlap != overlaps.last ? 8 : 0),
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
                    overlap,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    overlap == '1 Rib' ? '24" coverage' : '22" coverage',
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
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'PANELS NEEDED', '$_panelsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Screws', '$_screwsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Closure Strips', '${_closureFeet!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Cap', '${_ridgeCap!.toStringAsFixed(0)} lin ft'),
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
                    Text('Installation Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('End lap: 6" minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Side lap: 1-2 ribs based on slope', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Use closure strips at eave/ridge', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
