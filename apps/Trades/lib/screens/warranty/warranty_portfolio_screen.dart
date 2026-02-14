// ZAFTO Warranty Portfolio Screen
// W2: Lists all installed equipment with warranty status indicators.
// Green ≥6mo, Yellow 3-6mo, Red <3mo, Gray = expired/no warranty.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/supabase_client.dart';
import 'warranty_detail_screen.dart';

// Semantic warranty status colors (matches ZaftoColors tokens)
const _kError = Color(0xFFEF4444);
const _kWarning = Color(0xFFF59E0B);
const _kSuccess = Color(0xFF22C55E);

class WarrantyPortfolioScreen extends ConsumerStatefulWidget {
  const WarrantyPortfolioScreen({super.key});

  @override
  ConsumerState<WarrantyPortfolioScreen> createState() =>
      _WarrantyPortfolioScreenState();
}

class _WarrantyPortfolioScreenState
    extends ConsumerState<WarrantyPortfolioScreen> {
  List<Map<String, dynamic>> _equipment = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // all, expiring_soon, expired, active

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await supabase
          .from('home_equipment')
          .select(
              'id, name, manufacturer, model_number, serial_number, warranty_start_date, warranty_end_date, warranty_type, warranty_provider, recall_status, customer_id, customers(name)')
          .order('warranty_end_date', ascending: true);

      if (mounted) {
        setState(() {
          _equipment = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredEquipment {
    final now = DateTime.now();
    switch (_filter) {
      case 'expiring_soon':
        return _equipment.where((e) {
          final end = e['warranty_end_date'] as String?;
          if (end == null) return false;
          final expiry = DateTime.parse(end);
          final daysLeft = expiry.difference(now).inDays;
          return daysLeft >= 0 && daysLeft <= 90;
        }).toList();
      case 'expired':
        return _equipment.where((e) {
          final end = e['warranty_end_date'] as String?;
          if (end == null) return true;
          return DateTime.parse(end).isBefore(now);
        }).toList();
      case 'active':
        return _equipment.where((e) {
          final end = e['warranty_end_date'] as String?;
          if (end == null) return false;
          return DateTime.parse(end).isAfter(now);
        }).toList();
      default:
        return _equipment;
    }
  }

  Color _warrantyColor(String? endDate) {
    if (endDate == null) return Colors.grey;
    final now = DateTime.now();
    final expiry = DateTime.parse(endDate);
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft < 0) return Colors.grey;
    if (daysLeft < 90) return _kError;
    if (daysLeft < 180) return _kWarning;
    return _kSuccess;
  }

  String _warrantyLabel(String? endDate) {
    if (endDate == null) return 'No Warranty';
    final now = DateTime.now();
    final expiry = DateTime.parse(endDate);
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Expires Today';
    if (daysLeft <= 30) return '$daysLeft days left';
    final months = (daysLeft / 30).round();
    return '$months mo left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadEquipment,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle,
                  size: 48, color: _kError),
              const SizedBox(height: 12),
              Text('Failed to load equipment',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadEquipment, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (_equipment.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shield, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No Equipment Found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Equipment logged during jobs will appear here.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    // Data state
    final filtered = _filteredEquipment;
    final expiringSoonCount = _equipment.where((e) {
      final end = e['warranty_end_date'] as String?;
      if (end == null) return false;
      final days = DateTime.parse(end).difference(DateTime.now()).inDays;
      return days >= 0 && days <= 90;
    }).length;

    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _statChip('Total', _equipment.length.toString(), Colors.blue),
              const SizedBox(width: 12),
              _statChip(
                  'Active',
                  _equipment
                      .where((e) =>
                          e['warranty_end_date'] != null &&
                          DateTime.parse(e['warranty_end_date'] as String)
                              .isAfter(DateTime.now()))
                      .length
                      .toString(),
                  _kSuccess),
              const SizedBox(width: 12),
              _statChip('Expiring', expiringSoonCount.toString(),
                  _kWarning),
            ],
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip('All', 'all'),
              const SizedBox(width: 8),
              _filterChip('Active', 'active'),
              const SizedBox(width: 8),
              _filterChip('Expiring', 'expiring_soon'),
              const SizedBox(width: 8),
              _filterChip('Expired', 'expired'),
            ],
          ),
        ),

        // Equipment list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No equipment matches filter',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _loadEquipment,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _equipmentCard(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _equipmentCard(Map<String, dynamic> equipment) {
    final warrantyEnd = equipment['warranty_end_date'] as String?;
    final color = _warrantyColor(warrantyEnd);
    final label = _warrantyLabel(warrantyEnd);
    final customer = equipment['customers'] as Map<String, dynamic>?;
    final hasRecall = equipment['recall_status'] != null &&
        equipment['recall_status'] != 'none';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WarrantyDetailScreen(
                equipmentId: equipment['id'] as String,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Warranty status indicator
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Equipment info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (equipment['name'] as String?) ?? 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (hasRecall)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kError.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.alertTriangle,
                                    size: 12, color: _kError),
                                const SizedBox(width: 2),
                                Text('RECALL',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _kError)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        equipment['manufacturer'],
                        equipment['model_number'],
                      ].where((s) => s != null).join(' — '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    if (customer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer['name'] as String? ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),

              // Warranty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
