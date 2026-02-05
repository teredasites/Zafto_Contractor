import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Snow Load Calculator - Calculate roof snow loads per code
class SnowLoadScreen extends ConsumerStatefulWidget {
  const SnowLoadScreen({super.key});
  @override
  ConsumerState<SnowLoadScreen> createState() => _SnowLoadScreenState();
}

class _SnowLoadScreenState extends ConsumerState<SnowLoadScreen> {
  final _groundSnowController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');
  final _roofAreaController = TextEditingController(text: '2000');

  String _exposureCategory = 'Partially Exposed';
  String _roofType = 'Heated';

  double? _flatRoofLoad;
  double? _slopedRoofLoad;
  double? _totalSnowWeight;
  double? _slopeReduction;

  @override
  void dispose() {
    _groundSnowController.dispose();
    _pitchController.dispose();
    _roofAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final groundSnow = double.tryParse(_groundSnowController.text);
    final pitch = double.tryParse(_pitchController.text);
    final roofArea = double.tryParse(_roofAreaController.text);

    if (groundSnow == null || pitch == null || roofArea == null) {
      setState(() {
        _flatRoofLoad = null;
        _slopedRoofLoad = null;
        _totalSnowWeight = null;
        _slopeReduction = null;
      });
      return;
    }

    // ASCE 7 simplified method
    // pf = 0.7 × Ce × Ct × Is × pg

    // Exposure coefficient (Ce)
    double ce;
    switch (_exposureCategory) {
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
    switch (_roofType) {
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

    // Importance factor (residential = 1.0)
    const is_ = 1.0;

    // Flat roof snow load
    final flatRoofLoad = 0.7 * ce * ct * is_ * groundSnow;

    // Slope reduction factor
    // For warm roofs: Cs = 1.0 - (slope - 30°)/40° for slopes > 30°
    final slopeAngle = math.atan(pitch / 12) * (180 / math.pi);
    double cs = 1.0;
    if (slopeAngle > 30) {
      cs = 1.0 - (slopeAngle - 30) / 40;
      if (cs < 0) cs = 0;
    }

    final slopeReduction = (1 - cs) * 100;
    final slopedRoofLoad = flatRoofLoad * cs;

    // Total snow weight
    final totalSnowWeight = slopedRoofLoad * roofArea;

    setState(() {
      _flatRoofLoad = flatRoofLoad;
      _slopedRoofLoad = slopedRoofLoad;
      _totalSnowWeight = totalSnowWeight;
      _slopeReduction = slopeReduction;
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
    _pitchController.text = '6';
    _roofAreaController.text = '2000';
    setState(() {
      _exposureCategory = 'Partially Exposed';
      _roofType = 'Heated';
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
        title: Text('Snow Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SITE CONDITIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ground Snow',
                      unit: 'PSF',
                      hint: 'pg value',
                      controller: _groundSnowController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Pitch',
                      unit: '/12',
                      hint: 'Rise/run',
                      controller: _pitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Area',
                unit: 'sq ft',
                hint: 'Horizontal projection',
                controller: _roofAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildExposureSelector(colors),
              const SizedBox(height: 12),
              _buildRoofTypeSelector(colors),
              const SizedBox(height: 32),
              if (_slopedRoofLoad != null) ...[
                _buildSectionHeader(colors, 'DESIGN SNOW LOAD'),
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
            'ASCE 7 roof snow load calculation',
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

  Widget _buildExposureSelector(ZaftoColors colors) {
    final exposures = ['Fully Exposed', 'Partially Exposed', 'Sheltered'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _exposureCategory,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: exposures.map((exp) {
            return DropdownMenuItem(value: exp, child: Text(exp));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _exposureCategory = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoofTypeSelector(ZaftoColors colors) {
    final types = ['Heated', 'Unheated', 'Cold'];
    return Row(
      children: types.map((type) {
        final isSelected = _roofType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _roofType = type);
              _calculate();
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
          _buildResultRow(colors, 'Flat Roof Load (pf)', '${_flatRoofLoad!.toStringAsFixed(1)} PSF'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Slope Reduction', '${_slopeReduction!.toStringAsFixed(0)}%'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'DESIGN SNOW LOAD', '${_slopedRoofLoad!.toStringAsFixed(1)} PSF', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Total Snow Weight', '${(_totalSnowWeight! / 1000).toStringAsFixed(1)} kips'),
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
                    Text('ASCE 7 Coefficients', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ce: Fully Exposed=0.8, Partial=1.0, Sheltered=1.2', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                Text('Ct: Heated=1.0, Unheated=1.1, Cold=1.2', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                Text('Slope reduction starts at 30° for warm roofs', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
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
