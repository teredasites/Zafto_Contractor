import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stud Calculator - Calculate studs per wall
class StudCalculatorScreen extends ConsumerStatefulWidget {
  const StudCalculatorScreen({super.key});
  @override
  ConsumerState<StudCalculatorScreen> createState() => _StudCalculatorScreenState();
}

class _StudCalculatorScreenState extends ConsumerState<StudCalculatorScreen> {
  final _wallLengthController = TextEditingController(text: '20');
  final _openingsController = TextEditingController(text: '2');

  String _spacing = '16';

  int? _standardStuds;
  int? _cornersExtras;
  int? _openingStuds;
  int? _totalStuds;

  @override
  void dispose() {
    _wallLengthController.dispose();
    _openingsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final wallLength = double.tryParse(_wallLengthController.text);
    final openings = int.tryParse(_openingsController.text) ?? 0;
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (wallLength == null) {
      setState(() {
        _standardStuds = null;
        _cornersExtras = null;
        _openingStuds = null;
        _totalStuds = null;
      });
      return;
    }

    // Standard studs: (wall length in inches / spacing) + 1
    final wallInches = wallLength * 12;
    final standardStuds = (wallInches / spacingInches).floor() + 1;

    // Corner studs: 2 for each end (1 corner + 1 backer)
    const cornersExtras = 4;

    // Opening studs: 2 king + 2 jack per opening
    final openingStuds = openings * 4;

    final totalStuds = standardStuds + cornersExtras + openingStuds;

    setState(() {
      _standardStuds = standardStuds;
      _cornersExtras = cornersExtras;
      _openingStuds = openingStuds;
      _totalStuds = totalStuds;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wallLengthController.text = '20';
    _openingsController.text = '2';
    setState(() => _spacing = '16');
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
        title: Text('Stud Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'STUD SPACING'),
              const SizedBox(height: 12),
              _buildSpacingSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WALL DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wall Length',
                      unit: 'ft',
                      hint: 'Total length',
                      controller: _wallLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Openings',
                      unit: 'qty',
                      hint: 'Doors/windows',
                      controller: _openingsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalStuds != null) ...[
                _buildSectionHeader(colors, 'STUD COUNT'),
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
              Icon(LucideIcons.alignVerticalSpaceAround, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Stud Calculator',
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
            'Calculate wall studs including corners and openings',
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

  Widget _buildSpacingSelector(ZaftoColors colors) {
    final spacings = ['12', '16', '24'];
    return Row(
      children: spacings.map((s) {
        final isSelected = _spacing == s;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _spacing = s);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: s != spacings.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                '$s" OC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
          _buildResultRow(colors, 'Standard Studs', '$_standardStuds'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Corner/Extras', '$_cornersExtras'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Opening Studs', '$_openingStuds'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL STUDS', '$_totalStuds', isHighlighted: true),
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
                    Text('Framing Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('16" OC standard for load-bearing walls', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('24" OC allowed for non-bearing in some codes', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Add 10% waste factor for cuts', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
