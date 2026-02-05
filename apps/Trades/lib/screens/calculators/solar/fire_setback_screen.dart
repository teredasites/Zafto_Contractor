import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fire Setback Calculator - Code-compliant setback requirements
class FireSetbackScreen extends ConsumerStatefulWidget {
  const FireSetbackScreen({super.key});
  @override
  ConsumerState<FireSetbackScreen> createState() => _FireSetbackScreenState();
}

class _FireSetbackScreenState extends ConsumerState<FireSetbackScreen> {
  final _roofWidthController = TextEditingController(text: '40');
  final _roofLengthController = TextEditingController(text: '60');
  final _ridgeSetbackController = TextEditingController(text: '3');
  final _hipSetbackController = TextEditingController(text: '18');
  final _valleySetbackController = TextEditingController(text: '18');
  final _eaveSetbackController = TextEditingController(text: '3');

  String _roofType = 'Gable';
  String _jurisdiction = 'IFC 2021';

  double? _usableArea;
  double? _totalRoofArea;
  double? _usablePercent;
  String? _pathwayRequirements;
  String? _recommendation;

  @override
  void dispose() {
    _roofWidthController.dispose();
    _roofLengthController.dispose();
    _ridgeSetbackController.dispose();
    _hipSetbackController.dispose();
    _valleySetbackController.dispose();
    _eaveSetbackController.dispose();
    super.dispose();
  }

  void _applyJurisdictionDefaults() {
    switch (_jurisdiction) {
      case 'IFC 2021':
        _ridgeSetbackController.text = '3';
        _hipSetbackController.text = '18';
        _valleySetbackController.text = '18';
        _eaveSetbackController.text = '3';
        break;
      case 'California (Title 24)':
        _ridgeSetbackController.text = '3';
        _hipSetbackController.text = '3';
        _valleySetbackController.text = '3';
        _eaveSetbackController.text = '3';
        break;
      case 'No Requirements':
        _ridgeSetbackController.text = '0';
        _hipSetbackController.text = '0';
        _valleySetbackController.text = '0';
        _eaveSetbackController.text = '0';
        break;
    }
  }

  void _calculate() {
    final roofWidth = double.tryParse(_roofWidthController.text);
    final roofLength = double.tryParse(_roofLengthController.text);
    final ridgeSetback = double.tryParse(_ridgeSetbackController.text);
    final hipSetback = double.tryParse(_hipSetbackController.text);
    final valleySetback = double.tryParse(_valleySetbackController.text);
    final eaveSetback = double.tryParse(_eaveSetbackController.text);

    if (roofWidth == null || roofLength == null || ridgeSetback == null ||
        hipSetback == null || valleySetback == null || eaveSetback == null) {
      setState(() {
        _usableArea = null;
        _totalRoofArea = null;
        _usablePercent = null;
        _pathwayRequirements = null;
        _recommendation = null;
      });
      return;
    }

    final totalRoofArea = roofWidth * roofLength;

    // Calculate usable dimensions after setbacks
    double usableWidth;
    double usableLength;

    switch (_roofType) {
      case 'Gable':
        // Ridge at one end, eaves on sides
        usableWidth = roofWidth - (eaveSetback * 2);
        usableLength = roofLength - ridgeSetback - eaveSetback;
        break;
      case 'Hip':
        // Setbacks on all sides
        usableWidth = roofWidth - (hipSetback * 2);
        usableLength = roofLength - ridgeSetback - hipSetback;
        break;
      case 'Flat':
        // Perimeter setbacks only
        usableWidth = roofWidth - (eaveSetback * 2);
        usableLength = roofLength - (eaveSetback * 2);
        break;
      default:
        usableWidth = roofWidth - (eaveSetback * 2);
        usableLength = roofLength - ridgeSetback - eaveSetback;
    }

    // Ensure positive values
    usableWidth = usableWidth > 0 ? usableWidth : 0;
    usableLength = usableLength > 0 ? usableLength : 0;

    final usableArea = usableWidth * usableLength;
    final usablePercent = totalRoofArea > 0 ? (usableArea / totalRoofArea) * 100 : 0;

    // Pathway requirements based on jurisdiction
    String pathwayRequirements;
    switch (_jurisdiction) {
      case 'IFC 2021':
        pathwayRequirements = '3 ft ridge setback, 3 ft pathway from eave to ridge on each slope. Hip/valley: 18" clear.';
        break;
      case 'California (Title 24)':
        pathwayRequirements = '3 ft perimeter setbacks. Pathways per local fire marshal. NSHP access required.';
        break;
      case 'No Requirements':
        pathwayRequirements = 'No specific fire setbacks required. Verify with local AHJ.';
        break;
      default:
        pathwayRequirements = 'Check local fire code requirements.';
    }

    String recommendation;
    if (usablePercent > 80) {
      recommendation = 'Excellent usable area. Minimal impact from setbacks.';
    } else if (usablePercent > 60) {
      recommendation = 'Good usable area. Standard setback requirements applied.';
    } else if (usablePercent > 40) {
      recommendation = 'Moderate usable area. Consider alternative layouts.';
    } else {
      recommendation = 'Limited usable area. Small or complex roof shape.';
    }

    setState(() {
      _usableArea = usableArea;
      _totalRoofArea = totalRoofArea;
      _usablePercent = usablePercent.toDouble();
      _pathwayRequirements = pathwayRequirements;
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
    _roofWidthController.text = '40';
    _roofLengthController.text = '60';
    setState(() {
      _roofType = 'Gable';
      _jurisdiction = 'IFC 2021';
    });
    _applyJurisdictionDefaults();
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
        title: Text('Fire Setbacks', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'JURISDICTION'),
              const SizedBox(height: 12),
              _buildJurisdictionSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF'),
              const SizedBox(height: 12),
              _buildRoofTypeSelector(colors),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Width',
                      unit: 'ft',
                      hint: 'Side to side',
                      controller: _roofWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Length',
                      unit: 'ft',
                      hint: 'Front to back',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SETBACKS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ridge',
                      unit: 'ft',
                      hint: 'From ridge',
                      controller: _ridgeSetbackController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave',
                      unit: 'ft',
                      hint: 'From eave',
                      controller: _eaveSetbackController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Hip',
                      unit: 'in',
                      hint: 'From hip',
                      controller: _hipSetbackController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Valley',
                      unit: 'in',
                      hint: 'From valley',
                      controller: _valleySetbackController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_usableArea != null) ...[
                _buildSectionHeader(colors, 'USABLE AREA'),
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
              Icon(LucideIcons.flame, color: colors.accentWarning, size: 18),
              const SizedBox(width: 8),
              Text(
                'Fire Setback Calculator',
                style: TextStyle(
                  color: colors.accentWarning,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate code-required fire access setbacks',
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

  Widget _buildJurisdictionSelector(ZaftoColors colors) {
    final jurisdictions = ['IFC 2021', 'California (Title 24)', 'No Requirements'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _jurisdiction,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: jurisdictions.map((j) {
            return DropdownMenuItem(value: j, child: Text(j));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _jurisdiction = value);
              _applyJurisdictionDefaults();
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoofTypeSelector(ZaftoColors colors) {
    final types = ['Gable', 'Hip', 'Flat'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _usablePercent! > 60;
    final statusColor = _usablePercent! > 70 ? colors.accentSuccess : (_usablePercent! > 50 ? colors.accentInfo : colors.accentWarning);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Total Roof', '${_totalRoofArea!.toStringAsFixed(0)} sq ft', colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Usable Area', '${_usableArea!.toStringAsFixed(0)} sq ft', statusColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Usable Percentage', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                Text(
                  '${_usablePercent!.toStringAsFixed(0)}%',
                  style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PATHWAY REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  _pathwayRequirements!,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
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
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
