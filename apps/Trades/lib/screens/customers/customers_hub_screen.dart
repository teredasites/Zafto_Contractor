/// Customers Hub Screen - Design System v2.6
/// Sprint 5.0 - January 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/business/customer.dart';
import '../../services/customer_service.dart';
import 'customer_detail_screen.dart';
import 'customer_create_screen.dart';

class CustomersHubScreen extends ConsumerStatefulWidget {
  const CustomersHubScreen({super.key});
  @override
  ConsumerState<CustomersHubScreen> createState() => _CustomersHubScreenState();
}

class _CustomersHubScreenState extends ConsumerState<CustomersHubScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Customers', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
      ),
      body: Column(
        children: [
          _buildSearchBar(colors),
          Expanded(
            child: customersAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
              error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: colors.textSecondary))),
              data: (customers) {
                final filtered = _searchQuery.isEmpty 
                    ? customers 
                    : customers.where((c) => 
                        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (c.companyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                        (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                      ).toList();
                if (filtered.isEmpty) return _buildEmptyState(colors, customers.isEmpty);
                return _buildCustomersList(colors, filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerCreateScreen())),
        backgroundColor: colors.accentPrimary,
        child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.bgInset,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search customers...',
            hintStyle: TextStyle(color: colors.textQuaternary),
            prefixIcon: Icon(LucideIcons.search, size: 20, color: colors.textTertiary),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(LucideIcons.x, size: 18, color: colors.textTertiary),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildCustomersList(ZaftoColors colors, List<Customer> customers) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: customers.length,
      itemBuilder: (context, index) => _buildCustomerCard(colors, customers[index]),
    );
  }

  Widget _buildCustomerCard(ZaftoColors colors, Customer customer) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: customer.id))),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.accentPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  if (customer.companyName != null && customer.companyName!.isNotEmpty)
                    Text(customer.companyName!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Text(customer.phone!, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors, bool noCustomers) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colors.fillDefault, shape: BoxShape.circle),
            child: Icon(noCustomers ? LucideIcons.users : LucideIcons.search, size: 40, color: colors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text(
            noCustomers ? 'No customers yet' : 'No results found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            noCustomers ? 'Tap + to add your first customer' : 'Try a different search term',
            style: TextStyle(fontSize: 14, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
