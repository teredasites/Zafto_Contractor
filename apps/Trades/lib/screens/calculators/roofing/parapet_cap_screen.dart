import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Parapet Cap Calculator - Calculate parapet coping materials
class ParapetCapScreen extends ConsumerStatefulWidget {
  const ParapetCapScreen({super.key});
  @override
  ConsumerState<ParapetCapScreen> createState() => _ParapetCapScreenState();
}

class _ParapetCapScreenState extends ConsumerState<ParapetCapScreen> {
  final _linearFeetController = TextEditingController(text: '200');
  final _wallWidthController = TextEditingController(text: '12');

  String _material = 'Aluminum';
  String _style = 'Snap-On';

  double? _copingSqFt;
  int? _copingSections;
  int? _splices;
  int? _corners;

  @override
  void dispose() {
    _linearFeetController.dispose();
    _wallWidthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final wallWidth = double.tryParse(_wallWidthController.text);

    if (linearFeet == null || wallWidth == null) {
      setState(() {
        _copingSqFt = null;
        _copingSections = null;
        _splices = null;
        _corners = null;
      });
      return;
    }

    // Coping coverage width (wall width + 2" drip edge each side)
    final copingWidth = wallWidth + 4;

    // Square footage
    final copingSqFt = linearFeet * (copingWidth / 12);

    // Coping sections (10' typical length)
    final copingSections = (linearFeet / 10 * 1.1).ceil();

    // Splices (one per joint)
    final splices = copingSections;

    // Estimate corners (assume rectangular building)
    final corners = 4;

    setState(() {
      _copingSqFt = copingSqFt;
      _copingSections = copingSections;
      _splices = splices;
      _corners = corners;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _linearFeetController.text = '200';
    _wallWidthController.text = '12';
    setState(() {
      _material = 'Aluminum';
      _style = 'Snap-On';
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
        title: Text('Parapet Cap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COPING SPECS'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildStyleSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PARAPET DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Linear Feet',
                      unit: 'ft',
                      hint: 'Total length',
                      controller: _linearFeetController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wall Width',
                      unit: 'in',
                      hint: 'Top of wall',
                      controller: _wallWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_copingSections != null) ...[
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Parapet Cap Calculator',
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
            'Calculate parapet coping/cap materials',
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
    final materials = ['Aluminum', 'Steel', 'Copper', 'Composite'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((mat) {
        final isSelected = _material == mat;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _material = mat);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              mat,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleSelector(ZaftoColors colors) {
    final styles = ['Snap-On', 'Face-Mounted', 'Gravel Stop'];
    return Row(
      children: styles.map((style) {
        final isSelected = _style == style;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _style = style);
            },
            child: Container(
              margin: EdgeInsets.only(right: style != styles.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                style,
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
          _buildResultRow(colors, 'Coping Area', '${_copingSqFt!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'COPING SECTIONS', '$_copingSections', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Splice Plates', '$_splices'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Corner Pieces', '$_corners'),
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
                    Text('Coping Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Standard section: 10\' length', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Add 2" drip edge each side', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Use color-matched sealant at joints', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
