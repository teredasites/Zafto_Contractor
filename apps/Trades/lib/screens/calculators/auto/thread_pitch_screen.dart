import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Thread Pitch Calculator - Thread pitch identification and conversion
class ThreadPitchScreen extends ConsumerStatefulWidget {
  const ThreadPitchScreen({super.key});
  @override
  ConsumerState<ThreadPitchScreen> createState() => _ThreadPitchScreenState();
}

class _ThreadPitchScreenState extends ConsumerState<ThreadPitchScreen> {
  final _tpiController = TextEditingController();
  final _mmController = TextEditingController();

  double? _convertedTpi;
  double? _convertedMm;

  void _calculateFromTpi() {
    final tpi = double.tryParse(_tpiController.text);
    if (tpi == null || tpi <= 0) {
      setState(() { _convertedMm = null; });
      return;
    }
    setState(() {
      _convertedMm = 25.4 / tpi;
    });
  }

  void _calculateFromMm() {
    final mm = double.tryParse(_mmController.text);
    if (mm == null || mm <= 0) {
      setState(() { _convertedTpi = null; });
      return;
    }
    setState(() {
      _convertedTpi = 25.4 / mm;
    });
  }

  @override
  void dispose() {
    _tpiController.dispose();
    _mmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Thread Pitch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            _buildTpiConverter(colors),
            const SizedBox(height: 16),
            _buildMmConverter(colors),
            const SizedBox(height: 24),
            _buildCommonSae(colors),
            const SizedBox(height: 24),
            _buildCommonMetric(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('TPI × Pitch (mm) = 25.4', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Convert between TPI (threads per inch) and metric pitch (mm)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildTpiConverter(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TPI TO METRIC', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _tpiController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'TPI',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _calculateFromTpi(),
            ),
          ),
          const SizedBox(width: 12),
          Icon(LucideIcons.arrowRight, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text(_convertedMm?.toStringAsFixed(3) ?? '—', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('mm pitch', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMmConverter(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('METRIC TO TPI', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _mmController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Pitch (mm)',
                labelStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgBase,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _calculateFromMm(),
            ),
          ),
          const SizedBox(width: 12),
          Icon(LucideIcons.arrowRight, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text(_convertedTpi?.toStringAsFixed(1) ?? '—', style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('TPI', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildCommonSae(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SAE THREADS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildThreadRow(colors, '1/4-20', 'Coarse'),
        _buildThreadRow(colors, '1/4-28', 'Fine'),
        _buildThreadRow(colors, '5/16-18', 'Coarse'),
        _buildThreadRow(colors, '5/16-24', 'Fine'),
        _buildThreadRow(colors, '3/8-16', 'Coarse'),
        _buildThreadRow(colors, '3/8-24', 'Fine'),
        _buildThreadRow(colors, '1/2-13', 'Coarse'),
        _buildThreadRow(colors, '1/2-20', 'Fine'),
      ]),
    );
  }

  Widget _buildCommonMetric(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON METRIC THREADS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildThreadRow(colors, 'M6 x 1.0', 'Coarse'),
        _buildThreadRow(colors, 'M8 x 1.25', 'Coarse'),
        _buildThreadRow(colors, 'M8 x 1.0', 'Fine'),
        _buildThreadRow(colors, 'M10 x 1.5', 'Coarse'),
        _buildThreadRow(colors, 'M10 x 1.25', 'Fine'),
        _buildThreadRow(colors, 'M12 x 1.75', 'Coarse'),
        _buildThreadRow(colors, 'M12 x 1.25', 'Fine'),
      ]),
    );
  }

  Widget _buildThreadRow(ZaftoColors colors, String thread, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(thread, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'monospace')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: type == 'Coarse' ? colors.accentPrimary.withValues(alpha: 0.2) : colors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(type, style: TextStyle(color: type == 'Coarse' ? colors.accentPrimary : colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }
}
