import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// String Combiner Sizing Calculator - Parallel string configuration
class StringCombinerScreen extends ConsumerStatefulWidget {
  const StringCombinerScreen({super.key});
  @override
  ConsumerState<StringCombinerScreen> createState() => _StringCombinerScreenState();
}

class _StringCombinerScreenState extends ConsumerState<StringCombinerScreen> {
  final _moduleIscController = TextEditingController(text: '11.5');
  final _stringsController = TextEditingController(text: '4');
  final _seriesFuseController = TextEditingController(text: '20');

  double? _totalIsc;
  double? _fuseSize;
  double? _maxFuseSize;
  String? _combinerSpec;
  bool? _fuseOk;

  @override
  void dispose() {
    _moduleIscController.dispose();
    _stringsController.dispose();
    _seriesFuseController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleIsc = double.tryParse(_moduleIscController.text);
    final strings = int.tryParse(_stringsController.text);
    final seriesFuse = double.tryParse(_seriesFuseController.text);

    if (moduleIsc == null || strings == null || seriesFuse == null) {
      setState(() {
        _totalIsc = null;
        _fuseSize = null;
        _maxFuseSize = null;
        _combinerSpec = null;
        _fuseOk = null;
      });
      return;
    }

    // Total short circuit current (all strings in parallel)
    final totalIsc = moduleIsc * strings;

    // NEC 690.8: OCPD = Isc × 1.25 × 1.25 = 1.5625
    final fuseSize = moduleIsc * 1.56;

    // Max fuse per NEC 690.9: Module series fuse rating × (strings - 1)
    // This protects against backfeed from other parallel strings
    final maxFuseSize = seriesFuse * (strings - 1);

    // Check if calculated fuse fits within max
    final fuseOk = fuseSize <= maxFuseSize;

    // Combiner box specification
    final combinerSpec = '${strings}-string combiner, ${fuseSize.ceil()}A fuses, ${totalIsc.toStringAsFixed(1)}A total';

    setState(() {
      _totalIsc = totalIsc;
      _fuseSize = fuseSize;
      _maxFuseSize = maxFuseSize;
      _combinerSpec = combinerSpec;
      _fuseOk = fuseOk;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleIscController.text = '11.5';
    _stringsController.text = '4';
    _seriesFuseController.text = '20';
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
        title: Text('String Combiner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE & STRING DATA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Isc',
                      unit: 'A',
                      hint: 'Short circuit',
                      controller: _moduleIscController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Parallel Strings',
                      unit: '',
                      hint: '# of strings',
                      controller: _stringsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Module Series Fuse Rating',
                unit: 'A',
                hint: 'From module datasheet',
                controller: _seriesFuseController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalIsc != null) ...[
                _buildSectionHeader(colors, 'COMBINER SPECIFICATIONS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildFuseInfo(colors),
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
          Text(
            'String Combiner Box Sizing',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Combine parallel strings with proper fusing per NEC 690.9',
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
    final fuseOk = _fuseOk!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResultTile(colors, 'Total Isc', '${_totalIsc!.toStringAsFixed(1)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultTile(colors, 'String Fuse', '${_fuseSize!.ceil()} A', fuseOk ? colors.accentSuccess : colors.accentError),
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
                _buildResultRow(colors, 'Strings in Parallel', _stringsController.text),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Calculated Fuse (156%)', '${_fuseSize!.toStringAsFixed(1)} A'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Max Fuse Allowed', '${_maxFuseSize!.toStringAsFixed(1)} A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (fuseOk ? colors.accentSuccess : colors.accentError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  fuseOk ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 18,
                  color: fuseOk ? colors.accentSuccess : colors.accentError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fuseOk
                        ? 'Fuse size within module series fuse limit'
                        : 'Fuse exceeds limit - use modules with higher series fuse rating',
                    style: TextStyle(
                      color: fuseOk ? colors.accentSuccess : colors.accentError,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(ZaftoColors colors, String label, String value, Color accentColor) {
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w700)),
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

  Widget _buildFuseInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC 690.9 FUSE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildBullet(colors, 'String fuses required when 3+ strings in parallel'),
          _buildBullet(colors, 'Fuse rating ≤ Module series fuse × (strings - 1)'),
          _buildBullet(colors, 'Protects against backfeed from other strings'),
          _buildBullet(colors, 'Use PV-rated fuses (DC, 1000V or 1500V)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Common combiner sizes: 4, 8, 12, 16, 24 strings. Match fuse holder amp rating to calculated fuse size.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: colors.accentPrimary, fontSize: 13)),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
