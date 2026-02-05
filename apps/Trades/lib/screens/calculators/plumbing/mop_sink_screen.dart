import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Mop Sink / Service Sink Calculator - Design System v2.6
///
/// Calculates rough-in dimensions and plumbing requirements for mop sinks.
/// Covers floor-mounted and wall-mounted service sinks.
///
/// References: IPC 2024, ADA Standards
class MopSinkScreen extends ConsumerStatefulWidget {
  const MopSinkScreen({super.key});
  @override
  ConsumerState<MopSinkScreen> createState() => _MopSinkScreenState();
}

class _MopSinkScreenState extends ConsumerState<MopSinkScreen> {
  // Sink type
  String _sinkType = 'floor_24';

  // Faucet type
  String _faucetType = 'wall_mount';

  // ADA compliant
  bool _adaRequired = false;

  static const Map<String, ({String desc, int width, int depth, int drainSize, int dfu})> _sinkTypes = {
    'floor_24': (desc: 'Floor Mount 24\"', width: 24, depth: 24, drainSize: 3, dfu: 3),
    'floor_28': (desc: 'Floor Mount 28\"', width: 28, depth: 28, drainSize: 3, dfu: 3),
    'floor_32': (desc: 'Floor Mount 32\"', width: 32, depth: 32, drainSize: 3, dfu: 3),
    'wall_20': (desc: 'Wall Mount 20\"', width: 20, depth: 16, drainSize: 2, dfu: 3),
    'wall_24': (desc: 'Wall Mount 24\"', width: 24, depth: 20, drainSize: 2, dfu: 3),
  };

  static const Map<String, ({String desc, int roughInHeight})> _faucetTypes = {
    'wall_mount': (desc: 'Wall-Mount Service', roughInHeight: 42),
    'deck_mount': (desc: 'Deck-Mount', roughInHeight: 0),
    'hose_bib': (desc: 'Hose Bib Style', roughInHeight: 36),
  };

  // Rough-in dimensions
  Map<String, String> get _roughInDimensions {
    final sink = _sinkTypes[_sinkType];
    final faucet = _faucetTypes[_faucetType];
    final isFloorMount = _sinkType.startsWith('floor');

    return {
      'Drain CL from wall': isFloorMount ? '${(sink?.width ?? 24) ~/ 2}\"' : '4-6\" from wall',
      'Drain CL from side': '${(sink?.width ?? 24) ~/ 2}\"',
      'Supply height': isFloorMount ? '${faucet?.roughInHeight ?? 42}\" AFF' : '8\" above rim',
      'Supply spacing': '8\" center-to-center',
      'Drain size': '${sink?.drainSize ?? 3}\"',
      'Trap size': '${sink?.drainSize ?? 3}\" P-trap',
    };
  }

  // ADA dimensions
  Map<String, String> get _adaDimensions {
    return {
      'Rim height max': '34\" AFF',
      'Knee clearance': '27\" min height',
      'Clear floor space': '30\" × 48\" min',
      'Controls': 'Lever or sensor',
    };
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
        title: Text(
          'Mop Sink Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildSinkTypeCard(colors),
          const SizedBox(height: 16),
          _buildFaucetCard(colors),
          const SizedBox(height: 16),
          _buildAdaCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final sink = _sinkTypes[_sinkType];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${sink?.width ?? 24}\" × ${sink?.depth ?? 24}\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            sink?.desc ?? 'Mop Sink',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUGH-IN DIMENSIONS',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                ..._roughInDimensions.entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildResultRow(colors, entry.key, entry.value),
                  ),
                ),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'DFU', '${sink?.dfu ?? 3}'),
              ],
            ),
          ),
          if (_adaRequired) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.accessibility, color: colors.accentPrimary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ADA REQUIREMENTS',
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._adaDimensions.entries.map((entry) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildResultRow(colors, entry.key, entry.value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSinkTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SINK TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._sinkTypes.entries.map((entry) {
            final isSelected = _sinkType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _sinkType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value.drainSize}\" drain',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFaucetCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAUCET TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._faucetTypes.entries.map((entry) {
            final isSelected = _faucetType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _faucetType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (entry.value.roughInHeight > 0)
                        Text(
                          '${entry.value.roughInHeight}\" AFF',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _adaRequired ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: _adaRequired ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _adaRequired = !_adaRequired);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _adaRequired ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _adaRequired ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _adaRequired
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADA Compliant',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Include accessibility requirements',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.droplet, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC Requirements',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Required in commercial buildings\n'
            '• 3\" trap standard for floor mount\n'
            '• Provide hot and cold water\n'
            '• Floor drain nearby recommended\n'
            '• Vacuum breaker on hose connection\n'
            '• Check local requirements',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
