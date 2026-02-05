import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// R-Panel Calculator - Calculate R-panel (PBR) metal roofing
class RPanelScreen extends ConsumerStatefulWidget {
  const RPanelScreen({super.key});
  @override
  ConsumerState<RPanelScreen> createState() => _RPanelScreenState();
}

class _RPanelScreenState extends ConsumerState<RPanelScreen> {
  final _roofLengthController = TextEditingController(text: '60');
  final _roofWidthController = TextEditingController(text: '40');
  final _pitchController = TextEditingController(text: '3');

  String _gauge = '26 Gauge';
  String _panelCoverage = '36"';

  double? _roofArea;
  int? _panelsNeeded;
  int? _screwsNeeded;
  double? _trimFeet;
  int? _purlins;

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
        _trimFeet = null;
        _purlins = null;
      });
      return;
    }

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Rafter length
    final run = roofWidth / 2;
    final rafterLength = run * pitchFactor;

    // Roof area (both sides for gable)
    final roofArea = roofLength * rafterLength * 2;

    // Panel coverage
    double coverageFt;
    switch (_panelCoverage) {
      case '36"':
        coverageFt = 3.0;
        break;
      case '42"':
        coverageFt = 3.5;
        break;
      default:
        coverageFt = 3.0;
    }

    // Panels per side
    final panelsAcross = (roofLength / coverageFt).ceil();
    final panelsNeeded = panelsAcross * 2; // Both sides

    // Panel length matches rafter length (custom cut)

    // Screws: approximately 20 per panel
    final screwsNeeded = (panelsNeeded * 20 * 1.1).ceil();

    // Trim footage (ridge, eave, rake)
    final ridgeTrim = roofLength;
    final eaveTrim = roofLength * 2; // Both sides
    final rakeTrim = rafterLength * 4; // 4 rakes for gable
    final trimFeet = (ridgeTrim + eaveTrim + rakeTrim) * 1.1;

    // Purlins (24" spacing on metal)
    final purlinsPerSide = (rafterLength * 12 / 24).ceil() + 1;
    final purlins = purlinsPerSide * 2;

    setState(() {
      _roofArea = roofArea;
      _panelsNeeded = panelsNeeded;
      _screwsNeeded = screwsNeeded;
      _trimFeet = trimFeet;
      _purlins = purlins;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofLengthController.text = '60';
    _roofWidthController.text = '40';
    _pitchController.text = '3';
    setState(() {
      _gauge = '26 Gauge';
      _panelCoverage = '36"';
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
        title: Text('R-Panel', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildGaugeSelector(colors),
              const SizedBox(height: 12),
              _buildCoverageSelector(colors),
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
                      hint: 'Building',
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
                'R-Panel Calculator',
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
            'Calculate PBR/R-panel metal roofing',
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

  Widget _buildGaugeSelector(ZaftoColors colors) {
    final gauges = ['29 Gauge', '26 Gauge', '24 Gauge'];
    return Row(
      children: gauges.map((gauge) {
        final isSelected = _gauge == gauge;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _gauge = gauge);
            },
            child: Container(
              margin: EdgeInsets.only(right: gauge != gauges.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                gauge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoverageSelector(ZaftoColors colors) {
    final coverages = ['36"', '42"'];
    return Row(
      children: coverages.map((coverage) {
        final isSelected = _panelCoverage == coverage;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _panelCoverage = coverage);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: coverage != coverages.last ? 8 : 0),
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
                    coverage,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Coverage',
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
          _buildResultRow(colors, 'R-PANELS NEEDED', '$_panelsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Screws', '$_screwsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Trim', '${_trimFeet!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Purlin Rows', '$_purlins'),
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
                    'R-Panel is exposed fastener. Order panels cut to exact rafter length.',
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
