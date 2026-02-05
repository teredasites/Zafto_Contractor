import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Counter Flashing Calculator - Calculate counter flashing for masonry walls
class CounterFlashingScreen extends ConsumerStatefulWidget {
  const CounterFlashingScreen({super.key});
  @override
  ConsumerState<CounterFlashingScreen> createState() => _CounterFlashingScreenState();
}

class _CounterFlashingScreenState extends ConsumerState<CounterFlashingScreen> {
  final _lengthController = TextEditingController(text: '25');
  final _heightController = TextEditingController(text: '4');
  final _regletController = TextEditingController(text: '1');

  String _material = 'Aluminum';

  double? _flashingArea;
  double? _linearFeet;
  double? _sealantTubes;

  @override
  void dispose() {
    _lengthController.dispose();
    _heightController.dispose();
    _regletController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final height = double.tryParse(_heightController.text);
    final reglet = double.tryParse(_regletController.text);

    if (length == null || height == null || reglet == null) {
      setState(() {
        _flashingArea = null;
        _linearFeet = null;
        _sealantTubes = null;
      });
      return;
    }

    // Counter flashing dimensions
    // Height includes reglet depth + exposed face
    final totalHeight = height + reglet;
    final flashingArea = length * (totalHeight / 12); // convert to sq ft

    // Linear feet with 10% overlap waste
    final linearFeet = length * 1.1;

    // Sealant: ~20 lin ft per tube for reglet
    final sealantTubes = length / 20;

    setState(() {
      _flashingArea = flashingArea;
      _linearFeet = linearFeet;
      _sealantTubes = sealantTubes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.text = '25';
    _heightController.text = '4';
    _regletController.text = '1';
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
        title: Text('Counter Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DIMENSIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Length',
                unit: 'ft',
                hint: 'Wall length',
                controller: _lengthController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Height',
                      unit: 'in',
                      hint: 'Exposed face',
                      controller: _heightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Reglet',
                      unit: 'in',
                      hint: 'Insert depth',
                      controller: _regletController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_flashingArea != null) ...[
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
                'Counter Flashing Calculator',
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
            'Calculate reglet counter flashing materials',
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
    final materials = ['Aluminum', 'Galvanized', 'Copper', 'Lead-Coated'];
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
          _buildResultRow(colors, 'LINEAR FEET', '${_linearFeet!.toStringAsFixed(0)} ft', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Flashing Area', '${_flashingArea!.toStringAsFixed(1)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Sealant Tubes', '${_sealantTubes!.toStringAsFixed(1)}'),
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
                    Text('Counter Flashing Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Reglet cut: 3/4" deep into mortar joint', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Overlap sections by 4" minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Seal reglet with polyurethane sealant', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
