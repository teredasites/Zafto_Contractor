import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Attachment Spacing Calculator - Roof attachment layout
class AttachmentSpacingScreen extends ConsumerStatefulWidget {
  const AttachmentSpacingScreen({super.key});
  @override
  ConsumerState<AttachmentSpacingScreen> createState() => _AttachmentSpacingScreenState();
}

class _AttachmentSpacingScreenState extends ConsumerState<AttachmentSpacingScreen> {
  final _rafterSpacingController = TextEditingController(text: '24');
  final _panelWidthController = TextEditingController(text: '41');
  final _panelLengthController = TextEditingController(text: '77');
  final _windUpliftController = TextEditingController(text: '45');
  final _attachmentRatingController = TextEditingController(text: '500');

  String _orientation = 'Portrait';
  String _mountType = 'Rail';

  int? _attachmentsPerPanel;
  double? _maxSpacing;
  double? _recommendedSpacing;
  String? _layoutPattern;
  String? _recommendation;

  @override
  void dispose() {
    _rafterSpacingController.dispose();
    _panelWidthController.dispose();
    _panelLengthController.dispose();
    _windUpliftController.dispose();
    _attachmentRatingController.dispose();
    super.dispose();
  }

  void _calculate() {
    final rafterSpacing = double.tryParse(_rafterSpacingController.text);
    final panelWidth = double.tryParse(_panelWidthController.text);
    final panelLength = double.tryParse(_panelLengthController.text);
    final windUplift = double.tryParse(_windUpliftController.text);
    final attachmentRating = double.tryParse(_attachmentRatingController.text);

    if (rafterSpacing == null || panelWidth == null || panelLength == null ||
        windUplift == null || attachmentRating == null) {
      setState(() {
        _attachmentsPerPanel = null;
        _maxSpacing = null;
        _recommendedSpacing = null;
        _layoutPattern = null;
        _recommendation = null;
      });
      return;
    }

    // Panel dimensions based on orientation
    final effectiveWidth = _orientation == 'Portrait' ? panelWidth : panelLength;
    final effectiveLength = _orientation == 'Portrait' ? panelLength : panelWidth;

    // Panel area in sq ft
    final panelAreaSqFt = (panelWidth * panelLength) / 144;

    // Total uplift force per panel (lbs)
    final upliftPerPanel = windUplift * panelAreaSqFt;

    // Minimum attachments needed based on uplift and rating
    // Include 1.5 safety factor
    final minAttachments = (upliftPerPanel * 1.5 / attachmentRating).ceil();

    // Practical minimum is 4 for stability (corners)
    final attachmentsPerPanel = math.max(4, minAttachments);

    // Max spacing based on attachment rating and uplift
    // Simplified: spacing to distribute load evenly
    final maxSpacing = attachmentRating / (windUplift * 1.5);

    // Recommended spacing - align with rafter spacing when possible
    double recommendedSpacing;
    if (rafterSpacing <= maxSpacing) {
      recommendedSpacing = rafterSpacing;
    } else {
      // Use every other rafter or closest safe spacing
      recommendedSpacing = math.min(maxSpacing, rafterSpacing * 2);
    }

    // Layout pattern
    String layoutPattern;
    if (_mountType == 'Rail') {
      final railsNeeded = _orientation == 'Portrait' ? 2 : 3;
      final attachmentsPerRail = (attachmentsPerPanel / railsNeeded).ceil();
      layoutPattern = '$railsNeeded rails, $attachmentsPerRail attachments each';
    } else {
      // Rail-less
      layoutPattern = '$attachmentsPerPanel direct attachments in grid pattern';
    }

    String recommendation;
    if (recommendedSpacing <= rafterSpacing) {
      recommendation = 'Attach at every rafter (${rafterSpacing.toStringAsFixed(0)}" spacing).';
    } else if (recommendedSpacing <= rafterSpacing * 2) {
      recommendation = 'Can skip rafters. Attach at ${recommendedSpacing.toStringAsFixed(0)}" spacing.';
    } else {
      recommendation = 'High wind zone. Consider additional attachments for safety.';
    }

    setState(() {
      _attachmentsPerPanel = attachmentsPerPanel;
      _maxSpacing = maxSpacing;
      _recommendedSpacing = recommendedSpacing;
      _layoutPattern = layoutPattern;
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
    _rafterSpacingController.text = '24';
    _panelWidthController.text = '41';
    _panelLengthController.text = '77';
    _windUpliftController.text = '45';
    _attachmentRatingController.text = '500';
    setState(() {
      _orientation = 'Portrait';
      _mountType = 'Rail';
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
        title: Text('Attachment Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rafter Spacing',
                      unit: 'in',
                      hint: '16 or 24',
                      controller: _rafterSpacingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wind Uplift',
                      unit: 'psf',
                      hint: 'Design load',
                      controller: _windUpliftController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PANEL'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Width',
                      unit: 'in',
                      hint: '~41"',
                      controller: _panelWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Length',
                      unit: 'in',
                      hint: '~77"',
                      controller: _panelLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOrientationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MOUNTING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMountTypeSelector(colors)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Attachment Rating',
                      unit: 'lbs',
                      hint: 'Uplift capacity',
                      controller: _attachmentRatingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_attachmentsPerPanel != null) ...[
                _buildSectionHeader(colors, 'ATTACHMENT LAYOUT'),
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
              Icon(LucideIcons.grid, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Attachment Spacing',
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
            'Calculate roof attachment spacing and quantity',
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

  Widget _buildOrientationSelector(ZaftoColors colors) {
    final options = ['Portrait', 'Landscape'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _orientation == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _orientation = opt);
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
                    opt,
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

  Widget _buildMountTypeSelector(ZaftoColors colors) {
    final options = ['Rail', 'Rail-less'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _mountType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              HapticFeedback.selectionClick();
              setState(() => _mountType = v);
              _calculate();
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
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Attachments/Panel', '$_attachmentsPerPanel', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Recommended Spacing', '${_recommendedSpacing!.toStringAsFixed(0)}"', colors.accentSuccess),
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
              children: [
                _buildResultRow(colors, 'Max Allowable Spacing', '${_maxSpacing!.toStringAsFixed(1)}"'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Layout', _layoutPattern!),
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
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
