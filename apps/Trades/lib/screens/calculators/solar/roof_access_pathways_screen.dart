import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Access Pathways Calculator - Fire access pathway design
class RoofAccessPathwaysScreen extends ConsumerStatefulWidget {
  const RoofAccessPathwaysScreen({super.key});
  @override
  ConsumerState<RoofAccessPathwaysScreen> createState() => _RoofAccessPathwaysScreenState();
}

class _RoofAccessPathwaysScreenState extends ConsumerState<RoofAccessPathwaysScreen> {
  final _roofWidthController = TextEditingController(text: '40');
  final _roofLengthController = TextEditingController(text: '60');
  final _roofSlopeController = TextEditingController(text: '4');
  final _arrayWidthController = TextEditingController(text: '30');
  final _arrayLengthController = TextEditingController(text: '45');

  String _accessType = 'Ground Ladder';
  bool _hasMultipleArrays = false;

  double? _pathwayArea;
  double? _pathwayLength;
  bool? _meetsCode;
  List<String>? _requirements;
  String? _recommendation;

  @override
  void dispose() {
    _roofWidthController.dispose();
    _roofLengthController.dispose();
    _roofSlopeController.dispose();
    _arrayWidthController.dispose();
    _arrayLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofWidth = double.tryParse(_roofWidthController.text);
    final roofLength = double.tryParse(_roofLengthController.text);
    final roofSlope = double.tryParse(_roofSlopeController.text);
    final arrayWidth = double.tryParse(_arrayWidthController.text);
    final arrayLength = double.tryParse(_arrayLengthController.text);

    if (roofWidth == null || roofLength == null || roofSlope == null ||
        arrayWidth == null || arrayLength == null) {
      setState(() {
        _pathwayArea = null;
        _pathwayLength = null;
        _meetsCode = null;
        _requirements = null;
        _recommendation = null;
      });
      return;
    }

    List<String> requirements = [];

    // IFC 2021 Requirements
    // 1. Ridge setback: 3 ft minimum
    requirements.add('Ridge setback: 3 ft minimum clear');

    // 2. Eave to ridge pathway: 3 ft wide on each slope
    requirements.add('Eave-to-ridge pathway: 3 ft wide on at least one slope');

    // 3. Pathways must be on same roof slope as access point
    if (_accessType == 'Ground Ladder') {
      requirements.add('Pathway must be accessible from ground ladder location');
    } else {
      requirements.add('Interior access: pathway from roof hatch required');
    }

    // 4. Slope considerations
    if (roofSlope >= 7) {
      requirements.add('Steep slope (>${roofSlope}:12): May require walk boards');
    }

    // 5. Multiple arrays
    if (_hasMultipleArrays) {
      requirements.add('Multiple arrays: 3 ft pathway between arrays');
    }

    // Calculate pathway dimensions
    // Perimeter pathway (3 ft around array)
    final perimeterPathway = (2 * arrayWidth + 2 * arrayLength) * 3;

    // Ridge pathway (3 ft x roof length)
    final ridgePathway = roofLength * 3;

    // Eave to ridge pathway (3 ft x roof slope length)
    final slopeFactor = 1.0 + (roofSlope / 12 * 0.2); // Approximate slope factor
    final eaveToRidgePathway = (roofWidth / 2) * slopeFactor * 3;

    final pathwayArea = perimeterPathway + ridgePathway;
    final pathwayLength = ridgePathway + eaveToRidgePathway;

    // Check code compliance
    final eaveSetback = (roofWidth - arrayWidth) / 2;
    final ridgeSetback = roofLength - arrayLength - 3; // Assuming array starts 3 ft from eave
    final meetsCode = eaveSetback >= 3 && ridgeSetback >= 3;

    String recommendation;
    if (!meetsCode) {
      recommendation = 'Array position does not meet setback requirements. Adjust layout.';
    } else if (eaveSetback >= 6 && ridgeSetback >= 6) {
      recommendation = 'Excellent clearances. Exceeds minimum requirements.';
    } else {
      recommendation = 'Meets minimum requirements. Verify local fire marshal approval.';
    }

    setState(() {
      _pathwayArea = pathwayArea;
      _pathwayLength = pathwayLength;
      _meetsCode = meetsCode;
      _requirements = requirements;
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
    _roofSlopeController.text = '4';
    _arrayWidthController.text = '30';
    _arrayLengthController.text = '45';
    setState(() {
      _accessType = 'Ground Ladder';
      _hasMultipleArrays = false;
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
        title: Text('Roof Access Pathways', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Width',
                      unit: 'ft',
                      hint: 'Eave to eave',
                      controller: _roofWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Length',
                      unit: 'ft',
                      hint: 'Ridge line',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Slope',
                unit: '/12',
                hint: 'Rise per 12 run',
                controller: _roofSlopeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array Width',
                      unit: 'ft',
                      hint: 'Panel rows',
                      controller: _arrayWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array Length',
                      unit: 'ft',
                      hint: 'Panel columns',
                      controller: _arrayLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ACCESS TYPE'),
              const SizedBox(height: 12),
              _buildAccessTypeSelector(colors),
              const SizedBox(height: 12),
              _buildMultipleArraysToggle(colors),
              const SizedBox(height: 32),
              if (_meetsCode != null) ...[
                _buildSectionHeader(colors, 'PATHWAY ANALYSIS'),
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
              Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Access Pathways',
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
            'Design fire department access pathways per IFC',
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

  Widget _buildAccessTypeSelector(ZaftoColors colors) {
    final types = ['Ground Ladder', 'Interior Hatch'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _accessType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _accessType = type);
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

  Widget _buildMultipleArraysToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.layoutGrid, color: _hasMultipleArrays ? colors.accentPrimary : colors.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Multiple Arrays on Roof',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          Switch(
            value: _hasMultipleArrays,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _hasMultipleArrays = value);
              _calculate();
            },
            activeColor: colors.accentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _meetsCode! ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _meetsCode! ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _meetsCode! ? 'Meets IFC Requirements' : 'Does Not Meet Requirements',
                  style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Pathway Area', '${_pathwayArea!.toStringAsFixed(0)} sq ft', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Pathway Length', '${_pathwayLength!.toStringAsFixed(0)} ft', colors.accentInfo),
              ),
            ],
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
                Text('IFC REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._requirements!.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(req, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
                )),
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
                Icon(LucideIcons.info, size: 16, color: _meetsCode! ? colors.accentInfo : colors.accentError),
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
