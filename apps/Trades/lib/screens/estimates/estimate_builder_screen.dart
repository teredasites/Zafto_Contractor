// ZAFTO Estimate Builder Screen — Design System v2.6
// Sprint D8c (Session 86)
// Room-by-room estimate editor. Create/edit estimates with areas, line items,
// O&P settings, insurance toggle. The main workspace for field estimating.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/estimate.dart';
import '../../services/estimate_engine_service.dart';
import 'room_editor_screen.dart';
import 'estimate_preview_screen.dart';
import 'line_item_picker_screen.dart';

class EstimateBuilderScreen extends ConsumerStatefulWidget {
  final String? estimateId;
  final EstimateType? estimateType;

  const EstimateBuilderScreen({super.key, this.estimateId, this.estimateType});

  @override
  ConsumerState<EstimateBuilderScreen> createState() => _EstimateBuilderScreenState();
}

class _EstimateBuilderScreenState extends ConsumerState<EstimateBuilderScreen> {
  Estimate? _estimate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isNewEstimate = false;

  // Header controllers
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();

  // Insurance controllers
  final _claimController = TextEditingController();
  final _policyController = TextEditingController();
  final _carrierController = TextEditingController();
  final _adjusterNameController = TextEditingController();
  final _adjusterEmailController = TextEditingController();
  final _adjusterPhoneController = TextEditingController();
  final _deductibleController = TextEditingController();

  // Settings
  double _overheadPct = 10;
  double _profitPct = 10;
  double _taxPct = 0;
  EstimateType _type = EstimateType.regular;
  DateTime? _dateOfLoss;

  @override
  void initState() {
    super.initState();
    if (widget.estimateId != null) {
      _loadEstimate(widget.estimateId!);
    } else {
      _isNewEstimate = true;
      _type = widget.estimateType ?? EstimateType.regular;
      _createNewEstimate();
    }
  }

  Future<void> _loadEstimate(String id) async {
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final estimate = await service.getEstimate(id);
      if (estimate != null) {
        _populateFields(estimate);
      }
      setState(() {
        _estimate = estimate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewEstimate() async {
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final number = await service.generateEstimateNumber();
      final now = DateTime.now();
      final estimate = Estimate(
        estimateNumber: number,
        estimateType: _type,
        overheadPct: _overheadPct,
        profitPct: _profitPct,
        taxPct: _taxPct,
        createdAt: now,
        updatedAt: now,
      );
      final created = await service.createEstimate(estimate);
      _populateFields(created);
      setState(() {
        _estimate = created;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Estimate e) {
    _titleController.text = e.title ?? '';
    _addressController.text = e.propertyAddress ?? '';
    _cityController.text = e.propertyCity ?? '';
    _stateController.text = e.propertyState ?? '';
    _zipController.text = e.propertyZip ?? '';
    _notesController.text = e.notes ?? '';
    _overheadPct = e.overheadPct;
    _profitPct = e.profitPct;
    _taxPct = e.taxPct;
    _type = e.estimateType;
    _dateOfLoss = e.dateOfLoss;
    // Insurance fields
    _claimController.text = e.claimNumber ?? '';
    _policyController.text = e.policyNumber ?? '';
    _carrierController.text = e.insuranceCarrier ?? '';
    _adjusterNameController.text = e.adjusterName ?? '';
    _adjusterEmailController.text = e.adjusterEmail ?? '';
    _adjusterPhoneController.text = e.adjusterPhone ?? '';
    _deductibleController.text = e.deductible?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    _claimController.dispose();
    _policyController.dispose();
    _carrierController.dispose();
    _adjusterNameController.dispose();
    _adjusterEmailController.dispose();
    _adjusterPhoneController.dispose();
    _deductibleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      );
    }

    final estimate = _estimate;
    if (estimate == null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: Text('Failed to load estimate', style: TextStyle(color: colors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: _saveAndGoBack,
        ),
        title: Text(
          _isNewEstimate ? 'New Estimate' : 'Edit Estimate',
          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _saveEstimate(),
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
          IconButton(
            icon: Icon(LucideIcons.eye, color: colors.textSecondary),
            onPressed: () => _saveAndPreview(estimate.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            _buildTypeToggle(colors),
            const SizedBox(height: 16),
            // Header info
            _buildSectionHeader(colors, 'Estimate Details'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Title', _titleController, 'e.g. Kitchen Water Damage Repair', LucideIcons.fileText),
            const SizedBox(height: 12),
            // Property address
            _buildSectionHeader(colors, 'Property Address'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Street', _addressController, '123 Main St', LucideIcons.mapPin),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 3, child: _buildTextField(colors, 'City', _cityController, 'City', null)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildTextField(colors, 'State', _stateController, 'ST', null)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTextField(colors, 'ZIP', _zipController, '12345', null)),
              ],
            ),
            const SizedBox(height: 16),
            // Insurance fields
            if (_type == EstimateType.insurance) ...[
              _buildInsuranceFields(colors),
              const SizedBox(height: 16),
            ],
            // O&P settings
            _buildSectionHeader(colors, 'Markup & Tax'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildPercentField(colors, 'O/H %', _overheadPct, (v) => setState(() => _overheadPct = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildPercentField(colors, 'Profit %', _profitPct, (v) => setState(() => _profitPct = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildPercentField(colors, 'Tax %', _taxPct, (v) => setState(() => _taxPct = v))),
              ],
            ),
            const SizedBox(height: 24),
            // Rooms / Areas
            _buildSectionHeader(colors, 'Rooms / Areas'),
            const SizedBox(height: 8),
            _buildAreasList(colors, estimate),
            const SizedBox(height: 12),
            _buildAddAreaButton(colors, estimate),
            const SizedBox(height: 24),
            // Notes
            _buildSectionHeader(colors, 'Notes'),
            const SizedBox(height: 8),
            _buildTextField(colors, 'Notes', _notesController, 'Additional notes for this estimate...', null, maxLines: 3),
            const SizedBox(height: 24),
            // Totals
            _buildTotalsCard(colors, estimate),
            const SizedBox(height: 24),
            // Preview button
            _buildPreviewButton(colors, estimate),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTypeTab(colors, 'Regular', EstimateType.regular, LucideIcons.fileText)),
          Expanded(child: _buildTypeTab(colors, 'Insurance', EstimateType.insurance, LucideIcons.shield)),
        ],
      ),
    );
  }

  Widget _buildTypeTab(ZaftoColors colors, String label, EstimateType type, IconData icon) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _type = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? colors.accentPrimary : colors.textTertiary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? colors.textPrimary : colors.textTertiary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceFields(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, size: 16, color: colors.accentInfo),
              const SizedBox(width: 8),
              Text('Insurance Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentInfo)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(colors, 'Claim #', _claimController, 'CLM-12345', null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(colors, 'Policy #', _policyController, 'POL-67890', null)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(colors, 'Insurance Carrier', _carrierController, 'e.g. State Farm', null),
          const SizedBox(height: 12),
          _buildTextField(colors, 'Adjuster Name', _adjusterNameController, 'John Smith', null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(colors, 'Adjuster Email', _adjusterEmailController, 'email@carrier.com', null)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(colors, 'Adjuster Phone', _adjusterPhoneController, '(555) 123-4567', null)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(colors, 'Deductible', _deductibleController, '1000.00', null)),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfLoss ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dateOfLoss = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 16, color: colors.textTertiary),
                        const SizedBox(width: 8),
                        Text(
                          _dateOfLoss != null ? '${_dateOfLoss!.month}/${_dateOfLoss!.day}/${_dateOfLoss!.year}' : 'Date of Loss',
                          style: TextStyle(fontSize: 14, color: _dateOfLoss != null ? colors.textPrimary : colors.textQuaternary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreasList(ZaftoColors colors, Estimate estimate) {
    if (estimate.areas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.fillDefault,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.layoutGrid, size: 32, color: colors.textTertiary),
            const SizedBox(height: 8),
            Text('No rooms added yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text('Add rooms to organize line items by area', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
          ],
        ),
      );
    }

    return Column(
      children: estimate.areas.map((area) {
        final areaItems = estimate.lineItems.where((li) => li.areaId == area.id).toList();
        final areaTotal = areaItems.fold<double>(0.0, (sum, li) => sum + li.lineTotal);
        return GestureDetector(
          onTap: () async {
            await _saveEstimate(silent: true);
            if (!mounted) return;
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => RoomEditorScreen(estimateId: estimate.id, area: area),
            ));
            _loadEstimate(estimate.id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.home, size: 18, color: colors.accentPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      Text(
                        '${areaItems.length} item${areaItems.length != 1 ? 's' : ''}${area.calculatedArea > 0 ? "  |  ${area.calculatedArea.toStringAsFixed(0)} SF" : ""}',
                        style: TextStyle(fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Text('\$${areaTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddAreaButton(ZaftoColors colors, Estimate estimate) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showAddAreaSheet(colors, estimate),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 8),
                  Text('Add Room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentPrimary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            await _saveEstimate(silent: true);
            if (!mounted) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => LineItemPickerScreen(estimateId: estimate.id),
            )).then((_) => _loadEstimate(estimate.id));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.listPlus, size: 18, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text('Quick Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(ZaftoColors colors, Estimate estimate) {
    final subtotal = estimate.lineItems.fold<double>(0.0, (sum, li) => sum + li.lineTotal);
    final overhead = subtotal * (_overheadPct / 100);
    final profit = subtotal * (_profitPct / 100);
    final afterMarkup = subtotal + overhead + profit;
    final tax = afterMarkup * (_taxPct / 100);
    final grandTotal = afterMarkup + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildTotalRow(colors, 'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          if (_overheadPct > 0)
            _buildTotalRow(colors, 'Overhead (${_overheadPct.toStringAsFixed(1)}%)', '\$${overhead.toStringAsFixed(2)}'),
          if (_profitPct > 0)
            _buildTotalRow(colors, 'Profit (${_profitPct.toStringAsFixed(1)}%)', '\$${profit.toStringAsFixed(2)}'),
          if (_taxPct > 0)
            _buildTotalRow(colors, 'Tax (${_taxPct.toStringAsFixed(1)}%)', '\$${tax.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _buildTotalRow(colors, 'Grand Total', '\$${grandTotal.toStringAsFixed(2)}', isBold: true),
          Text('${estimate.lineItemCount} line items across ${estimate.areaCount} rooms', style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(ZaftoColors colors, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPreviewButton(ZaftoColors colors, Estimate estimate) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          await _saveEstimate(silent: true);
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => EstimatePreviewScreen(estimateId: estimate.id),
            ));
          }
        },
        icon: const Icon(LucideIcons.eye, size: 18),
        label: const Text('Preview Estimate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
    );
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData? icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: icon != null ? Icon(icon, size: 20, color: colors.textTertiary) : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: icon != null ? 0 : 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPercentField(ZaftoColors colors, String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: TextEditingController(text: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)),
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
            decoration: InputDecoration(
              suffixText: '%',
              suffixStyle: TextStyle(color: colors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAreaSheet(ZaftoColors colors, Estimate estimate) {
    final nameController = TextEditingController();
    int floor = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Add Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const Spacer(),
                  IconButton(icon: Icon(LucideIcons.x, color: colors.textTertiary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Room Name', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Kitchen, Master Bedroom, Garage',
                    hintStyle: TextStyle(color: colors.textQuaternary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Floor', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 0; i <= 3; i++)
                    GestureDetector(
                      onTap: () => setSheetState(() => floor = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: floor == i ? colors.accentPrimary : colors.fillDefault,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          i == 0 ? 'Basement' : 'Floor $i',
                          style: TextStyle(fontSize: 13, color: floor == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Common room presets
              Text('Quick Select', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Kitchen', 'Living Room', 'Master Bedroom', 'Bathroom',
                  'Garage', 'Hallway', 'Dining Room', 'Laundry',
                ].map((name) => GestureDetector(
                  onTap: () => nameController.text = name,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.fillDefault,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(name, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await _addArea(estimate, nameController.text.trim(), floor);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Room', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addArea(Estimate estimate, String name, int floor) async {
    final service = ref.read(estimateEngineServiceProvider);
    final area = EstimateArea(
      estimateId: estimate.id,
      name: name,
      floorNumber: floor,
      sortOrder: estimate.areas.length,
      createdAt: DateTime.now(),
    );
    await service.createArea(area);
    HapticFeedback.mediumImpact();
    _loadEstimate(estimate.id);
  }

  Future<void> _saveAndGoBack() async {
    await _saveEstimate(silent: true);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveAndPreview(String id) async {
    await _saveEstimate(silent: true);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EstimatePreviewScreen(estimateId: id),
      ));
    }
  }

  Future<void> _saveEstimate({bool silent = false}) async {
    final estimate = _estimate;
    if (estimate == null) return;

    setState(() => _isSaving = true);
    if (!silent) HapticFeedback.mediumImpact();

    final updated = estimate.copyWith(
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      propertyAddress: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      propertyCity: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      propertyState: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
      propertyZip: _zipController.text.trim().isNotEmpty ? _zipController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      estimateType: _type,
      overheadPct: _overheadPct,
      profitPct: _profitPct,
      taxPct: _taxPct,
      claimNumber: _claimController.text.trim().isNotEmpty ? _claimController.text.trim() : null,
      policyNumber: _policyController.text.trim().isNotEmpty ? _policyController.text.trim() : null,
      insuranceCarrier: _carrierController.text.trim().isNotEmpty ? _carrierController.text.trim() : null,
      adjusterName: _adjusterNameController.text.trim().isNotEmpty ? _adjusterNameController.text.trim() : null,
      adjusterEmail: _adjusterEmailController.text.trim().isNotEmpty ? _adjusterEmailController.text.trim() : null,
      adjusterPhone: _adjusterPhoneController.text.trim().isNotEmpty ? _adjusterPhoneController.text.trim() : null,
      deductible: double.tryParse(_deductibleController.text),
      dateOfLoss: _dateOfLoss,
    ).recalculate();

    try {
      final service = ref.read(estimateEngineServiceProvider);
      final saved = await service.updateEstimate(updated);
      await ref.read(estimatesProvider.notifier).loadEstimates();
      setState(() {
        _estimate = saved;
        _isSaving = false;
        _isNewEstimate = false;
      });
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Estimate saved'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}
