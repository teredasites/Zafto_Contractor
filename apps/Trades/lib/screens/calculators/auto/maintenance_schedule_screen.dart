import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Maintenance Schedule Calculator - Track maintenance intervals
class MaintenanceScheduleScreen extends ConsumerStatefulWidget {
  const MaintenanceScheduleScreen({super.key});
  @override
  ConsumerState<MaintenanceScheduleScreen> createState() => _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends ConsumerState<MaintenanceScheduleScreen> {
  final _currentMileageController = TextEditingController();

  int? _currentMileage;

  final List<Map<String, dynamic>> _maintenanceItems = [
    {'name': 'Oil Change (Conventional)', 'interval': 5000, 'icon': LucideIcons.droplet},
    {'name': 'Oil Change (Synthetic)', 'interval': 7500, 'icon': LucideIcons.droplet},
    {'name': 'Oil Change (Full Synthetic)', 'interval': 10000, 'icon': LucideIcons.droplet},
    {'name': 'Tire Rotation', 'interval': 7500, 'icon': LucideIcons.disc},
    {'name': 'Air Filter', 'interval': 20000, 'icon': LucideIcons.wind},
    {'name': 'Cabin Air Filter', 'interval': 20000, 'icon': LucideIcons.airVent},
    {'name': 'Brake Inspection', 'interval': 15000, 'icon': LucideIcons.octagon},
    {'name': 'Brake Fluid Flush', 'interval': 30000, 'icon': LucideIcons.beaker},
    {'name': 'Coolant Flush', 'interval': 50000, 'icon': LucideIcons.thermometer},
    {'name': 'Transmission Fluid', 'interval': 60000, 'icon': LucideIcons.cog},
    {'name': 'Spark Plugs', 'interval': 60000, 'icon': LucideIcons.zap},
    {'name': 'Timing Belt', 'interval': 90000, 'icon': LucideIcons.clock},
    {'name': 'Serpentine Belt', 'interval': 60000, 'icon': LucideIcons.repeat},
    {'name': 'Battery', 'interval': 50000, 'icon': LucideIcons.battery},
    {'name': 'Fuel Filter', 'interval': 50000, 'icon': LucideIcons.filter},
  ];

  void _calculate() {
    final mileage = int.tryParse(_currentMileageController.text);
    setState(() { _currentMileage = mileage; });
  }

  int _getNextServiceMileage(int interval) {
    if (_currentMileage == null) return interval;
    final remainder = _currentMileage! % interval;
    return _currentMileage! + (interval - remainder);
  }

  int _getMilesUntilService(int interval) {
    if (_currentMileage == null) return interval;
    final next = _getNextServiceMileage(interval);
    return next - _currentMileage!;
  }

  @override
  void dispose() {
    _currentMileageController.dispose();
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
        title: Text('Maintenance Schedule', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildMileageInput(colors),
            const SizedBox(height: 24),
            if (_currentMileage != null) _buildUpcoming(colors),
            const SizedBox(height: 24),
            _buildScheduleList(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMileageInput(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CURRENT MILEAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        TextField(
          controller: _currentMileageController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.bgBase,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            hintText: 'Enter odometer',
            hintStyle: TextStyle(color: colors.textTertiary, fontSize: 16),
            suffixText: 'mi',
            suffixStyle: TextStyle(color: colors.textTertiary, fontSize: 16),
          ),
          onChanged: (_) => _calculate(),
        ),
      ]),
    );
  }

  Widget _buildUpcoming(ZaftoColors colors) {
    // Find items due soon (within 1000 miles)
    final upcoming = _maintenanceItems.where((item) {
      final milesUntil = _getMilesUntilService(item['interval']);
      return milesUntil <= 1000;
    }).toList();

    if (upcoming.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess),
          const SizedBox(width: 12),
          Text('No services due soon!', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.warning.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.alertTriangle, color: colors.warning, size: 18),
          const SizedBox(width: 8),
          Text('SERVICES DUE SOON', style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ...upcoming.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item['name'], style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            Text('${_getMilesUntilService(item['interval'])} mi', style: TextStyle(color: colors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        )),
      ]),
    );
  }

  Widget _buildScheduleList(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MAINTENANCE INTERVALS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._maintenanceItems.map((item) => _buildMaintenanceRow(colors, item)),
      ]),
    );
  }

  Widget _buildMaintenanceRow(ZaftoColors colors, Map<String, dynamic> item) {
    final milesUntil = _currentMileage != null ? _getMilesUntilService(item['interval']) : null;
    final isDueSoon = milesUntil != null && milesUntil <= 1000;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDueSoon ? colors.warning.withValues(alpha: 0.1) : colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(item['icon'], color: isDueSoon ? colors.warning : colors.textTertiary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'], style: TextStyle(color: colors.textPrimary, fontSize: 13)),
            Text('Every ${item['interval'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} miles', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
        if (milesUntil != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDueSoon ? colors.warning : colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${milesUntil.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} mi', style: TextStyle(color: isDueSoon ? colors.warning : colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}
