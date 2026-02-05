import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fascia Board Calculator - Calculate fascia and soffit materials
class FasciaBoardScreen extends ConsumerStatefulWidget {
  const FasciaBoardScreen({super.key});
  @override
  ConsumerState<FasciaBoardScreen> createState() => _FasciaBoardScreenState();
}

class _FasciaBoardScreenState extends ConsumerState<FasciaBoardScreen> {
  final _linearFeetController = TextEditingController(text: '150');
  final _wasteController = TextEditingController(text: '10');

  String _material = 'Wood';
  String _width = '1×6';

  double? _totalLength;
  int? _boardsNeeded;
  int? _nailsNeeded;
  double? _paintArea;

  @override
  void dispose() {
    _linearFeetController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final linearFeet = double.tryParse(_linearFeetController.text);
    final waste = double.tryParse(_wasteController.text);

    if (linearFeet == null || waste == null) {
      setState(() {
        _totalLength = null;
        _boardsNeeded = null;
        _nailsNeeded = null;
        _paintArea = null;
      });
      return;
    }

    final totalLength = linearFeet * (1 + waste / 100);

    // Board length depends on material
    double boardLength;
    switch (_material) {
      case 'Wood':
        boardLength = 16; // 16 ft boards
        break;
      case 'Composite':
        boardLength = 12; // 12 ft boards typical
        break;
      case 'Aluminum':
        boardLength = 12;
        break;
      case 'Vinyl':
        boardLength = 12;
        break;
      default:
        boardLength = 16;
    }

    final boardsNeeded = (totalLength / boardLength).ceil();

    // Nails: 2 per foot for wood
    int nailsNeeded = 0;
    if (_material == 'Wood') {
      nailsNeeded = (totalLength * 2).ceil();
    }

    // Paint area (width in inches to feet)
    double widthFeet;
    switch (_width) {
      case '1×4':
        widthFeet = 3.5 / 12;
        break;
      case '1×6':
        widthFeet = 5.5 / 12;
        break;
      case '1×8':
        widthFeet = 7.25 / 12;
        break;
      default:
        widthFeet = 5.5 / 12;
    }
    final paintArea = totalLength * widthFeet * 2; // Both sides

    setState(() {
      _totalLength = totalLength;
      _boardsNeeded = boardsNeeded;
      _nailsNeeded = nailsNeeded;
      _paintArea = paintArea;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _linearFeetController.text = '150';
    _wasteController.text = '10';
    setState(() {
      _material = 'Wood';
      _width = '1×6';
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
        title: Text('Fascia Board', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MATERIAL & SIZE'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildWidthSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MEASUREMENTS'),
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
                      label: 'Waste',
                      unit: '%',
                      hint: '10% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_boardsNeeded != null) ...[
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
                'Fascia Board Calculator',
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
            'Calculate fascia boards and accessories',
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
    final materials = ['Wood', 'Composite', 'Aluminum', 'Vinyl'];
    return Row(
      children: materials.map((material) {
        final isSelected = _material == material;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _material = material);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: material != materials.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                material,
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

  Widget _buildWidthSelector(ZaftoColors colors) {
    final widths = ['1×4', '1×6', '1×8'];
    return Row(
      children: widths.map((width) {
        final isSelected = _width == width;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _width = width);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: width != widths.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                width,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 14,
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
          _buildResultRow(colors, 'Total Length', '${_totalLength!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'BOARDS NEEDED', '$_boardsNeeded', isHighlighted: true),
          if (_nailsNeeded! > 0) ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Nails (8d SS)', '$_nailsNeeded'),
          ],
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Paint Area', '${_paintArea!.toStringAsFixed(0)} sq ft'),
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
                    'Use stainless steel or hot-dip galvanized fasteners to prevent rust staining.',
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
