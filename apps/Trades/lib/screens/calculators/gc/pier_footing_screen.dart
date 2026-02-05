import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pier/Post Footing - Individual footings
class PierFootingScreen extends ConsumerStatefulWidget {
  const PierFootingScreen({super.key});
  @override
  ConsumerState<PierFootingScreen> createState() => _PierFootingScreenState();
}

class _PierFootingScreenState extends ConsumerState<PierFootingScreen> {
  final _diameterController = TextEditingController(text: '12');
  final _depthController = TextEditingController(text: '42');
  final _countController = TextEditingController(text: '6');

  double? _volumeEach;
  double? _totalVolume;
  int? _bags80lb;
  int? _bags60lb;

  @override
  void dispose() { _diameterController.dispose(); _depthController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final diameterInches = double.tryParse(_diameterController.text);
    final depthInches = double.tryParse(_depthController.text);
    final count = int.tryParse(_countController.text);

    if (diameterInches == null || depthInches == null || count == null) {
      setState(() { _volumeEach = null; _totalVolume = null; _bags80lb = null; _bags60lb = null; });
      return;
    }

    // Volume of cylinder: π × r² × h
    final radiusFeet = (diameterInches / 2) / 12;
    final depthFeet = depthInches / 12;
    final volumeEach = math.pi * radiusFeet * radiusFeet * depthFeet;
    final totalVolume = volumeEach * count;

    // Bags: 80lb = 0.6 cu ft, 60lb = 0.45 cu ft
    final bags80lb = (totalVolume / 0.6).ceil();
    final bags60lb = (totalVolume / 0.45).ceil();

    setState(() { _volumeEach = volumeEach; _totalVolume = totalVolume; _bags80lb = bags80lb; _bags60lb = bags60lb; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _diameterController.text = '12'; _depthController.text = '42'; _countController.text = '6'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pier Footing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Diameter', unit: 'inches', controller: _diameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Piers', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalVolume!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume Each', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeEach!.toStringAsFixed(2)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('80lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags80lb', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('60lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags60lb', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Frost line depth varies by region. Check local code for minimum depth requirements.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
