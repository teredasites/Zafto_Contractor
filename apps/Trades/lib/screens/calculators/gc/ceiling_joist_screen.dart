import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ceiling Joist Calculator - Flat ceiling framing
class CeilingJoistScreen extends ConsumerStatefulWidget {
  const CeilingJoistScreen({super.key});
  @override
  ConsumerState<CeilingJoistScreen> createState() => _CeilingJoistScreenState();
}

class _CeilingJoistScreenState extends ConsumerState<CeilingJoistScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _spanController = TextEditingController(text: '14');

  String _spacing = '16';
  bool _atticStorage = false;

  int? _joistCount;
  String? _joistSize;

  @override
  void dispose() { _lengthController.dispose(); _spanController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final span = double.tryParse(_spanController.text);
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (length == null || span == null) {
      setState(() { _joistCount = null; _joistSize = null; });
      return;
    }

    final lengthInches = length * 12;
    final joistCount = (lengthInches / spacingInches).floor() + 1;

    // Sizing based on span and load (10 PSF uninhabitable attic, 20 PSF limited storage)
    String joistSize;
    if (_atticStorage) {
      if (span <= 10) joistSize = '2x6';
      else if (span <= 14) joistSize = '2x8';
      else if (span <= 18) joistSize = '2x10';
      else joistSize = '2x12';
    } else {
      if (span <= 12) joistSize = '2x4';
      else if (span <= 16) joistSize = '2x6';
      else if (span <= 20) joistSize = '2x8';
      else joistSize = '2x10';
    }

    setState(() { _joistCount = joistCount; _joistSize = joistSize; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _spanController.text = '14'; setState(() { _spacing = '16'; _atticStorage = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ceiling Joists', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 16),
            _buildAtticStorageToggle(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Ceiling Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Joist Span', unit: 'ft', controller: _spanController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_joistCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('JOISTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_joistCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recommended Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_joistSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    return Row(children: ['16', '24'].map((s) {
      final isSelected = _spacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _spacing = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s == '16' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s" OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }

  Widget _buildAtticStorageToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); setState(() => _atticStorage = !_atticStorage); _calculate(); },
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(children: [
          Icon(_atticStorage ? LucideIcons.checkSquare : LucideIcons.square, color: _atticStorage ? colors.accentPrimary : colors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('Attic Storage Load (20 PSF)', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }
}
