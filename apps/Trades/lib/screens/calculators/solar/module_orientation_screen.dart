import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Module Orientation Calculator - Portrait vs Landscape comparison
class ModuleOrientationScreen extends ConsumerStatefulWidget {
  const ModuleOrientationScreen({super.key});
  @override
  ConsumerState<ModuleOrientationScreen> createState() => _ModuleOrientationScreenState();
}

class _ModuleOrientationScreenState extends ConsumerState<ModuleOrientationScreen> {
  final _panelLengthController = TextEditingController(text: '6.8');
  final _panelWidthController = TextEditingController(text: '3.4');
  final _roofLengthController = TextEditingController(text: '40');
  final _roofWidthController = TextEditingController(text: '24');
  final _panelWattsController = TextEditingController(text: '400');

  int? _portraitCount;
  int? _landscapeCount;
  double? _portraitKw;
  double? _landscapeKw;
  String? _recommendation;

  @override
  void dispose() {
    _panelLengthController.dispose();
    _panelWidthController.dispose();
    _roofLengthController.dispose();
    _roofWidthController.dispose();
    _panelWattsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final panelLength = double.tryParse(_panelLengthController.text);
    final panelWidth = double.tryParse(_panelWidthController.text);
    final roofLength = double.tryParse(_roofLengthController.text);
    final roofWidth = double.tryParse(_roofWidthController.text);
    final panelWatts = double.tryParse(_panelWattsController.text);

    if (panelLength == null || panelWidth == null || roofLength == null || roofWidth == null || panelWatts == null) {
      setState(() {
        _portraitCount = null;
        _landscapeCount = null;
        _portraitKw = null;
        _landscapeKw = null;
        _recommendation = null;
      });
      return;
    }

    // Portrait orientation: length vertical, width horizontal
    // Rows along roof width, columns along roof length
    final portraitRowsAcross = (roofLength / panelWidth).floor();
    final portraitColumnsUp = (roofWidth / panelLength).floor();
    final portraitCount = portraitRowsAcross * portraitColumnsUp;

    // Landscape orientation: width vertical, length horizontal
    final landscapeRowsAcross = (roofLength / panelLength).floor();
    final landscapeColumnsUp = (roofWidth / panelWidth).floor();
    final landscapeCount = landscapeRowsAcross * landscapeColumnsUp;

    final portraitKw = (portraitCount * panelWatts) / 1000;
    final landscapeKw = (landscapeCount * panelWatts) / 1000;

    String recommendation;
    if (portraitCount > landscapeCount) {
      final diff = portraitCount - landscapeCount;
      recommendation = 'Portrait fits $diff more panels (+${((diff / landscapeCount) * 100).toStringAsFixed(0)}% capacity)';
    } else if (landscapeCount > portraitCount) {
      final diff = landscapeCount - portraitCount;
      recommendation = 'Landscape fits $diff more panels (+${((diff / portraitCount) * 100).toStringAsFixed(0)}% capacity)';
    } else {
      recommendation = 'Both orientations fit equal panels';
    }

    setState(() {
      _portraitCount = portraitCount;
      _landscapeCount = landscapeCount;
      _portraitKw = portraitKw;
      _landscapeKw = landscapeKw;
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
    _panelLengthController.text = '6.8';
    _panelWidthController.text = '3.4';
    _roofLengthController.text = '40';
    _roofWidthController.text = '24';
    _panelWattsController.text = '400';
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
        title: Text('Module Orientation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Length',
                      unit: 'ft',
                      hint: 'Long side',
                      controller: _panelLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Width',
                      unit: 'ft',
                      hint: 'Short side',
                      controller: _panelWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Panel Wattage',
                unit: 'W',
                hint: 'Per module',
                controller: _panelWattsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Length',
                      unit: 'ft',
                      hint: 'E-W dimension',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Width',
                      unit: 'ft',
                      hint: 'N-S dimension',
                      controller: _roofWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_portraitCount != null) ...[
                _buildSectionHeader(colors, 'ORIENTATION COMPARISON'),
                const SizedBox(height: 12),
                _buildComparisonCard(colors),
                const SizedBox(height: 16),
                _buildConsiderations(colors),
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
              Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Portrait vs Landscape',
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
            'Compare module counts for different mounting orientations',
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

  Widget _buildComparisonCard(ZaftoColors colors) {
    final portraitBetter = _portraitCount! > _landscapeCount!;
    final landscapeBetter = _landscapeCount! > _portraitCount!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildOrientationTile(
                  colors,
                  'Portrait',
                  '$_portraitCount panels',
                  '${_portraitKw!.toStringAsFixed(2)} kW',
                  LucideIcons.smartphone,
                  portraitBetter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrientationTile(
                  colors,
                  'Landscape',
                  '$_landscapeCount panels',
                  '${_landscapeKw!.toStringAsFixed(2)} kW',
                  LucideIcons.monitor,
                  landscapeBetter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 18, color: colors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(color: colors.accentSuccess, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientationTile(ZaftoColors colors, String title, String count, String kw, IconData icon, bool isBetter) {
    final accentColor = isBetter ? colors.accentPrimary : colors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBetter ? accentColor.withValues(alpha: 0.1) : colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
        border: isBetter ? Border.all(color: accentColor.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
              if (isBetter) ...[
                const SizedBox(width: 4),
                Icon(LucideIcons.crown, size: 12, color: colors.accentWarning),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(kw, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildConsiderations(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OTHER CONSIDERATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildConsiderationRow(colors, 'Rail Length', 'Landscape often uses less rail'),
          _buildConsiderationRow(colors, 'Wind Load', 'Portrait may see higher uplift'),
          _buildConsiderationRow(colors, 'Racking', 'Check manufacturer specs'),
          _buildConsiderationRow(colors, 'Clamps', 'Mid-clamp count varies'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This shows theoretical max panels. Account for setbacks, vents, obstructions, and fire access pathways.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsiderationRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.chevronRight, size: 12, color: colors.accentPrimary),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
