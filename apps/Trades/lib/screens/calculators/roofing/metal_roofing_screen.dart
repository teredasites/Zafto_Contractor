import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Metal Roofing Calculator - Estimate metal panels and accessories
class MetalRoofingScreen extends ConsumerStatefulWidget {
  const MetalRoofingScreen({super.key});
  @override
  ConsumerState<MetalRoofingScreen> createState() => _MetalRoofingScreenState();
}

class _MetalRoofingScreenState extends ConsumerState<MetalRoofingScreen> {
  final _areaController = TextEditingController(text: '2400');
  final _panelWidthController = TextEditingController(text: '36');
  final _wasteController = TextEditingController(text: '5');

  String _panelType = 'Standing Seam';

  double? _squares;
  int? _panelsNeeded;
  double? _totalPanelArea;
  int? _screwsNeeded;
  double? _trimLength;

  @override
  void dispose() {
    _areaController.dispose();
    _panelWidthController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final panelWidth = double.tryParse(_panelWidthController.text);
    final waste = double.tryParse(_wasteController.text);

    if (area == null || panelWidth == null || waste == null) {
      setState(() {
        _squares = null;
        _panelsNeeded = null;
        _totalPanelArea = null;
        _screwsNeeded = null;
        _trimLength = null;
      });
      return;
    }

    final squares = area / 100;
    final areaWithWaste = area * (1 + waste / 100);

    // Panel coverage width in feet
    final panelCoverage = panelWidth / 12;

    // Screws per square based on panel type
    int screwsPerSquare;
    switch (_panelType) {
      case 'Standing Seam':
        screwsPerSquare = 75; // Hidden fasteners + clips
        break;
      case 'Corrugated':
        screwsPerSquare = 100; // Exposed fasteners
        break;
      case 'R-Panel':
        screwsPerSquare = 90;
        break;
      default:
        screwsPerSquare = 90;
    }

    // Estimate panel count based on typical 3ft × variable length panels
    // Assume average panel length of 12 ft
    final avgPanelLength = 12.0;
    final panelArea = panelCoverage * avgPanelLength;
    final panelsNeeded = (areaWithWaste / panelArea).ceil();

    final totalPanelArea = panelsNeeded * panelArea;
    final screwsNeeded = (squares * screwsPerSquare * (1 + waste / 100)).ceil();

    // Trim estimate (eave, rake, ridge)
    final trimLength = area / 100 * 50; // ~50 lin ft per square for all trims

    setState(() {
      _squares = squares;
      _panelsNeeded = panelsNeeded;
      _totalPanelArea = totalPanelArea;
      _screwsNeeded = screwsNeeded;
      _trimLength = trimLength;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _areaController.text = '2400';
    _panelWidthController.text = '36';
    _wasteController.text = '5';
    setState(() => _panelType = 'Standing Seam');
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
        title: Text('Metal Roofing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF SPECIFICATIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Area',
                unit: 'sq ft',
                hint: 'Total area',
                controller: _areaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Width',
                      unit: 'in',
                      hint: 'Coverage width',
                      controller: _panelWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Waste',
                      unit: '%',
                      hint: '5-10%',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_panelsNeeded != null) ...[
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
              Icon(LucideIcons.layoutList, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Metal Roofing Calculator',
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
            'Estimate metal panels, screws, and trim',
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
    final types = ['Standing Seam', 'Corrugated', 'R-Panel'];
    return Row(
      children: types.map((type) {
        final isSelected = _panelType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _panelType = type);
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
          _buildResultRow(colors, 'Roofing Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'PANELS NEEDED', '$_panelsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Panel Coverage', '${_totalPanelArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Screws/Fasteners', '$_screwsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Trim (All Types)', '${_trimLength!.toStringAsFixed(0)} lin ft'),
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
                    Text('Panel Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Standing Seam: Hidden clips, premium look', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Corrugated: Exposed screws, economical', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('R-Panel: Commercial grade, ribbed profile', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
