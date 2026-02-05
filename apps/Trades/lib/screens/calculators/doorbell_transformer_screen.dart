import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Doorbell Transformer Calculator - Design System v2.6
/// VA sizing for doorbell and chime systems
class DoorbellTransformerScreen extends ConsumerStatefulWidget {
  const DoorbellTransformerScreen({super.key});
  @override
  ConsumerState<DoorbellTransformerScreen> createState() => _DoorbellTransformerScreenState();
}

class _DoorbellTransformerScreenState extends ConsumerState<DoorbellTransformerScreen> {
  int _doorbellCount = 1;
  String _doorbellType = 'standard';
  int _chimeCount = 1;
  String _chimeType = 'mechanical';
  bool _hasVideoCamera = false;

  int? _requiredVA;
  int? _requiredVoltage;
  String? _transformerSize;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // VA requirements by device type
    double totalVA = 0;
    int voltage = 16;

    // Doorbell buttons (minimal draw)
    totalVA += _doorbellCount * 0.5;

    // Chimes
    if (_chimeType == 'mechanical') {
      totalVA += _chimeCount * 10; // Mechanical chimes ~10VA
    } else {
      totalVA += _chimeCount * 15; // Electronic chimes ~15VA
    }

    // Video doorbell (if present)
    if (_hasVideoCamera) {
      totalVA += 20; // Video doorbells need more power
      voltage = 24; // Most video doorbells need 24V
    }

    // Smart doorbell type
    if (_doorbellType == 'smart') {
      totalVA += 10 * _doorbellCount;
      voltage = 24;
    }

    // Size transformer with 25% margin
    final sizedVA = (totalVA * 1.25).ceil();

    // Standard sizes
    int transformerSize;
    if (sizedVA <= 10) {
      transformerSize = 10;
    } else if (sizedVA <= 16) {
      transformerSize = 16;
    } else if (sizedVA <= 20) {
      transformerSize = 20;
    } else if (sizedVA <= 30) {
      transformerSize = 30;
    } else {
      transformerSize = 40;
    }

    String recommendation;
    if (_hasVideoCamera || _doorbellType == 'smart') {
      recommendation = 'Use 24V transformer for smart/video doorbells. Check device specs.';
    } else if (_chimeCount > 2) {
      recommendation = 'Multiple chimes may need larger transformer. Test operation.';
    } else {
      recommendation = 'Standard $voltage V transformer suitable for this installation.';
    }

    setState(() {
      _requiredVA = sizedVA;
      _requiredVoltage = voltage;
      _transformerSize = '${transformerSize}VA @ ${voltage}V';
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _doorbellCount = 1;
      _doorbellType = 'standard';
      _chimeCount = 1;
      _chimeType = 'mechanical';
      _hasVideoCamera = false;
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
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Doorbell Transformer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DOORBELL BUTTONS'),
              const SizedBox(height: 12),
              _buildCounterRow(colors, label: 'Number of Buttons', value: _doorbellCount, min: 1, max: 4, onChanged: (v) { setState(() => _doorbellCount = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Button Type', options: const ['Standard', 'Smart/Lighted'], selectedIndex: _doorbellType == 'standard' ? 0 : 1, onChanged: (i) { setState(() => _doorbellType = i == 0 ? 'standard' : 'smart'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CHIMES'),
              const SizedBox(height: 12),
              _buildCounterRow(colors, label: 'Number of Chimes', value: _chimeCount, min: 1, max: 4, onChanged: (v) { setState(() => _chimeCount = v); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Chime Type', options: const ['Mechanical', 'Electronic'], selectedIndex: _chimeType == 'mechanical' ? 0 : 1, onChanged: (i) { setState(() => _chimeType = i == 0 ? 'mechanical' : 'electronic'); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VIDEO DOORBELL'),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'Includes video doorbell camera', value: _hasVideoCamera, onChanged: (v) { setState(() => _hasVideoCamera = v ?? false); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'TRANSFORMER SIZING'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.bellRing, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Standard: 16V 10VA. Smart/video: 24V 20-40VA. Always check manufacturer specs.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCounterRow(ZaftoColors colors, {required String label, required int value, required int min, required int max, required ValueChanged<int> onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        Row(children: [
          IconButton(
            icon: Icon(LucideIcons.minus, color: value > min ? colors.textPrimary : colors.textSecondary),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
            child: Text('$value', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: Icon(LucideIcons.plus, color: value < max ? colors.textPrimary : colors.textSecondary),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ]),
      ],
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool?> onChanged}) {
    return Row(children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
    ]);
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_transformerSize == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Icon(LucideIcons.zap, color: colors.accentPrimary, size: 32),
          const SizedBox(height: 12),
          Text(_transformerSize!, style: TextStyle(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
          Text('Recommended Transformer', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Calculated Load', '${_requiredVA}VA')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Voltage', '${_requiredVoltage}V')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
