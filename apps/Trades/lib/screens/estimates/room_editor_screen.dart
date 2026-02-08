// ZAFTO Room Editor Screen — Design System v2.6
// Sprint D8c (Session 86)
// Editing one area: dimensions form, line items list, add items.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/estimate.dart';
import '../../services/estimate_engine_service.dart';
import 'line_item_picker_screen.dart';

class RoomEditorScreen extends ConsumerStatefulWidget {
  final String estimateId;
  final EstimateArea area;

  const RoomEditorScreen({
    super.key,
    required this.estimateId,
    required this.area,
  });

  @override
  ConsumerState<RoomEditorScreen> createState() => _RoomEditorScreenState();
}

class _RoomEditorScreenState extends ConsumerState<RoomEditorScreen> {
  late EstimateArea _area;
  List<EstimateLineItem> _lineItems = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _dimensionsExpanded = true;

  // Dimension controllers
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _windowsController = TextEditingController();
  final _doorsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _area = widget.area;
    _populateFields();
    _loadLineItems();
  }

  void _populateFields() {
    _nameController.text = _area.name;
    _lengthController.text = _area.lengthFt?.toStringAsFixed(1) ?? '';
    _widthController.text = _area.widthFt?.toStringAsFixed(1) ?? '';
    _heightController.text = (_area.heightFt ?? 8).toStringAsFixed(1);
    _windowsController.text = _area.windowCount.toString();
    _doorsController.text = _area.doorCount.toString();
    _notesController.text = _area.notes ?? '';
  }

  Future<void> _loadLineItems() async {
    try {
      final service = ref.read(estimateEngineServiceProvider);
      final items = await service.getLineItems(widget.estimateId);
      setState(() {
        _lineItems = items.where((li) => li.areaId == _area.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _windowsController.dispose();
    _doorsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final areaTotal = _lineItems.fold<double>(0.0, (sum, li) => sum + li.lineTotal);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: _saveAndGoBack,
        ),
        title: Text(_area.name, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _saveArea(),
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 20, color: colors.accentError),
            onPressed: () => _deleteArea(colors),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name
                        _buildTextField(colors, 'Room Name', _nameController, 'Room name', LucideIcons.home),
                        const SizedBox(height: 16),
                        // Dimensions section
                        _buildDimensionsSection(colors),
                        const SizedBox(height: 16),
                        // Computed measurements
                        _buildMeasurements(colors),
                        const SizedBox(height: 24),
                        // Line items
                        _buildSectionHeader(colors, 'Line Items', '${_lineItems.length}'),
                        const SizedBox(height: 8),
                        if (_lineItems.isEmpty)
                          _buildEmptyItems(colors)
                        else
                          ..._lineItems.map((item) => _buildLineItemCard(colors, item)),
                        const SizedBox(height: 12),
                        _buildAddItemButton(colors),
                        const SizedBox(height: 16),
                        // Notes
                        _buildTextField(colors, 'Room Notes', _notesController, 'Notes specific to this room...', null, maxLines: 2),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
          // Bottom totals bar
          _buildTotalsBar(colors, areaTotal),
        ],
      ),
    );
  }

  Widget _buildDimensionsSection(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _dimensionsExpanded = !_dimensionsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(LucideIcons.ruler, size: 18, color: colors.accentPrimary),
                  const SizedBox(width: 10),
                  Text('Dimensions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  const Spacer(),
                  Icon(
                    _dimensionsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18, color: colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_dimensionsExpanded) ...[
            Divider(height: 1, color: colors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDimField(colors, 'Length (ft)', _lengthController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDimField(colors, 'Width (ft)', _widthController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDimField(colors, 'Height (ft)', _heightController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDimField(colors, 'Windows', _windowsController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDimField(colors, 'Doors', _doorsController)),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurements(ZaftoColors colors) {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;
    final area = length * width;
    final perimeter = (length > 0 && width > 0) ? 2 * (length + width) : 0.0;
    final wallArea = perimeter * height;

    if (area <= 0 && perimeter <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          if (area > 0) ...[
            _buildMeasureItem(colors, '${area.toStringAsFixed(0)} SF', 'Floor'),
            _buildMeasureDivider(colors),
          ],
          if (perimeter > 0) ...[
            _buildMeasureItem(colors, '${perimeter.toStringAsFixed(0)} LF', 'Perimeter'),
            _buildMeasureDivider(colors),
          ],
          if (wallArea > 0)
            _buildMeasureItem(colors, '${wallArea.toStringAsFixed(0)} SF', 'Wall Area'),
        ],
      ),
    );
  }

  Widget _buildMeasureItem(ZaftoColors colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.accentPrimary)),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildMeasureDivider(ZaftoColors colors) {
    return Container(width: 1, height: 28, color: colors.accentPrimary.withValues(alpha: 0.2));
  }

  Widget _buildLineItemCard(ZaftoColors colors, EstimateLineItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.accentError,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _deleteLineItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.description, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary))),
                Text('\$${item.lineTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.actionType.label, style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.quantity} ${item.unitCode} x \$${(item.laborRate + item.materialCost + item.equipmentCost).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: colors.textTertiary),
                ),
                if (item.aiSuggested) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.accentPrimary, colors.accentInfo]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('AI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItems(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.listPlus, size: 32, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text('No items in this room', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text('Tap "Add Items" to browse the code database', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () async {
          await _saveArea(silent: true);
          if (!mounted) return;
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => LineItemPickerScreen(
              estimateId: widget.estimateId,
              areaId: _area.id,
              areaName: _area.name,
            ),
          ));
          _loadLineItems();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text('Add Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.accentPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsBar(ZaftoColors colors, double areaTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Room Total', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                Text('\$${areaTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
            const SizedBox(width: 12),
            Text('${_lineItems.length} items', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveArea(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
                  : const Text('Save Room', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title, String count) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.fillDefault,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textTertiary)),
        ),
      ],
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

  Widget _buildDimField(ZaftoColors colors, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.fillDefault,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndGoBack() async {
    await _saveArea(silent: true);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveArea({bool silent = false}) async {
    setState(() => _isSaving = true);
    if (!silent) HapticFeedback.mediumImpact();

    final updated = _area.copyWith(
      name: _nameController.text.trim(),
      lengthFt: double.tryParse(_lengthController.text),
      widthFt: double.tryParse(_widthController.text),
      heightFt: double.tryParse(_heightController.text) ?? 8,
      windowCount: int.tryParse(_windowsController.text) ?? 0,
      doorCount: int.tryParse(_doorsController.text) ?? 0,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    // Compute area and perimeter
    final length = updated.lengthFt ?? 0;
    final width = updated.widthFt ?? 0;
    final computedArea = (length > 0 && width > 0) ? length * width : null;
    final computedPerimeter = (length > 0 && width > 0) ? 2 * (length + width) : null;
    final withComputed = updated.copyWith(
      areaSf: computedArea,
      perimeterFt: computedPerimeter,
    );

    try {
      final service = ref.read(estimateEngineServiceProvider);
      final saved = await service.updateArea(withComputed);
      setState(() {
        _area = saved;
        _isSaving = false;
      });
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Room saved'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _deleteLineItem(EstimateLineItem item) async {
    try {
      final service = ref.read(estimateEngineServiceProvider);
      await service.deleteLineItem(item.id);
      setState(() {
        _lineItems.removeWhere((li) => li.id == item.id);
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
      _loadLineItems();
    }
  }

  Future<void> _deleteArea(ZaftoColors colors) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Delete Room?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'This will delete "${_area.name}" and all its line items. This cannot be undone.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: colors.accentError)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(estimateEngineServiceProvider);
      await service.deleteArea(_area.id);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}
