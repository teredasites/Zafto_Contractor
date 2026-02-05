import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trailer Towing Calculator - Towing capacity and safety
class TrailerTowingScreen extends ConsumerStatefulWidget {
  const TrailerTowingScreen({super.key});
  @override
  ConsumerState<TrailerTowingScreen> createState() => _TrailerTowingScreenState();
}

class _TrailerTowingScreenState extends ConsumerState<TrailerTowingScreen> {
  final _vehicleGvwrController = TextEditingController();
  final _vehicleCurbWeightController = TextEditingController();
  final _maxTowRatingController = TextEditingController();
  final _trailerWeightController = TextEditingController();
  final _tongueWeightController = TextEditingController();

  double? _remainingPayload;
  double? _towingMargin;
  double? _tonguePercent;
  String? _status;

  void _calculate() {
    final gvwr = double.tryParse(_vehicleGvwrController.text);
    final curbWeight = double.tryParse(_vehicleCurbWeightController.text);
    final maxTow = double.tryParse(_maxTowRatingController.text);
    final trailerWeight = double.tryParse(_trailerWeightController.text);
    final tongueWeight = double.tryParse(_tongueWeightController.text);

    if (trailerWeight == null) {
      setState(() { _remainingPayload = null; });
      return;
    }

    double? remainingPayload;
    if (gvwr != null && curbWeight != null && tongueWeight != null) {
      remainingPayload = gvwr - curbWeight - tongueWeight;
    }

    double? towingMargin;
    if (maxTow != null) {
      towingMargin = maxTow - trailerWeight;
    }

    double? tonguePercent;
    if (tongueWeight != null && trailerWeight > 0) {
      tonguePercent = (tongueWeight / trailerWeight) * 100;
    }

    String status = 'Enter all values for complete analysis';
    if (towingMargin != null && tonguePercent != null && remainingPayload != null) {
      if (towingMargin < 0) {
        status = 'OVER CAPACITY - reduce trailer weight';
      } else if (remainingPayload < 0) {
        status = 'OVER GVWR - reduce tongue weight or cargo';
      } else if (tonguePercent < 10 || tonguePercent > 15) {
        status = 'Tongue weight should be 10-15% of trailer';
      } else if (towingMargin < trailerWeight * 0.1) {
        status = 'Near capacity - tow with caution';
      } else {
        status = 'Within safe towing limits';
      }
    }

    setState(() {
      _remainingPayload = remainingPayload;
      _towingMargin = towingMargin;
      _tonguePercent = tonguePercent;
      _status = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleGvwrController.clear();
    _vehicleCurbWeightController.clear();
    _maxTowRatingController.clear();
    _trailerWeightController.clear();
    _tongueWeightController.clear();
    setState(() { _remainingPayload = null; });
  }

  @override
  void dispose() {
    _vehicleGvwrController.dispose();
    _vehicleCurbWeightController.dispose();
    _maxTowRatingController.dispose();
    _trailerWeightController.dispose();
    _tongueWeightController.dispose();
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
        title: Text('Trailer Towing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Vehicle Specs', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'GVWR', unit: 'lbs', hint: '', controller: _vehicleGvwrController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Curb Weight', unit: 'lbs', hint: '', controller: _vehicleCurbWeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Tow Rating', unit: 'lbs', hint: 'From door sticker', controller: _maxTowRatingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('Trailer', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Trailer Weight', unit: 'lbs', hint: 'Loaded', controller: _trailerWeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tongue Weight', unit: 'lbs', hint: '', controller: _tongueWeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_status != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_status!.contains('OVER') || _status!.contains('should be')) {
      statusColor = colors.error;
    } else if (_status!.contains('caution')) {
      statusColor = colors.warning;
    } else if (_status!.contains('safe')) {
      statusColor = colors.accentSuccess;
    } else {
      statusColor = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('TOWING ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_towingMargin != null) _buildResultRow(colors, 'Towing Margin', '${_towingMargin!.toStringAsFixed(0)} lbs'),
        if (_remainingPayload != null) ...[
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Remaining Payload', '${_remainingPayload!.toStringAsFixed(0)} lbs'),
        ],
        if (_tonguePercent != null) ...[
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Tongue Weight %', '${_tonguePercent!.toStringAsFixed(1)}%'),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
