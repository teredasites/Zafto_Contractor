import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cripple Stud Calculator - Calculate cripples above/below openings
class CrippleStudScreen extends ConsumerStatefulWidget {
  const CrippleStudScreen({super.key});
  @override
  ConsumerState<CrippleStudScreen> createState() => _CrippleStudScreenState();
}

class _CrippleStudScreenState extends ConsumerState<CrippleStudScreen> {
  final _windowsController = TextEditingController(text: '4');
  final _windowWidthController = TextEditingController(text: '3');

  String _spacing = '16';

  int? _cripplesAbove;
  int? _cripplesBelow;
  int? _totalCripples;

  @override
  void dispose() {
    _windowsController.dispose();
    _windowWidthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final windowWidth = double.tryParse(_windowWidthController.text) ?? 0;
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (windows == 0 || windowWidth == 0) {
      setState(() {
        _cripplesAbove = null;
        _cripplesBelow = null;
        _totalCripples = null;
      });
      return;
    }

    // Cripples per opening: (opening width in inches / spacing) - 1
    // Above header and below sill
    final widthInches = windowWidth * 12;
    final cripplesPerOpening = ((widthInches / spacingInches).floor() - 1).clamp(0, 100);

    // Above header (all windows have cripples above)
    final cripplesAbove = cripplesPerOpening * windows;

    // Below sill (windows only, not doors)
    final cripplesBelow = cripplesPerOpening * windows;

    final totalCripples = cripplesAbove + cripplesBelow;

    setState(() {
      _cripplesAbove = cripplesAbove;
      _cripplesBelow = cripplesBelow;
      _totalCripples = totalCripples;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _windowsController.text = '4';
    _windowWidthController.text = '3';
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
        title: Text('Cripple Studs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'WINDOW OPENINGS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Windows',
                      unit: 'qty',
                      hint: 'Count',
                      controller: _windowsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Avg Width',
                      unit: 'ft',
                      hint: 'Per window',
                      controller: _windowWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalCripples != null) ...[
                _buildSectionHeader(colors, 'CRIPPLE STUD COUNT'),
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
                'Cripple Stud Calculator',
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
            'Calculate cripples above headers and below sills',
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
          _buildResultRow(colors, 'Cripples Above Headers', '$_cripplesAbove'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Cripples Below Sills', '$_cripplesBelow'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL CRIPPLES', '$_totalCripples', isHighlighted: true),
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
                    Text('Cripple Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Cripples maintain stud layout continuity', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Doors have no cripples below (no sill)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Cut from stud lengths for efficiency', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
