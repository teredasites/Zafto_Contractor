import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ridge Board Sizing - Length and dimension
class RidgeBoardScreen extends ConsumerStatefulWidget {
  const RidgeBoardScreen({super.key});
  @override
  ConsumerState<RidgeBoardScreen> createState() => _RidgeBoardScreenState();
}

class _RidgeBoardScreenState extends ConsumerState<RidgeBoardScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _rafterSizeController = TextEditingController(text: '8');

  double? _ridgeLength;
  String? _ridgeSize;
  int? _boards;

  @override
  void dispose() { _lengthController.dispose(); _rafterSizeController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final rafterDepth = int.tryParse(_rafterSizeController.text);

    if (length == null || rafterDepth == null) {
      setState(() { _ridgeLength = null; _ridgeSize = null; _boards = null; });
      return;
    }

    // Ridge board should be 1" deeper than rafters
    int ridgeDepth;
    if (rafterDepth <= 6) ridgeDepth = 8;
    else if (rafterDepth <= 8) ridgeDepth = 10;
    else if (rafterDepth <= 10) ridgeDepth = 12;
    else ridgeDepth = 12; // Max standard dimension

    final ridgeSize = '2x$ridgeDepth';
    final boards = (length / 16).ceil(); // 16' boards typical

    setState(() { _ridgeLength = length; _ridgeSize = ridgeSize; _boards = boards; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _rafterSizeController.text = '8'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Ridge Board', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Building Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rafter Depth', unit: 'inches', hint: 'e.g., 8 for 2x8', controller: _rafterSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_ridgeSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RIDGE SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_ridgeSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_ridgeLength!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('16\' Boards', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_boards', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Ridge board must be at least 1" deeper than rafter cut to allow full bearing.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
