import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Snow Load Calculator - Roof snow load analysis
class SnowLoadCalculatorScreen extends ConsumerStatefulWidget {
  const SnowLoadCalculatorScreen({super.key});
  @override
  ConsumerState<SnowLoadCalculatorScreen> createState() => _SnowLoadCalculatorScreenState();
}

class _SnowLoadCalculatorScreenState extends ConsumerState<SnowLoadCalculatorScreen> {
  final _groundSnowController = TextEditingController(text: '30');
  final _roofSlopeController = TextEditingController(text: '20');
  final _panelTiltController = TextEditingController(text: '25');
  final _panelAreaController = TextEditingController(text: '21.5');
  final _numPanelsController = TextEditingController(text: '20');

  String _roofType = 'Slippery';
  String _exposure = 'Partially Exposed';
  String _thermalFactor = 'Heated';

  double? _flatRoofSnowLoad;
  double? _slopedRoofSnowLoad;
  double? _panelSnowLoad;
  double? _totalArrayLoad;
  String? _recommendation;

  @override
  void dispose() {
    _groundSnowController.dispose();
    _roofSlopeController.dispose();
    _panelTiltController.dispose();
    _panelAreaController.dispose();
    _numPanelsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final groundSnow = double.tryParse(_groundSnowController.text);
    final roofSlope = double.tryParse(_roofSlopeController.text);
    final panelTilt = double.tryParse(_panelTiltController.text);
    final panelArea = double.tryParse(_panelAreaController.text);
    final numPanels = int.tryParse(_numPanelsController.text);

    if (groundSnow == null || roofSlope == null || panelTilt == null ||
        panelArea == null || numPanels == null) {
      setState(() {
        _flatRoofSnowLoad = null;
        _slopedRoofSnowLoad = null;
        _panelSnowLoad = null;
        _totalArrayLoad = null;
        _recommendation = null;
      });
      return;
    }

    // ASCE 7 Snow Load Calculation
    // pf = 0.7 * Ce * Ct * Is * pg

    // Exposure factor (Ce)
    double ce;
    switch (_exposure) {
      case 'Fully Exposed':
        ce = 0.8;
        break;
      case 'Partially Exposed':
        ce = 1.0;
        break;
      case 'Sheltered':
        ce = 1.2;
        break;
      default:
        ce = 1.0;
    }

    // Thermal factor (Ct)
    double ct;
    switch (_thermalFactor) {
      case 'Heated':
        ct = 1.0;
        break;
      case 'Unheated':
        ct = 1.1;
        break;
      case 'Cold':
        ct = 1.2;
        break;
      default:
        ct = 1.0;
    }

    // Importance factor (Is) - assume residential = 1.0
    const is_ = 1.0;

    // Flat roof snow load
    final flatRoofSnowLoad = 0.7 * ce * ct * is_ * groundSnow;

    // Slope factor (Cs) - for sloped roofs
    double cs;
    if (_roofType == 'Slippery') {
      // Slippery surface (metal, membrane)
      if (roofSlope <= 5) {
        cs = 1.0;
      } else if (roofSlope >= 70) {
        cs = 0.0;
      } else {
        cs = 1.0 - (roofSlope - 5) / 65;
      }
    } else {
      // Non-slippery surface
      if (roofSlope <= 30) {
        cs = 1.0;
      } else if (roofSlope >= 70) {
        cs = 0.0;
      } else {
        cs = 1.0 - (roofSlope - 30) / 40;
      }
    }
    cs = cs.clamp(0.0, 1.0);

    // Sloped roof snow load
    final slopedRoofSnowLoad = flatRoofSnowLoad * cs;

    // Panel snow load - panels typically shed snow faster due to tilt
    // Use panel tilt for additional reduction
    double panelCs;
    if (panelTilt >= 45) {
      panelCs = 0.3; // Steep panels shed quickly
    } else if (panelTilt >= 30) {
      panelCs = 0.5;
    } else if (panelTilt >= 15) {
      panelCs = 0.7;
    } else {
      panelCs = 0.9; // Low tilt retains more snow
    }

    final panelSnowLoad = slopedRoofSnowLoad * panelCs;

    // Total array load
    final totalArrayLoad = panelSnowLoad * panelArea * numPanels;

    String recommendation;
    if (panelSnowLoad > 40) {
      recommendation = 'Heavy snow region. Verify mount snow ratings and consider steeper tilt.';
    } else if (panelSnowLoad > 25) {
      recommendation = 'Moderate snow load. Standard heavy-duty mounts recommended.';
    } else if (panelSnowLoad > 10) {
      recommendation = 'Light to moderate snow. Most standard mounts adequate.';
    } else {
      recommendation = 'Minimal snow load concern. Standard installation practices apply.';
    }

    setState(() {
      _flatRoofSnowLoad = flatRoofSnowLoad;
      _slopedRoofSnowLoad = slopedRoofSnowLoad;
      _panelSnowLoad = panelSnowLoad;
      _totalArrayLoad = totalArrayLoad;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _groundSnowController.text = '30';
    _roofSlopeController.text = '20';
    _panelTiltController.text = '25';
    _panelAreaController.text = '21.5';
    _numPanelsController.text = '20';
    setState(() {
      _roofType = 'Slippery';
      _exposure = 'Partially Exposed';
      _thermalFactor = 'Heated';
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
        title: Text('Snow Load Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SNOW DATA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ground Snow',
                      unit: 'psf',
                      hint: 'Pg value',
                      controller: _groundSnowController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Slope',
                      unit: 'deg',
                      hint: 'Roof angle',
                      controller: _roofSlopeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'FACTORS'),
              const SizedBox(height: 12),
              _buildFactorRow(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Tilt',
                      unit: 'deg',
                      hint: 'Array angle',
                      controller: _panelTiltController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Area',
                      unit: 'sq ft',
                      hint: 'Per panel',
                      controller: _panelAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Number of Panels',
                unit: 'qty',
                hint: 'Total count',
                controller: _numPanelsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_panelSnowLoad != null) ...[
                _buildSectionHeader(colors, 'SNOW LOAD ANALYSIS'),
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
              Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Snow Load Calculator',
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
            'ASCE 7 based snow load for solar arrays',
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

  Widget _buildFactorRow(ZaftoColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown(colors, 'Surface', _roofType, ['Slippery', 'Non-Slippery'], (v) {
              setState(() => _roofType = v);
              _calculate();
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown(colors, 'Exposure', _exposure, ['Fully Exposed', 'Partially Exposed', 'Sheltered'], (v) {
              setState(() => _exposure = v);
              _calculate();
            })),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdown(colors, 'Thermal', _thermalFactor, ['Heated', 'Unheated', 'Cold'], (v) {
          setState(() => _thermalFactor = v);
          _calculate();
        }),
      ],
    );
  }

  Widget _buildDropdown(ZaftoColors colors, String label, String value, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt, overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              HapticFeedback.selectionClick();
              onChanged(v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Design Snow Load on Panels', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _panelSnowLoad!.toStringAsFixed(1),
                style: TextStyle(color: colors.accentInfo, fontSize: 40, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ' psf',
                  style: TextStyle(color: colors.textSecondary, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Flat Roof', '${_flatRoofSnowLoad!.toStringAsFixed(1)} psf', colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Sloped Roof', '${_slopedRoofSnowLoad!.toStringAsFixed(1)} psf', colors.accentPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text('Total Array Snow Load', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${_totalArrayLoad!.toStringAsFixed(0)} lbs',
                  style: TextStyle(color: colors.accentWarning, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
                    _recommendation!,
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

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
