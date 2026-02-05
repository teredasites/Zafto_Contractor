import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// King/Jack Stud Calculator - Calculate studs per opening
class KingJackStudScreen extends ConsumerStatefulWidget {
  const KingJackStudScreen({super.key});
  @override
  ConsumerState<KingJackStudScreen> createState() => _KingJackStudScreenState();
}

class _KingJackStudScreenState extends ConsumerState<KingJackStudScreen> {
  final _doorsController = TextEditingController(text: '3');
  final _windowsController = TextEditingController(text: '6');
  final _wideOpeningsController = TextEditingController(text: '1');

  int? _kingStuds;
  int? _jackStuds;
  int? _totalStuds;

  @override
  void dispose() {
    _doorsController.dispose();
    _windowsController.dispose();
    _wideOpeningsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final wideOpenings = int.tryParse(_wideOpeningsController.text) ?? 0;

    // Standard openings: 2 king + 2 jack
    final standardOpenings = doors + windows;

    // Wide openings (>6'): 2 king + 4 jack (2 per side)
    final kingStuds = (standardOpenings * 2) + (wideOpenings * 2);
    final jackStuds = (standardOpenings * 2) + (wideOpenings * 4);
    final totalStuds = kingStuds + jackStuds;

    setState(() {
      _kingStuds = kingStuds;
      _jackStuds = jackStuds;
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
    _doorsController.text = '3';
    _windowsController.text = '6';
    _wideOpeningsController.text = '1';
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
        title: Text('King/Jack Studs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'OPENING COUNT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Doors',
                      unit: 'qty',
                      hint: 'Standard doors',
                      controller: _doorsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Windows',
                      unit: 'qty',
                      hint: 'Standard windows',
                      controller: _windowsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Wide Openings',
                unit: 'qty',
                hint: 'Over 6 feet wide',
                controller: _wideOpeningsController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalStuds != null) ...[
                _buildSectionHeader(colors, 'STUD REQUIREMENTS'),
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
                'King/Jack Stud Calculator',
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
            'Calculate king and jack studs for all openings',
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
          _buildResultRow(colors, 'King Studs', '$_kingStuds'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Jack Studs', '$_jackStuds'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL OPENING STUDS', '$_totalStuds', isHighlighted: true),
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
                    Text('Framing Terms', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('King Studs: Full-height studs beside openings', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Jack Studs: Short studs supporting header', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Wide openings may need multiple jacks', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
