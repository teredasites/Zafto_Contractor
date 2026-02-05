import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// EPDM Membrane Calculator - Calculate single-ply membrane materials
class EpdmMembraneScreen extends ConsumerStatefulWidget {
  const EpdmMembraneScreen({super.key});
  @override
  ConsumerState<EpdmMembraneScreen> createState() => _EpdmMembraneScreenState();
}

class _EpdmMembraneScreenState extends ConsumerState<EpdmMembraneScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '40');
  final _parapetHeightController = TextEditingController(text: '12');

  String _thickness = '60 mil';
  String _attachment = 'Fully Adhered';

  double? _fieldArea;
  double? _flashingArea;
  double? _totalArea;
  double? _adhesiveGallons;
  double? _seamTapeLength;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _parapetHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final parapetHeight = double.tryParse(_parapetHeightController.text);

    if (length == null || width == null || parapetHeight == null) {
      setState(() {
        _fieldArea = null;
        _flashingArea = null;
        _totalArea = null;
        _adhesiveGallons = null;
        _seamTapeLength = null;
      });
      return;
    }

    // Field area
    final fieldArea = length * width;

    // Parapet/flashing area (perimeter × height in feet)
    final perimeter = 2 * (length + width);
    final flashingArea = perimeter * (parapetHeight / 12);

    // Total area with 10% waste
    final totalArea = (fieldArea + flashingArea) * 1.1;

    // Adhesive: varies by attachment method
    double adhesiveGallons = 0;
    if (_attachment == 'Fully Adhered') {
      // Bonding adhesive: ~100 sq ft/gal
      adhesiveGallons = totalArea / 100;
    }

    // Seam tape: length of seams
    // Assume 10' wide rolls, so seams = length of roof × (width / 10)
    final seamTapeLength = length * (width / 10).ceil();

    setState(() {
      _fieldArea = fieldArea;
      _flashingArea = flashingArea;
      _totalArea = totalArea;
      _adhesiveGallons = adhesiveGallons;
      _seamTapeLength = seamTapeLength;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.text = '50';
    _widthController.text = '40';
    _parapetHeightController.text = '12';
    setState(() {
      _thickness = '60 mil';
      _attachment = 'Fully Adhered';
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
        title: Text('EPDM Membrane', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MEMBRANE SPECS'),
              const SizedBox(height: 12),
              _buildThicknessSelector(colors),
              const SizedBox(height: 12),
              _buildAttachmentSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Roof length',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Roof width',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Parapet Height',
                unit: 'in',
                hint: 'Wall flashing',
                controller: _parapetHeightController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalArea != null) ...[
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'EPDM Membrane Calculator',
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
            'Calculate single-ply rubber roofing materials',
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

  Widget _buildThicknessSelector(ZaftoColors colors) {
    final thicknesses = ['45 mil', '60 mil', '90 mil'];
    return Row(
      children: thicknesses.map((thick) {
        final isSelected = _thickness == thick;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _thickness = thick);
            },
            child: Container(
              margin: EdgeInsets.only(right: thick != thicknesses.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                thick,
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

  Widget _buildAttachmentSelector(ZaftoColors colors) {
    final attachments = ['Fully Adhered', 'Mechanically Attached', 'Ballasted'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        final isSelected = _attachment == attachment;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _attachment = attachment);
            _calculate();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              attachment,
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
          _buildResultRow(colors, 'Field Area', '${_fieldArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Flashing Area', '${_flashingArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL MEMBRANE', '${_totalArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 12),
          if (_adhesiveGallons! > 0)
            _buildResultRow(colors, 'Bonding Adhesive', '${_adhesiveGallons!.toStringAsFixed(0)} gal'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Seam Tape', '${_seamTapeLength!.toStringAsFixed(0)} lin ft'),
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
                    Text('EPDM Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('45 mil: 10-15 year warranty', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('60 mil: 15-20 year warranty (most common)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('90 mil: 20-25+ year warranty', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
