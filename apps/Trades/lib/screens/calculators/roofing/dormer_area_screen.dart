import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dormer Area Calculator - Calculate dormer roofing area
class DormerAreaScreen extends ConsumerStatefulWidget {
  const DormerAreaScreen({super.key});
  @override
  ConsumerState<DormerAreaScreen> createState() => _DormerAreaScreenState();
}

class _DormerAreaScreenState extends ConsumerState<DormerAreaScreen> {
  final _widthController = TextEditingController(text: '8');
  final _depthController = TextEditingController(text: '6');
  final _pitchController = TextEditingController(text: '6');
  final _countController = TextEditingController(text: '2');

  String _dormerType = 'Gable';

  double? _singleDormerArea;
  double? _totalDormerArea;
  double? _valleyLength;
  double? _ridgeLength;

  @override
  void dispose() {
    _widthController.dispose();
    _depthController.dispose();
    _pitchController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);
    final pitch = double.tryParse(_pitchController.text);
    final count = int.tryParse(_countController.text);

    if (width == null || depth == null || pitch == null || count == null) {
      setState(() {
        _singleDormerArea = null;
        _totalDormerArea = null;
        _valleyLength = null;
        _ridgeLength = null;
      });
      return;
    }

    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    double singleDormerArea;
    double ridgeLength;
    double valleyLength;

    switch (_dormerType) {
      case 'Gable':
        // Two sloped sides meeting at ridge
        final halfWidth = width / 2;
        final rakeLength = halfWidth * pitchFactor;
        singleDormerArea = 2 * depth * rakeLength;
        ridgeLength = depth;
        // Valleys where dormer meets main roof
        valleyLength = 2 * math.sqrt(math.pow(depth, 2) + math.pow(halfWidth, 2));
        break;
      case 'Shed':
        // Single sloped surface
        singleDormerArea = width * depth * pitchFactor;
        ridgeLength = width; // Top edge
        valleyLength = 2 * depth; // Side edges
        break;
      case 'Hip':
        // Three sloped surfaces
        final halfWidth = width / 2;
        final frontArea = width * halfWidth * pitchFactor;
        final sideArea = 2 * (depth * halfWidth * pitchFactor / 2);
        singleDormerArea = frontArea + sideArea;
        ridgeLength = 0; // Hip dormers have no ridge
        valleyLength = 2 * math.sqrt(math.pow(depth, 2) + math.pow(halfWidth, 2));
        break;
      default:
        singleDormerArea = width * depth * pitchFactor;
        ridgeLength = depth;
        valleyLength = 2 * depth;
    }

    final totalDormerArea = singleDormerArea * count;

    setState(() {
      _singleDormerArea = singleDormerArea;
      _totalDormerArea = totalDormerArea;
      _valleyLength = valleyLength * count;
      _ridgeLength = ridgeLength * count;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.text = '8';
    _depthController.text = '6';
    _pitchController.text = '6';
    _countController.text = '2';
    setState(() => _dormerType = 'Gable');
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
        title: Text('Dormer Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DORMER TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DORMER DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Face width',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Depth',
                      unit: 'ft',
                      hint: 'Projection',
                      controller: _depthController,
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
                      label: 'Pitch',
                      unit: '/12',
                      hint: 'Dormer pitch',
                      controller: _pitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Count',
                      unit: 'qty',
                      hint: 'Number',
                      controller: _countController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_singleDormerArea != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
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
              Icon(LucideIcons.square, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Dormer Area Calculator',
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
            'Calculate dormer roofing area and trim',
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
    final types = ['Gable', 'Shed', 'Hip'];
    return Row(
      children: types.map((type) {
        final isSelected = _dormerType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _dormerType = type);
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
          _buildResultRow(colors, 'Single Dormer', '${_singleDormerArea!.toStringAsFixed(1)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL DORMER AREA', '${_totalDormerArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Total Valley Length', '${_valleyLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Total Ridge Length', '${_ridgeLength!.toStringAsFixed(1)} ft'),
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
                    'Add dormer area to main roof area. Valley flashing required at intersections.',
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
