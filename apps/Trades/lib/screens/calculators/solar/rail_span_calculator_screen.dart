import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rail Span Calculator - Mounting rail span analysis
class RailSpanCalculatorScreen extends ConsumerStatefulWidget {
  const RailSpanCalculatorScreen({super.key});
  @override
  ConsumerState<RailSpanCalculatorScreen> createState() => _RailSpanCalculatorScreenState();
}

class _RailSpanCalculatorScreenState extends ConsumerState<RailSpanCalculatorScreen> {
  final _windLoadController = TextEditingController(text: '45');
  final _snowLoadController = TextEditingController(text: '25');
  final _panelWeightController = TextEditingController(text: '45');
  final _panelWidthController = TextEditingController(text: '41');

  String _railType = 'Standard Aluminum';
  String _orientation = 'Portrait';

  double? _maxSpan;
  double? _recommendedSpan;
  double? _cantileverMax;
  double? _totalLoad;
  String? _recommendation;

  // Rail capacities (lb-in moment capacity)
  final Map<String, Map<String, double>> _railData = {
    'Standard Aluminum': {'moment': 4500, 'deflectionLimit': 0.75},
    'Heavy Duty Aluminum': {'moment': 7500, 'deflectionLimit': 0.75},
    'Steel Rail': {'moment': 12000, 'deflectionLimit': 0.5},
  };

  List<String> get _railTypes => _railData.keys.toList();

  @override
  void dispose() {
    _windLoadController.dispose();
    _snowLoadController.dispose();
    _panelWeightController.dispose();
    _panelWidthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windLoad = double.tryParse(_windLoadController.text);
    final snowLoad = double.tryParse(_snowLoadController.text);
    final panelWeight = double.tryParse(_panelWeightController.text);
    final panelWidth = double.tryParse(_panelWidthController.text);

    if (windLoad == null || snowLoad == null || panelWeight == null || panelWidth == null) {
      setState(() {
        _maxSpan = null;
        _recommendedSpan = null;
        _cantileverMax = null;
        _totalLoad = null;
        _recommendation = null;
      });
      return;
    }

    final railInfo = _railData[_railType]!;
    final momentCapacity = railInfo['moment']!;
    final deflectionLimit = railInfo['deflectionLimit']!;

    // Panel area (assuming 77" length for standard panel)
    const panelLength = 77.0;
    final panelAreaSqFt = (panelWidth * panelLength) / 144;

    // Total load per panel (lbs)
    // Use controlling load: dead + larger of wind or snow
    final deadLoad = panelWeight;
    final liveLoad = math.max(windLoad * panelAreaSqFt, snowLoad * panelAreaSqFt);
    final totalLoad = deadLoad + liveLoad;

    // Tributary width on rail (half panel width for 2-rail system)
    final tributaryWidth = _orientation == 'Portrait' ? panelWidth / 2 : panelLength / 2;

    // Distributed load on rail (lb/in)
    final distributedLoad = totalLoad / (_orientation == 'Portrait' ? panelLength : panelWidth);

    // Max span based on moment capacity
    // For uniform load: M = wL²/8, so L = sqrt(8M/w)
    final maxSpanMoment = math.sqrt(8 * momentCapacity / distributedLoad);

    // Max span based on deflection (simplified)
    // Using L/180 deflection limit as standard
    final maxSpanDeflection = maxSpanMoment * 0.85; // Approximate deflection control

    // Controlling max span
    final maxSpan = math.min(maxSpanMoment, maxSpanDeflection);

    // Recommended span with safety factor
    final recommendedSpan = maxSpan * 0.8;

    // Max cantilever (typically 1/3 of span)
    final cantileverMax = recommendedSpan / 3;

    String recommendation;
    if (recommendedSpan > 72) {
      recommendation = 'Long spans achievable. Standard rafter spacing works well.';
    } else if (recommendedSpan > 48) {
      recommendation = 'Moderate spans. Verify attachment at every rafter.';
    } else if (recommendedSpan > 36) {
      recommendation = 'Shorter spans required. May need additional attachments.';
    } else {
      recommendation = 'High loads. Consider heavy-duty rail or more supports.';
    }

    setState(() {
      _maxSpan = maxSpan;
      _recommendedSpan = recommendedSpan;
      _cantileverMax = cantileverMax;
      _totalLoad = totalLoad;
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
    _windLoadController.text = '45';
    _snowLoadController.text = '25';
    _panelWeightController.text = '45';
    _panelWidthController.text = '41';
    setState(() {
      _railType = 'Standard Aluminum';
      _orientation = 'Portrait';
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
        title: Text('Rail Span Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'RAIL TYPE'),
              const SizedBox(height: 12),
              _buildRailSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOADS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wind Load',
                      unit: 'psf',
                      hint: 'Design wind',
                      controller: _windLoadController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Snow Load',
                      unit: 'psf',
                      hint: 'Design snow',
                      controller: _snowLoadController,
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
                      label: 'Panel Weight',
                      unit: 'lbs',
                      hint: 'Per panel',
                      controller: _panelWeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Width',
                      unit: 'in',
                      hint: '~41"',
                      controller: _panelWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOrientationSelector(colors),
              const SizedBox(height: 32),
              if (_recommendedSpan != null) ...[
                _buildSectionHeader(colors, 'SPAN ANALYSIS'),
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
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Rail Span Calculator',
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
            'Determine maximum rail span between supports',
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

  Widget _buildRailSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _railType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _railTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _railType = value);
              _calculate();
            }
          },
        ),
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
          Text('Recommended Maximum Span', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _recommendedSpan!.toStringAsFixed(0),
                style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' inches',
                  style: TextStyle(color: colors.textSecondary, fontSize: 18),
                ),
              ),
            ],
          ),
          Text(
            '(${(_recommendedSpan! / 12).toStringAsFixed(1)} ft)',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Max Span', '${_maxSpan!.toStringAsFixed(0)}"', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Max Cantilever', '${_cantileverMax!.toStringAsFixed(0)}"', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total Load/Panel', '${_totalLoad!.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Rail Type', _railType),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
