import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Cricket Calculator - Calculate chimney cricket/saddle dimensions
class RoofCricketScreen extends ConsumerStatefulWidget {
  const RoofCricketScreen({super.key});
  @override
  ConsumerState<RoofCricketScreen> createState() => _RoofCricketScreenState();
}

class _RoofCricketScreenState extends ConsumerState<RoofCricketScreen> {
  final _chimneyWidthController = TextEditingController(text: '36');
  final _roofPitchController = TextEditingController(text: '6');

  String _cricketStyle = 'Peaked';

  double? _cricketWidth;
  double? _cricketLength;
  double? _cricketHeight;
  double? _materialArea;
  double? _flashingLength;

  @override
  void dispose() {
    _chimneyWidthController.dispose();
    _roofPitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final chimneyWidth = double.tryParse(_chimneyWidthController.text);
    final roofPitch = double.tryParse(_roofPitchController.text);

    if (chimneyWidth == null || roofPitch == null) {
      setState(() {
        _cricketWidth = null;
        _cricketLength = null;
        _cricketHeight = null;
        _materialArea = null;
        _flashingLength = null;
      });
      return;
    }

    // Cricket width equals chimney width
    final cricketWidth = chimneyWidth;

    // Cricket length (from chimney to ridge of cricket)
    // Rule of thumb: length = width / 2 for peaked, width for flat-top
    double cricketLength;
    if (_cricketStyle == 'Peaked') {
      cricketLength = cricketWidth / 2;
    } else {
      cricketLength = cricketWidth * 0.75;
    }

    // Cricket height at ridge
    // Should match roof slope or be slightly steeper
    final cricketPitch = roofPitch + 2; // Slightly steeper than main roof
    final cricketHeight = (cricketPitch / 12) * cricketLength;

    // Material area (two triangular sides + optional flat top)
    double materialArea;
    if (_cricketStyle == 'Peaked') {
      // Two triangular faces
      final sideLength = math.sqrt(math.pow(cricketLength, 2) + math.pow(cricketHeight, 2));
      materialArea = 2 * (cricketWidth / 2 * sideLength / 2);
    } else {
      // Flat-top saddle
      final sideLength = math.sqrt(math.pow(cricketLength, 2) + math.pow(cricketHeight, 2));
      materialArea = (cricketWidth * cricketLength) + (2 * cricketLength * sideLength / 2);
    }

    // Add waste factor
    materialArea = materialArea * 1.2 / 144; // Convert to sq ft

    // Flashing length (perimeter minus chimney side)
    final flashingLength = (cricketWidth + cricketLength * 2) / 12;

    setState(() {
      _cricketWidth = cricketWidth;
      _cricketLength = cricketLength;
      _cricketHeight = cricketHeight;
      _materialArea = materialArea;
      _flashingLength = flashingLength;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _chimneyWidthController.text = '36';
    _roofPitchController.text = '6';
    setState(() => _cricketStyle = 'Peaked');
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
        title: Text('Roof Cricket', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CRICKET STYLE'),
              const SizedBox(height: 12),
              _buildStyleSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Chimney Width',
                      unit: 'in',
                      hint: 'Upslope face',
                      controller: _chimneyWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Pitch',
                      unit: '/12',
                      hint: 'Main roof',
                      controller: _roofPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_materialArea != null) ...[
                _buildSectionHeader(colors, 'CRICKET DIMENSIONS'),
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
              Icon(LucideIcons.triangle, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Cricket Calculator',
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
            'Calculate chimney cricket/saddle dimensions',
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

  Widget _buildStyleSelector(ZaftoColors colors) {
    final styles = ['Peaked', 'Flat-Top'];
    return Row(
      children: styles.map((style) {
        final isSelected = _cricketStyle == style;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _cricketStyle = style);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: style != styles.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                    style,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    style == 'Peaked' ? 'Standard' : 'Saddle',
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
          _buildResultRow(colors, 'Cricket Width', '${_cricketWidth!.toStringAsFixed(0)}"'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Cricket Length', '${_cricketLength!.toStringAsFixed(1)}"'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Cricket Height', '${_cricketHeight!.toStringAsFixed(1)}"'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'MATERIAL AREA', '${_materialArea!.toStringAsFixed(1)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Flashing Length', '${_flashingLength!.toStringAsFixed(1)} ft'),
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
                    Text('Cricket Requirements', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Required when chimney > 30" wide', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Prevents water/debris buildup', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Slope should match or exceed roof', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
