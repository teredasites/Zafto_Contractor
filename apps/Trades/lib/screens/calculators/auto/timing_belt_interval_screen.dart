import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Timing Belt/Chain Service Interval Calculator
class TimingBeltIntervalScreen extends ConsumerStatefulWidget {
  const TimingBeltIntervalScreen({super.key});
  @override
  ConsumerState<TimingBeltIntervalScreen> createState() => _TimingBeltIntervalScreenState();
}

class _TimingBeltIntervalScreenState extends ConsumerState<TimingBeltIntervalScreen> {
  final _currentMilesController = TextEditingController();
  final _lastServiceController = TextEditingController(text: '0');
  String _timingType = 'Belt';
  bool _isInterference = true;

  int? _milesRemaining;
  int? _serviceInterval;
  String? _urgency;
  String? _recommendation;

  void _calculate() {
    final currentMiles = double.tryParse(_currentMilesController.text);
    final lastService = double.tryParse(_lastServiceController.text) ?? 0;

    if (currentMiles == null || currentMiles <= 0) {
      setState(() { _milesRemaining = null; });
      return;
    }

    // Service intervals
    int interval;
    if (_timingType == 'Belt') {
      interval = 60000; // 60-100K typical, use conservative
    } else if (_timingType == 'Chain') {
      interval = 150000; // Chains last longer but still need service
    } else {
      interval = 100000; // Gear drive (rare, very long life)
    }

    final milesSinceService = currentMiles - lastService;
    final remaining = (interval - milesSinceService).round();

    String urgency;
    if (remaining <= 0) {
      urgency = 'OVERDUE - Service immediately!';
    } else if (remaining <= 10000) {
      urgency = 'Due soon - Schedule service';
    } else if (remaining <= 20000) {
      urgency = 'Plan service within next year';
    } else {
      urgency = 'Good - Continue monitoring';
    }

    String recommendation;
    if (_timingType == 'Belt' && _isInterference) {
      recommendation = 'INTERFERENCE ENGINE: Belt failure = engine damage. Don\'t delay service!';
    } else if (_timingType == 'Belt') {
      recommendation = 'Replace water pump, tensioner, and idlers with belt';
    } else {
      recommendation = 'Inspect guides and tensioners; replace if worn';
    }

    setState(() {
      _milesRemaining = remaining;
      _serviceInterval = interval;
      _urgency = urgency;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentMilesController.clear();
    _lastServiceController.text = '0';
    setState(() { _milesRemaining = null; });
  }

  @override
  void dispose() {
    _currentMilesController.dispose();
    _lastServiceController.dispose();
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
        title: Text('Timing Belt Service', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('TIMING TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            if (_timingType == 'Belt') _buildInterferenceToggle(colors),
            if (_timingType == 'Belt') const SizedBox(height: 16),
            ZaftoInputField(label: 'Current Mileage', unit: 'mi', hint: 'Odometer reading', controller: _currentMilesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Last Service', unit: 'mi', hint: '0 if never done', controller: _lastServiceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_milesRemaining != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Belt', 'Chain', 'Gear'].map((type) => ChoiceChip(
        label: Text(type),
        selected: _timingType == type,
        onSelected: (_) => setState(() { _timingType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildInterferenceToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Interference'), selected: _isInterference, onSelected: (_) => setState(() { _isInterference = true; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Non-Interference'), selected: !_isInterference, onSelected: (_) => setState(() { _isInterference = false; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Remaining = Interval - Miles Since', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Belt: 60-100K | Chain: 100-150K', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isOverdue = _milesRemaining! <= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isOverdue ? Colors.red.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Miles Remaining', isOverdue ? 'OVERDUE' : '${_milesRemaining!}', isPrimary: true, isWarning: isOverdue),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Service Interval', '${_serviceInterval!} mi'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isOverdue ? Colors.red.withValues(alpha: 0.1) : colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_urgency!, style: TextStyle(color: isOverdue ? Colors.red : colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false, bool isWarning = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isWarning ? Colors.red : (isPrimary ? colors.accentPrimary : colors.textPrimary), fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
