import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// OCPD Sizing (DC) Calculator - DC fuses and breakers
class OcpdDcScreen extends ConsumerStatefulWidget {
  const OcpdDcScreen({super.key});
  @override
  ConsumerState<OcpdDcScreen> createState() => _OcpdDcScreenState();
}

class _OcpdDcScreenState extends ConsumerState<OcpdDcScreen> {
  final _iscController = TextEditingController(text: '10.8');
  final _moduleOcpdController = TextEditingController(text: '20');
  final _stringsController = TextEditingController(text: '3');
  final _vocController = TextEditingController(text: '500');

  double? _minOcpdRating;
  double? _maxOcpdRating;
  int? _recommendedFuse;
  bool? _fusingRequired;
  String? _notes;

  @override
  void dispose() {
    _iscController.dispose();
    _moduleOcpdController.dispose();
    _stringsController.dispose();
    _vocController.dispose();
    super.dispose();
  }

  void _calculate() {
    final isc = double.tryParse(_iscController.text);
    final moduleOcpd = double.tryParse(_moduleOcpdController.text);
    final strings = int.tryParse(_stringsController.text);
    final voc = double.tryParse(_vocController.text);

    if (isc == null || moduleOcpd == null || strings == null || voc == null) {
      setState(() {
        _minOcpdRating = null;
        _maxOcpdRating = null;
        _recommendedFuse = null;
        _fusingRequired = null;
        _notes = null;
      });
      return;
    }

    // NEC 690.9 - OCPD requirements
    // Minimum: Isc × 1.25 × 1.25 = Isc × 1.56
    final minOcpdRating = isc * 1.56;

    // Maximum: Module series fuse rating from nameplate
    final maxOcpdRating = moduleOcpd;

    // Check if fusing is required
    // Per 690.9(A) Exception: Fusing not required if module Isc × (N-1) < module series fuse rating
    // where N is number of parallel strings
    final backfeedCurrent = isc * (strings - 1);
    final fusingRequired = backfeedCurrent > moduleOcpd;

    // Find standard fuse size between min and max
    final standardFuses = [1, 2, 3, 5, 6, 8, 10, 12, 15, 20, 25, 30, 35, 40, 50, 60];
    int? recommendedFuse;
    for (final fuse in standardFuses) {
      if (fuse >= minOcpdRating && fuse <= maxOcpdRating) {
        recommendedFuse = fuse;
        break;
      }
    }

    String notes;
    if (!fusingRequired) {
      notes = 'String fusing NOT required per NEC 690.9(A) Exception - only $strings parallel strings.';
    } else if (recommendedFuse == null) {
      notes = 'No standard fuse fits between min (${minOcpdRating.toStringAsFixed(1)}A) and max (${maxOcpdRating.toStringAsFixed(0)}A). Review module specs.';
    } else {
      notes = 'Use ${recommendedFuse}A DC-rated fuses at each string combiner input.';
    }

    setState(() {
      _minOcpdRating = minOcpdRating;
      _maxOcpdRating = maxOcpdRating;
      _recommendedFuse = recommendedFuse;
      _fusingRequired = fusingRequired;
      _notes = notes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _iscController.text = '10.8';
    _moduleOcpdController.text = '20';
    _stringsController.text = '3';
    _vocController.text = '500';
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
        title: Text('DC OCPD Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Isc',
                      unit: 'A',
                      hint: 'Short circuit',
                      controller: _iscController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Series Fuse',
                      unit: 'A',
                      hint: 'From nameplate',
                      controller: _moduleOcpdController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Parallel Strings',
                      unit: '#',
                      hint: 'String count',
                      controller: _stringsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'String Voc',
                      unit: 'V',
                      hint: 'Open circuit',
                      controller: _vocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_minOcpdRating != null) ...[
                _buildSectionHeader(colors, 'FUSE SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildNecReference(colors),
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
              Icon(LucideIcons.shieldCheck, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'DC Overcurrent Protection',
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
            'Size string fuses per NEC 690.9',
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
    final required = _fusingRequired!;
    final hasFuse = _recommendedFuse != null;
    final statusColor = !required ? colors.accentInfo :
                        hasFuse ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (!required) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Fusing Not Required',
                  style: TextStyle(color: colors.accentInfo, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ] else if (hasFuse) ...[
            Text('Recommended Fuse Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              '${_recommendedFuse}A',
              style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
            ),
            Text(
              'DC-rated, 600V+ minimum',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 24),
                const SizedBox(width: 8),
                Text(
                  'No Valid Fuse Size',
                  style: TextStyle(color: colors.accentWarning, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRangeTile(colors, 'Minimum', '${_minOcpdRating!.toStringAsFixed(1)} A', 'Isc × 1.56'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRangeTile(colors, 'Maximum', '${_maxOcpdRating!.toStringAsFixed(0)} A', 'Module rating'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notes!,
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

  Widget _buildRangeTile(ZaftoColors colors, String label, String value, String sublabel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          Text(sublabel, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNecReference(ZaftoColors colors) {
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
          Text('NEC 690.9 REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildNecRow(colors, '690.9(A)', 'OCPD required if backfeed can exceed module series fuse rating'),
          _buildNecRow(colors, '690.9(B)', 'OCPD rating: ≥156% of Isc but ≤ module max series fuse'),
          _buildNecRow(colors, '690.9(D)', 'DC-rated fuses or circuit breakers required'),
        ],
      ),
    );
  }

  Widget _buildNecRow(ZaftoColors colors, String code, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
