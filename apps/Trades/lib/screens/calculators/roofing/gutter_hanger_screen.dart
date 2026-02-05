import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gutter Hanger Calculator - Calculate gutter hanger/bracket requirements
class GutterHangerScreen extends ConsumerStatefulWidget {
  const GutterHangerScreen({super.key});
  @override
  ConsumerState<GutterHangerScreen> createState() => _GutterHangerScreenState();
}

class _GutterHangerScreenState extends ConsumerState<GutterHangerScreen> {
  final _gutterLengthController = TextEditingController(text: '120');
  final _spacingController = TextEditingController(text: '24');

  String _hangerType = 'Hidden';
  String _climate = 'Standard';

  int? _hangersNeeded;
  int? _screwsNeeded;
  double? _actualSpacing;

  @override
  void dispose() {
    _gutterLengthController.dispose();
    _spacingController.dispose();
    super.dispose();
  }

  void _calculate() {
    final gutterLength = double.tryParse(_gutterLengthController.text);
    var spacing = double.tryParse(_spacingController.text);

    if (gutterLength == null || spacing == null) {
      setState(() {
        _hangersNeeded = null;
        _screwsNeeded = null;
        _actualSpacing = null;
      });
      return;
    }

    // Adjust spacing for climate
    if (_climate == 'Snow/Ice') {
      // Tighter spacing for snow areas
      if (spacing > 18) spacing = 18;
    }

    // Convert feet to inches
    final lengthInches = gutterLength * 12;

    // Hangers needed = (length / spacing) + 1 for end
    final hangersNeeded = (lengthInches / spacing).ceil() + 1;

    // Screws per hanger
    int screwsPerHanger;
    switch (_hangerType) {
      case 'Hidden':
        screwsPerHanger = 1; // One long screw through gutter
        break;
      case 'Spike/Ferrule':
        screwsPerHanger = 1; // One spike
        break;
      case 'Strap':
        screwsPerHanger = 3; // Screws into roof deck
        break;
      case 'Fascia Bracket':
        screwsPerHanger = 2;
        break;
      default:
        screwsPerHanger = 1;
    }

    final screwsNeeded = (hangersNeeded * screwsPerHanger * 1.1).ceil(); // 10% extra

    // Calculate actual spacing
    final actualSpacing = lengthInches / (hangersNeeded - 1);

    setState(() {
      _hangersNeeded = hangersNeeded;
      _screwsNeeded = screwsNeeded;
      _actualSpacing = actualSpacing;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gutterLengthController.text = '120';
    _spacingController.text = '24';
    setState(() {
      _hangerType = 'Hidden';
      _climate = 'Standard';
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
        title: Text('Gutter Hanger', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'HANGER TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'GUTTER RUN'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Total Length',
                      unit: 'ft',
                      hint: 'All gutters',
                      controller: _gutterLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Spacing',
                      unit: 'in',
                      hint: '24" typical',
                      controller: _spacingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_hangersNeeded != null) ...[
                _buildSectionHeader(colors, 'HARDWARE NEEDED'),
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
              Icon(LucideIcons.link, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gutter Hanger Calculator',
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
            'Calculate gutter hangers and fasteners',
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
    final types = ['Hidden', 'Spike/Ferrule', 'Strap', 'Fascia Bracket'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _hangerType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _hangerType = type);
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
              type,
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

  Widget _buildClimateSelector(ZaftoColors colors) {
    final climates = ['Standard', 'Snow/Ice'];
    return Row(
      children: climates.map((climate) {
        final isSelected = _climate == climate;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _climate = climate);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: climate != climates.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    climate,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    climate == 'Standard' ? '24" spacing OK' : '18" max spacing',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
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
          _buildResultRow(colors, 'HANGERS NEEDED', '$_hangersNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Screws/Fasteners', '$_screwsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Actual Spacing', '${_actualSpacing!.toStringAsFixed(1)}"'),
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
                    Text('Hanger Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Hidden hangers: Best for seamless', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Snow areas: 18" max, 12" preferred', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Always use stainless steel fasteners', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
