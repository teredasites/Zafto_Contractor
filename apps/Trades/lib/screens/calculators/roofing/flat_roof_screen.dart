import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flat Roof Calculator - Calculate flat/low-slope roof materials
class FlatRoofScreen extends ConsumerStatefulWidget {
  const FlatRoofScreen({super.key});
  @override
  ConsumerState<FlatRoofScreen> createState() => _FlatRoofScreenState();
}

class _FlatRoofScreenState extends ConsumerState<FlatRoofScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '40');
  final _parapetController = TextEditingController(text: '18');

  String _roofingType = 'TPO';

  double? _fieldArea;
  double? _flashingArea;
  double? _totalArea;
  double? _squares;
  int? _drains;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _parapetController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final parapet = double.tryParse(_parapetController.text);

    if (length == null || width == null || parapet == null) {
      setState(() {
        _fieldArea = null;
        _flashingArea = null;
        _totalArea = null;
        _squares = null;
        _drains = null;
      });
      return;
    }

    // Field area (main roof surface)
    final fieldArea = length * width;

    // Parapet flashing area (perimeter × height in feet)
    final perimeter = 2 * (length + width);
    final parapetFeet = parapet / 12;
    final flashingArea = perimeter * parapetFeet;

    // Total with 10% waste
    final totalArea = (fieldArea + flashingArea) * 1.1;
    final squares = totalArea / 100;

    // Drain calculation: 1 drain per 10,000 sq ft minimum, plus 1
    final drains = (fieldArea / 10000).ceil() + 1;

    setState(() {
      _fieldArea = fieldArea;
      _flashingArea = flashingArea;
      _totalArea = totalArea;
      _squares = squares;
      _drains = drains;
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
    _parapetController.text = '18';
    setState(() => _roofingType = 'TPO');
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
        title: Text('Flat Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOFING TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
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
                hint: 'Wall height above roof',
                controller: _parapetController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalArea != null) ...[
                _buildSectionHeader(colors, 'ROOF CALCULATIONS'),
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
                'Flat Roof Calculator',
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
            'Calculate low-slope/flat roof materials',
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
    final types = ['TPO', 'EPDM', 'PVC', 'BUR', 'Mod Bit'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _roofingType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _roofingType = type);
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
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 13,
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
          _buildResultRow(colors, 'TOTAL AREA', '${_totalArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'ROOF SQUARES', _squares!.toStringAsFixed(1), isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Min. Roof Drains', '$_drains'),
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
                    Text('Flat Roof Requirements', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Min slope: 1/4" per foot for drainage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Includes 10% waste factor', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Consider overflow scuppers', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
