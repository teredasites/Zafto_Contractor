import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/job_material.dart';
import '../../services/job_material_service.dart';

/// Materials Tracker - Track materials, equipment, tools used on a job
class MaterialsTrackerScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const MaterialsTrackerScreen({super.key, this.jobId});

  @override
  ConsumerState<MaterialsTrackerScreen> createState() =>
      _MaterialsTrackerScreenState();
}

class _MaterialsTrackerScreenState
    extends ConsumerState<MaterialsTrackerScreen> {
  List<JobMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    if (widget.jobId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final service = ref.read(jobMaterialServiceProvider);
      final materials = await service.getMaterialsByJob(widget.jobId!);
      if (mounted) setState(() { _materials = materials; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalCost =>
      _materials.fold<double>(0.0, (sum, m) => sum + m.computedTotal);

  double get _billableCost => _materials
      .where((m) => m.isBillable)
      .fold<double>(0.0, (sum, m) => sum + m.computedTotal);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Materials Tracker',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: widget.jobId != null
          ? FloatingActionButton(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              onPressed: () => _showAddMaterialSheet(colors),
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          if (widget.jobId == null) _buildNoJobBanner(colors),
          if (widget.jobId != null && _materials.isNotEmpty)
            _buildCostSummary(colors),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _materials.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildMaterialsList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildNoJobBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Open from a job to track materials',
              style: TextStyle(fontSize: 13, color: colors.accentWarning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Cost',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('\$${_totalCost.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Billable',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('\$${_billableCost.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.accentSuccess)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_materials.length} items',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.package, size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text('No materials tracked',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            widget.jobId != null
                ? 'Tap + to add materials, equipment,\nor tools used on this job'
                : 'Open from a job to start tracking',
            style: TextStyle(
                fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList(ZaftoColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return _buildMaterialCard(colors, material, index);
      },
    );
  }

  Widget _buildMaterialCard(
      ZaftoColors colors, JobMaterial material, int index) {
    final categoryColor = _categoryColor(material.category);

    return Dismissible(
      key: Key(material.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.accentError,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(colors),
      onDismissed: (_) => _deleteMaterial(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(material.category),
                  color: categoryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(material.name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (!material.isBillable)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.fillDefault,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Non-billable',
                              style: TextStyle(
                                  fontSize: 10, color: colors.textTertiary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${material.quantity.toStringAsFixed(material.quantity == material.quantity.roundToDouble() ? 0 : 1)} ${material.unit}',
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                      if (material.unitCost != null) ...[
                        Text(' @ \$${material.unitCost!.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 12, color: colors.textTertiary)),
                      ],
                      if (material.vendor != null &&
                          material.vendor!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(LucideIcons.store, size: 11, color: colors.textTertiary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(material.vendor!,
                              style: TextStyle(
                                  fontSize: 12, color: colors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('\$${material.computedTotal.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD MATERIAL SHEET
  // ============================================================

  void _showAddMaterialSheet(ZaftoColors colors) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCostCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    MaterialCategory selectedCategory = MaterialCategory.material;
    String selectedUnit = 'each';
    bool isBillable = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(LucideIcons.package, color: colors.textPrimary),
                    const SizedBox(width: 12),
                    Text('Add Material',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                _buildTextField(colors, nameCtrl, 'Item Name *',
                    icon: LucideIcons.tag),
                const SizedBox(height: 12),

                // Category chips
                Text('Category',
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MaterialCategory.values.map((cat) {
                    final isSelected = cat == selectedCategory;
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      selectedColor: colors.accentPrimary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? colors.accentPrimary
                            : colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (_) =>
                          setSheetState(() => selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Quantity + Unit + Unit Cost row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(colors, qtyCtrl, 'Qty',
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: TextStyle(
                              fontSize: 13, color: colors.textTertiary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'each', child: Text('each')),
                          DropdownMenuItem(value: 'ft', child: Text('ft')),
                          DropdownMenuItem(value: 'lf', child: Text('lf')),
                          DropdownMenuItem(value: 'sqft', child: Text('sqft')),
                          DropdownMenuItem(value: 'box', child: Text('box')),
                          DropdownMenuItem(value: 'roll', child: Text('roll')),
                          DropdownMenuItem(value: 'gal', child: Text('gal')),
                          DropdownMenuItem(value: 'lb', child: Text('lb')),
                          DropdownMenuItem(value: 'hr', child: Text('hr')),
                          DropdownMenuItem(value: 'day', child: Text('day')),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => selectedUnit = v ?? 'each'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildTextField(colors, unitCostCtrl, 'Unit Cost',
                          keyboardType: TextInputType.number,
                          prefix: '\$ '),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vendor
                _buildTextField(colors, vendorCtrl, 'Vendor (optional)',
                    icon: LucideIcons.store),
                const SizedBox(height: 12),

                // Serial number (show for equipment)
                if (selectedCategory == MaterialCategory.equipment)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTextField(
                        colors, serialCtrl, 'Serial Number (optional)',
                        icon: LucideIcons.hash),
                  ),

                // Notes
                _buildTextField(colors, notesCtrl, 'Notes (optional)',
                    maxLines: 2),
                const SizedBox(height: 12),

                // Billable toggle
                Row(
                  children: [
                    Text('Billable to client',
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary)),
                    const Spacer(),
                    Switch.adaptive(
                      value: isBillable,
                      activeColor: colors.accentPrimary,
                      onChanged: (v) => setSheetState(() => isBillable = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Add Material',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor:
                          colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      _addMaterial(
                        name: nameCtrl.text.trim(),
                        category: selectedCategory,
                        quantity: double.tryParse(qtyCtrl.text) ?? 1,
                        unit: selectedUnit,
                        unitCost: double.tryParse(unitCostCtrl.text),
                        vendor: vendorCtrl.text.trim().isNotEmpty
                            ? vendorCtrl.text.trim()
                            : null,
                        isBillable: isBillable,
                        serialNumber: serialCtrl.text.trim().isNotEmpty
                            ? serialCtrl.text.trim()
                            : null,
                        notes: notesCtrl.text.trim().isNotEmpty
                            ? notesCtrl.text.trim()
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    ZaftoColors colors,
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: colors.textTertiary)
            : null,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _addMaterial({
    required String name,
    required MaterialCategory category,
    required double quantity,
    required String unit,
    double? unitCost,
    String? vendor,
    bool isBillable = true,
    String? serialNumber,
    String? notes,
  }) async {
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(jobMaterialServiceProvider);
      final saved = await service.createMaterial(
        jobId: widget.jobId!,
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        unitCost: unitCost,
        vendor: vendor,
        isBillable: isBillable,
        serialNumber: serialNumber,
        notes: notes,
      );

      if (mounted) {
        setState(() => _materials.insert(0, saved));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add material'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete(ZaftoColors colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete material?'),
            content:
                const Text('This item will be removed from the materials list.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: TextStyle(color: colors.accentError))),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteMaterial(int index) async {
    final material = _materials[index];
    setState(() => _materials.removeAt(index));

    final service = ref.read(jobMaterialServiceProvider);
    service.deleteMaterial(material.id).then((_) {}).catchError((_) {});
  }

  // ============================================================
  // HELPERS
  // ============================================================

  IconData _categoryIcon(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.material:
        return LucideIcons.package;
      case MaterialCategory.equipment:
        return LucideIcons.hardDrive;
      case MaterialCategory.tool:
        return LucideIcons.wrench;
      case MaterialCategory.consumable:
        return LucideIcons.droplet;
      case MaterialCategory.rental:
        return LucideIcons.clock;
    }
  }

  Color _categoryColor(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.material:
        return Colors.blue;
      case MaterialCategory.equipment:
        return Colors.purple;
      case MaterialCategory.tool:
        return Colors.orange;
      case MaterialCategory.consumable:
        return Colors.teal;
      case MaterialCategory.rental:
        return Colors.indigo;
    }
  }
}
