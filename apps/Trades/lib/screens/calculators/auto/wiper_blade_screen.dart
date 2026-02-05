import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wiper Blade Calculator - Wiper blade size reference
class WiperBladeScreen extends ConsumerStatefulWidget {
  const WiperBladeScreen({super.key});
  @override
  ConsumerState<WiperBladeScreen> createState() => _WiperBladeScreenState();
}

class _WiperBladeScreenState extends ConsumerState<WiperBladeScreen> {
  final _driverController = TextEditingController();
  final _passengerController = TextEditingController();
  final _rearController = TextEditingController();

  @override
  void dispose() {
    _driverController.dispose();
    _passengerController.dispose();
    _rearController.dispose();
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
        title: Text('Wiper Blade Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            _buildSizeInput(colors),
            const SizedBox(height: 24),
            _buildCommonSizes(colors),
            const SizedBox(height: 24),
            _buildBladeTypes(colors),
            const SizedBox(height: 24),
            _buildReplacementTips(colors),
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
        Icon(LucideIcons.cloud, color: colors.accentPrimary, size: 32),
        const SizedBox(height: 12),
        Text('Wiper Blade Reference', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Record your wiper sizes for easy reference', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSizeInput(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YOUR VEHICLE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildSizeField(colors, 'Driver', _driverController)),
          const SizedBox(width: 12),
          Expanded(child: _buildSizeField(colors, 'Passenger', _passengerController)),
          const SizedBox(width: 12),
          Expanded(child: _buildSizeField(colors, 'Rear', _rearController)),
        ]),
      ]),
    );
  }

  Widget _buildSizeField(ZaftoColors colors, String label, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.bgBase,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          hintText: '—"',
          hintStyle: TextStyle(color: colors.textTertiary),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ]);
  }

  Widget _buildCommonSizes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SIZE RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSizeRow(colors, 'Compact Cars', '18-22" / 16-20"'),
        _buildSizeRow(colors, 'Sedans', '22-26" / 18-22"'),
        _buildSizeRow(colors, 'SUVs/Trucks', '22-28" / 18-24"'),
        _buildSizeRow(colors, 'Rear Wipers', '10-16" typically'),
        const SizedBox(height: 8),
        Text('Driver side is usually longer than passenger', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildSizeRow(ZaftoColors colors, String vehicle, String sizes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(vehicle, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(sizes, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildBladeTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BLADE TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildBladeType(colors, 'Conventional', 'Metal frame, budget option, traditional design'),
        _buildBladeType(colors, 'Beam/Bracketless', 'Curved design, better contact, premium'),
        _buildBladeType(colors, 'Hybrid', 'Frame with aerodynamic shell, best of both'),
        _buildBladeType(colors, 'Winter/Snow', 'Rubber cover prevents ice buildup'),
      ]),
    );
  }

  Widget _buildBladeType(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.check, size: 14, color: colors.accentPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildReplacementTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REPLACEMENT TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Replace every 6-12 months', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Signs: streaking, squeaking, skipping', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Clean windshield before new install', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Lift arm carefully - spring is strong', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Match connector type (J-hook, pin, etc.)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• OEM sizes are in owner\'s manual', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
