import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Chimney Flashing Calculator - Calculate chimney flashing materials
class ChimneyFlashingScreen extends ConsumerStatefulWidget {
  const ChimneyFlashingScreen({super.key});
  @override
  ConsumerState<ChimneyFlashingScreen> createState() => _ChimneyFlashingScreenState();
}

class _ChimneyFlashingScreenState extends ConsumerState<ChimneyFlashingScreen> {
  final _widthController = TextEditingController(text: '36');
  final _depthController = TextEditingController(text: '24');
  final _exposedHeightController = TextEditingController(text: '8');

  String _material = 'Aluminum';

  double? _apronLength;
  double? _stepFlashingLength;
  double? _counterFlashingLength;
  double? _cricketArea;
  double? _totalSheetMetal;

  @override
  void dispose() {
    _widthController.dispose();
    _depthController.dispose();
    _exposedHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);
    final exposedHeight = double.tryParse(_exposedHeightController.text);

    if (width == null || depth == null || exposedHeight == null) {
      setState(() {
        _apronLength = null;
        _stepFlashingLength = null;
        _counterFlashingLength = null;
        _cricketArea = null;
        _totalSheetMetal = null;
      });
      return;
    }

    // Front apron: width + 6" on each side turn-up
    final apronLength = width + 12;

    // Step flashing: both sides of chimney
    final stepFlashingLength = depth * 2;

    // Counter flashing: all 4 sides + overlaps
    final counterFlashingLength = (width * 2) + (depth * 2) + 12; // 12" for overlaps

    // Cricket/saddle: for chimneys > 30" wide on upslope
    double cricketArea = 0;
    if (width > 30) {
      // Cricket is typically triangular, width × depth/2
      cricketArea = (width / 12) * (depth / 2 / 12); // in sq ft
    }

    // Total sheet metal needed (rough estimate)
    // Apron: width × 8"
    // Step: 2 sides × depth × 6"
    // Counter: perimeter × 5"
    // Cricket: calculated above
    final apronSqIn = apronLength * 8;
    final stepSqIn = stepFlashingLength * 6;
    final counterSqIn = counterFlashingLength * 5;
    final totalSheetMetal = (apronSqIn + stepSqIn + counterSqIn) / 144 + cricketArea;

    setState(() {
      _apronLength = apronLength;
      _stepFlashingLength = stepFlashingLength;
      _counterFlashingLength = counterFlashingLength;
      _cricketArea = cricketArea;
      _totalSheetMetal = totalSheetMetal * 1.15; // 15% waste
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _widthController.text = '36';
    _depthController.text = '24';
    _exposedHeightController.text = '8';
    setState(() => _material = 'Aluminum');
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
        title: Text('Chimney Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MATERIAL'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CHIMNEY DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'in',
                      hint: 'Front face',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Depth',
                      unit: 'in',
                      hint: 'Side to side',
                      controller: _depthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Exposed Height',
                unit: 'in',
                hint: 'Above roof',
                controller: _exposedHeightController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalSheetMetal != null) ...[
                _buildSectionHeader(colors, 'FLASHING COMPONENTS'),
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
              Icon(LucideIcons.flame, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Chimney Flashing Calculator',
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
            'Calculate complete chimney flashing kit',
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

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Aluminum', 'Copper', 'Lead', 'Galvanized'];
    return Row(
      children: materials.map((mat) {
        final isSelected = _material == mat;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _material = mat);
            },
            child: Container(
              margin: EdgeInsets.only(right: mat != materials.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                mat,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 11,
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
          _buildResultRow(colors, 'TOTAL SHEET METAL', '${_totalSheetMetal!.toStringAsFixed(1)} sq ft', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Front Apron', '${_apronLength!.toStringAsFixed(0)}" long'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Step Flashing', '${_stepFlashingLength!.toStringAsFixed(0)}" total'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Counter Flash', '${_counterFlashingLength!.toStringAsFixed(0)}" total'),
          if (_cricketArea! > 0) ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Cricket/Saddle', '${_cricketArea!.toStringAsFixed(1)} sq ft'),
          ],
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
                    Text('Chimney Flashing', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Cricket required if width > 30"', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Two-piece system: base + counter', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Counter flash into mortar joints', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
