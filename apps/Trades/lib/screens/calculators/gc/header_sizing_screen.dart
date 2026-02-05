import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Header Sizing - Calculate header size by span and load
class HeaderSizingScreen extends ConsumerStatefulWidget {
  const HeaderSizingScreen({super.key});
  @override
  ConsumerState<HeaderSizingScreen> createState() => _HeaderSizingScreenState();
}

class _HeaderSizingScreenState extends ConsumerState<HeaderSizingScreen> {
  final _spanController = TextEditingController(text: '4');

  String _loadType = 'Non-Bearing';
  String _stories = '1';

  String? _headerSize;
  String? _headerType;
  String? _jackStuds;

  @override
  void dispose() {
    _spanController.dispose();
    super.dispose();
  }

  void _calculate() {
    final span = double.tryParse(_spanController.text);

    if (span == null) {
      setState(() {
        _headerSize = null;
        _headerType = null;
        _jackStuds = null;
      });
      return;
    }

    String headerSize;
    String headerType;
    int jackStuds;

    // Simplified header sizing based on IRC tables
    if (_loadType == 'Non-Bearing') {
      // Non-bearing: flat 2x4 or 2x6 is often sufficient
      if (span <= 4) {
        headerSize = '2x4 flat';
        headerType = 'Single 2x4';
      } else if (span <= 6) {
        headerSize = '2x6 flat';
        headerType = 'Single 2x6';
      } else {
        headerSize = '(2) 2x6';
        headerType = 'Double 2x6';
      }
      jackStuds = 1;
    } else {
      // Load-bearing
      final stories = int.tryParse(_stories) ?? 1;

      if (stories == 1) {
        if (span <= 4) {
          headerSize = '(2) 2x6';
          headerType = 'Double 2x6';
          jackStuds = 1;
        } else if (span <= 6) {
          headerSize = '(2) 2x8';
          headerType = 'Double 2x8';
          jackStuds = 2;
        } else if (span <= 8) {
          headerSize = '(2) 2x10';
          headerType = 'Double 2x10';
          jackStuds = 2;
        } else {
          headerSize = '(2) 2x12 or LVL';
          headerType = 'Double 2x12 / LVL';
          jackStuds = 2;
        }
      } else {
        // 2+ stories
        if (span <= 4) {
          headerSize = '(2) 2x8';
          headerType = 'Double 2x8';
          jackStuds = 2;
        } else if (span <= 6) {
          headerSize = '(2) 2x10';
          headerType = 'Double 2x10';
          jackStuds = 2;
        } else if (span <= 8) {
          headerSize = '(2) 2x12';
          headerType = 'Double 2x12';
          jackStuds = 3;
        } else {
          headerSize = 'LVL / Glulam';
          headerType = 'Engineered Lumber Required';
          jackStuds = 3;
        }
      }
    }

    setState(() {
      _headerSize = headerSize;
      _headerType = headerType;
      _jackStuds = '$jackStuds per side';
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _spanController.text = '4';
    setState(() {
      _loadType = 'Non-Bearing';
      _stories = '1';
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
        title: Text('Header Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'LOAD TYPE'),
              const SizedBox(height: 12),
              _buildLoadTypeSelector(colors),
              if (_loadType == 'Load-Bearing') ...[
                const SizedBox(height: 12),
                _buildStoriesSelector(colors),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OPENING SPAN'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Span',
                unit: 'ft',
                hint: 'Opening width',
                controller: _spanController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_headerSize != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED HEADER'),
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
              Icon(LucideIcons.doorOpen, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Header Sizing Calculator',
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
            'Size headers by span and load requirements',
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

  Widget _buildLoadTypeSelector(ZaftoColors colors) {
    final types = ['Non-Bearing', 'Load-Bearing'];
    return Row(
      children: types.map((type) {
        final isSelected = _loadType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _loadType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                  color: isSelected ? Colors.white : colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStoriesSelector(ZaftoColors colors) {
    final stories = ['1', '2', '3+'];
    return Row(
      children: stories.map((s) {
        final isSelected = _stories == s;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _stories = s);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: s != stories.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                '$s Story',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
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
          _buildResultRow(colors, 'HEADER SIZE', _headerSize!, isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Header Type', _headerType!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Jack Studs', _jackStuds!),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                    const SizedBox(width: 8),
                    Text('Engineering Note', style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('These are general guidelines per IRC', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Verify with local codes and engineer', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Point loads require engineering', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
