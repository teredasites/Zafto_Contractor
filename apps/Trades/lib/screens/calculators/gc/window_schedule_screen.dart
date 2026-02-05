import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Window Schedule Calculator - Window takeoff and materials
class WindowScheduleScreen extends ConsumerStatefulWidget {
  const WindowScheduleScreen({super.key});
  @override
  ConsumerState<WindowScheduleScreen> createState() => _WindowScheduleScreenState();
}

class _WindowScheduleScreenState extends ConsumerState<WindowScheduleScreen> {
  final _singleController = TextEditingController(text: '6');
  final _doubleController = TextEditingController(text: '4');
  final _slidingController = TextEditingController(text: '2');
  final _pictureController = TextEditingController(text: '1');

  int? _totalWindows;
  double? _totalGlassArea;
  int? _locksNeeded;
  int? _screensNeeded;

  @override
  void dispose() { _singleController.dispose(); _doubleController.dispose(); _slidingController.dispose(); _pictureController.dispose(); super.dispose(); }

  void _calculate() {
    final single = int.tryParse(_singleController.text) ?? 0;
    final double_ = int.tryParse(_doubleController.text) ?? 0;
    final sliding = int.tryParse(_slidingController.text) ?? 0;
    final picture = int.tryParse(_pictureController.text) ?? 0;

    final totalWindows = single + double_ + sliding + picture;

    // Average glass areas (sq ft)
    // Single hung: ~10 sq ft, Double hung: ~12, Sliding: ~20, Picture: ~15
    final totalGlassArea = (single * 10.0) + (double_ * 12.0) + (sliding * 20.0) + (picture * 15.0);

    // Locks: single/double have 1-2, sliding has 1
    final locksNeeded = single + (double_ * 2) + sliding;

    // Screens for operable windows
    final screensNeeded = single + double_ + sliding;

    setState(() { _totalWindows = totalWindows; _totalGlassArea = totalGlassArea; _locksNeeded = locksNeeded; _screensNeeded = screensNeeded; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _singleController.text = '6'; _doubleController.text = '4'; _slidingController.text = '2'; _pictureController.text = '1'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Window Schedule', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Single Hung', unit: 'qty', controller: _singleController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Double Hung', unit: 'qty', controller: _doubleController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Sliding', unit: 'qty', controller: _slidingController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Picture', unit: 'qty', controller: _pictureController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalWindows != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL WINDOWS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalWindows', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Glass Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalGlassArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Window Locks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_locksNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Screens', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_screensNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Check egress requirements for bedrooms. Min 5.7 sq ft opening, 24" min height, 20" min width.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCommonSizesTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCommonSizesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON WINDOW SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Bedroom (egress)', '32" x 48" min'),
        _buildTableRow(colors, 'Kitchen', '36" x 48"'),
        _buildTableRow(colors, 'Bathroom', '24" x 36"'),
        _buildTableRow(colors, 'Living Room', '48" x 60"'),
        _buildTableRow(colors, 'Slider', '60" x 48"'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
