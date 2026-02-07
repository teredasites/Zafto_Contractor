// ZAFTO Claims Hub Screen — List all insurance claims with status filters.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/insurance_claim.dart';
import '../../services/insurance_claim_service.dart';
import '../../widgets/error_widgets.dart';
import 'claim_detail_screen.dart';
import 'claim_create_screen.dart';

class ClaimsHubScreen extends ConsumerStatefulWidget {
  const ClaimsHubScreen({super.key});

  @override
  ConsumerState<ClaimsHubScreen> createState() => _ClaimsHubScreenState();
}

class _ClaimsHubScreenState extends ConsumerState<ClaimsHubScreen> {
  ClaimStatus? _filterStatus;
  ClaimCategory? _filterCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(insuranceClaimsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Insurance Claims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClaimCreateScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search claims, carriers...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(null, 'All', isDark),
                _buildFilterChip(ClaimStatus.newClaim, 'New', isDark),
                _buildFilterChip(ClaimStatus.estimatePending, 'Estimate', isDark),
                _buildFilterChip(ClaimStatus.workInProgress, 'In Progress', isDark),
                _buildFilterChip(ClaimStatus.workComplete, 'Complete', isDark),
                _buildFilterChip(ClaimStatus.settled, 'Settled', isDark),
                _buildFilterChip(ClaimStatus.denied, 'Denied', isDark),
              ],
            ),
          ),
          // Category filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, 'All Types', isDark),
                ...ClaimCategory.values.map((cat) => _buildCategoryChip(cat, cat.label, isDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Claims list
          Expanded(
            child: claimsAsync.when(
              loading: () => const ZaftoLoadingState(message: 'Loading claims...'),
              error: (e, _) => ZaftoEmptyState(
                icon: LucideIcons.alertTriangle,
                title: 'Error loading claims',
                subtitle: e.toString(),
              ),
              data: (claims) {
                var filtered = claims;
                if (_filterStatus != null) {
                  filtered = filtered.where((c) => c.claimStatus == _filterStatus).toList();
                }
                if (_filterCategory != null) {
                  filtered = filtered.where((c) => c.claimCategory == _filterCategory).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered.where((c) =>
                      c.claimNumber.toLowerCase().contains(q) ||
                      c.insuranceCompany.toLowerCase().contains(q)).toList();
                }
                if (filtered.isEmpty) {
                  return ZaftoEmptyState(
                    icon: LucideIcons.shield,
                    title: 'No insurance claims',
                    subtitle: 'Create an insurance job to start tracking claims',
                    actionLabel: 'New Claim',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClaimCreateScreen())),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildClaimCard(filtered[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ClaimStatus? status, String label, bool isDark) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ClaimCategory? category, String label, bool isDark) {
    final isSelected = _filterCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(InsuranceClaim claim, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClaimDetailScreen(claimId: claim.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.shield, size: 16, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          claim.insuranceCompany,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(claim.claimStatus),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (claim.claimCategory != ClaimCategory.restoration) ...[
                        _buildCategoryBadge(claim.claimCategory),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          '${claim.claimNumber} · ${claim.lossType.label}',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black45),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (claim.approvedAmount != null) ...[
              const SizedBox(width: 8),
              Text(
                '\$${claim.approvedAmount!.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
              ),
            ],
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(ClaimCategory category) {
    Color color;
    switch (category) {
      case ClaimCategory.storm:
        color = const Color(0xFF8B5CF6);
        break;
      case ClaimCategory.reconstruction:
        color = const Color(0xFFF97316);
        break;
      case ClaimCategory.commercial:
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF3B82F6);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(category.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStatusBadge(ClaimStatus status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case ClaimStatus.newClaim:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1D4ED8);
        break;
      case ClaimStatus.workInProgress:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1D4ED8);
        break;
      case ClaimStatus.settled:
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case ClaimStatus.denied:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      case ClaimStatus.closed:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
      default:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
