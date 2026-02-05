import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Warranty Expiration Calculator - Track vehicle warranty status
class WarrantyExpirationScreen extends ConsumerStatefulWidget {
  const WarrantyExpirationScreen({super.key});
  @override
  ConsumerState<WarrantyExpirationScreen> createState() => _WarrantyExpirationScreenState();
}

class _WarrantyExpirationScreenState extends ConsumerState<WarrantyExpirationScreen> {
  final _purchaseDateController = TextEditingController();
  final _currentMileageController = TextEditingController();
  final _warrantyYearsController = TextEditingController();
  final _warrantyMilesController = TextEditingController();

  String? _status;
  int? _daysRemaining;
  int? _milesRemaining;

  void _calculate() {
    final currentMileage = int.tryParse(_currentMileageController.text);
    final warrantyYears = int.tryParse(_warrantyYearsController.text);
    final warrantyMiles = int.tryParse(_warrantyMilesController.text);

    if (currentMileage == null || warrantyYears == null || warrantyMiles == null) {
      setState(() { _status = null; });
      return;
    }

    // Parse purchase date (MM/DD/YYYY or similar)
    DateTime? purchaseDate;
    final dateText = _purchaseDateController.text.trim();
    if (dateText.isNotEmpty) {
      final parts = dateText.split(RegExp(r'[/\-.]'));
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          purchaseDate = DateTime(year, month, day);
        }
      }
    }

    final now = DateTime.now();
    int? daysRemaining;
    if (purchaseDate != null) {
      final expirationDate = DateTime(purchaseDate.year + warrantyYears, purchaseDate.month, purchaseDate.day);
      daysRemaining = expirationDate.difference(now).inDays;
    }

    final milesRemaining = warrantyMiles - currentMileage;

    String status;
    if (daysRemaining != null && daysRemaining < 0 || milesRemaining < 0) {
      status = 'WARRANTY EXPIRED';
    } else if (daysRemaining != null && daysRemaining < 90 || milesRemaining < 3000) {
      status = 'WARRANTY EXPIRING SOON';
    } else {
      status = 'WARRANTY ACTIVE';
    }

    setState(() {
      _status = status;
      _daysRemaining = daysRemaining;
      _milesRemaining = milesRemaining;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _purchaseDateController.clear();
    _currentMileageController.clear();
    _warrantyYearsController.clear();
    _warrantyMilesController.clear();
    setState(() { _status = null; });
  }

  @override
  void dispose() {
    _purchaseDateController.dispose();
    _currentMileageController.dispose();
    _warrantyYearsController.dispose();
    _warrantyMilesController.dispose();
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
        title: Text('Warranty Status', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Purchase Date', unit: '', hint: 'MM/DD/YYYY', controller: _purchaseDateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Mileage', unit: 'mi', hint: 'Odometer', controller: _currentMileageController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Warranty Years', unit: 'yrs', hint: '3, 5, 10', controller: _warrantyYearsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Warranty Miles', unit: 'mi', hint: '36000', controller: _warrantyMilesController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_status != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildCommonWarranties(colors),
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
        Icon(LucideIcons.shieldCheck, color: colors.accentPrimary, size: 32),
        const SizedBox(height: 8),
        Text('Track warranty expiration by time OR mileage (whichever comes first)', style: TextStyle(color: colors.textTertiary, fontSize: 13), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_status == 'WARRANTY ACTIVE') {
      statusColor = colors.accentSuccess;
    } else if (_status == 'WARRANTY EXPIRING SOON') {
      statusColor = colors.warning;
    } else {
      statusColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          if (_daysRemaining != null) Expanded(child: _buildStatBox(colors, 'Days Left', _daysRemaining! > 0 ? '${_daysRemaining!}' : 'Expired', statusColor)),
          if (_daysRemaining != null && _milesRemaining != null) const SizedBox(width: 12),
          if (_milesRemaining != null) Expanded(child: _buildStatBox(colors, 'Miles Left', _milesRemaining! > 0 ? '${_milesRemaining!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}' : 'Expired', statusColor)),
        ]),
      ]),
    );
  }

  Widget _buildStatBox(ZaftoColors colors, String label, String value, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildCommonWarranties(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON WARRANTIES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildWarrantyRow(colors, 'Basic/Bumper-to-Bumper', '3yr/36k mi'),
        _buildWarrantyRow(colors, 'Powertrain', '5yr/60k mi'),
        _buildWarrantyRow(colors, 'Hyundai/Kia Powertrain', '10yr/100k mi'),
        _buildWarrantyRow(colors, 'EV Battery', '8yr/100k mi'),
        _buildWarrantyRow(colors, 'Corrosion/Rust', '5-12 years'),
        const SizedBox(height: 8),
        Text('Extended warranties and CPO coverage vary', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildWarrantyRow(ZaftoColors colors, String type, String coverage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(coverage, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
