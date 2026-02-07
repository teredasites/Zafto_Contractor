import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/certification.dart';
import '../../services/certification_service.dart';
import '../../services/auth_service.dart';

// Local fallback type labels for when DB types haven't loaded yet.
// Once certificationTypesProvider loads, these are replaced with DB values.
String _getCertTypeLabel(String typeKey, List<CertificationTypeConfig> dbTypes) {
  for (final t in dbTypes) {
    if (t.typeKey == typeKey) return t.displayName;
  }
  // Fallback to enum label if not found in DB
  return CertificationType.fromString(typeKey).label;
}

class CertificationsScreen extends ConsumerStatefulWidget {
  const CertificationsScreen({super.key});

  @override
  ConsumerState<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen> {
  List<Certification> _certifications = [];
  List<CertificationTypeConfig> _certTypes = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, expiring, expired

  @override
  void initState() {
    super.initState();
    _loadCertifications();
  }


  Future<void> _loadCertifications() async {
    try {
      final service = ref.read(certificationServiceProvider);
      final certs = await service.getCertifications();
      if (mounted) {
        setState(() {
          _certifications = certs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Certification> get _filteredCerts {
    switch (_filter) {
      case 'active':
        return _certifications
            .where((c) => c.status == CertificationStatus.active && !c.isExpired)
            .toList();
      case 'expiring':
        return _certifications.where((c) => c.isExpiringSoon).toList();
      case 'expired':
        return _certifications
            .where(
                (c) => c.isExpired || c.status == CertificationStatus.expired)
            .toList();
      default:
        return _certifications;
    }
  }

  int get _expiringCount =>
      _certifications.where((c) => c.isExpiringSoon).length;
  int get _expiredCount =>
      _certifications
          .where(
              (c) => c.isExpired || c.status == CertificationStatus.expired)
          .length;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final certTypesAsync = ref.watch(certificationTypesProvider);
    final dbTypes = certTypesAsync.valueOrNull ?? _certTypes;
    if (dbTypes.isNotEmpty && _certTypes.isEmpty) {
      _certTypes = dbTypes;
    }
    final filtered = _filteredCerts;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Certifications',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: colors.accentPrimary),
            onPressed: () => _showAddCertSheet(colors),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.bgElevated,
            child: Row(
              children: [
                _SummaryChip(
                  label: 'All',
                  count: _certifications.length,
                  isActive: _filter == 'all',
                  color: colors.accentPrimary,
                  onTap: () => setState(() => _filter = 'all'),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Active',
                  count: _certifications
                      .where((c) =>
                          c.status == CertificationStatus.active &&
                          !c.isExpired)
                      .length,
                  isActive: _filter == 'active',
                  color: Colors.green,
                  onTap: () => setState(() => _filter = 'active'),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Expiring',
                  count: _expiringCount,
                  isActive: _filter == 'expiring',
                  color: Colors.orange,
                  onTap: () => setState(() => _filter = 'expiring'),
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Expired',
                  count: _expiredCount,
                  isActive: _filter == 'expired',
                  color: Colors.red,
                  onTap: () => setState(() => _filter = 'expired'),
                  colors: colors,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.award,
                                size: 48,
                                color: colors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              _filter == 'all'
                                  ? 'No certifications yet'
                                  : 'No $_filter certifications',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCertifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final cert = filtered[index];
                            return _CertCard(
                              cert: cert,
                              colors: colors,
                              certTypes: _certTypes,
                              onTap: () => _showCertDetail(cert, colors),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showCertDetail(Certification cert, ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(cert: cert, colors: colors),
                const Spacer(),
                if (cert.daysUntilExpiry != null)
                  Text(
                    cert.daysUntilExpiry! > 0
                        ? '${cert.daysUntilExpiry} days until expiry'
                        : '${-cert.daysUntilExpiry!} days overdue',
                    style: TextStyle(
                      color: cert.isExpired
                          ? Colors.red
                          : cert.isExpiringSoon
                              ? Colors.orange
                              : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(cert.certificationName,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_getCertTypeLabel(cert.certificationTypeValue, _certTypes),
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            if (cert.issuingAuthority != null) ...[
              _DetailRow('Issuing Authority', cert.issuingAuthority!,
                  colors),
            ],
            if (cert.certificationNumber != null) ...[
              _DetailRow('Cert #', cert.certificationNumber!, colors),
            ],
            if (cert.expirationDate != null) ...[
              _DetailRow(
                'Expiration',
                '${cert.expirationDate!.month}/${cert.expirationDate!.day}/${cert.expirationDate!.year}',
                colors,
              ),
            ],
            if (cert.notes != null && cert.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(cert.notes!,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddCertSheet(ZaftoColors colors) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final authorityController = TextEditingController();
    String selectedType = 'other';
    DateTime? expirationDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Certification',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _certTypes.isNotEmpty
                      ? _certTypes
                          .map((t) => DropdownMenuItem(
                              value: t.typeKey,
                              child: Text(t.displayName)))
                          .toList()
                      : CertificationType.values
                          .map((t) => DropdownMenuItem(
                              value: t.dbValue, child: Text(t.label)))
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() => selectedType = v);
                      final dbType = _certTypes.where((t) => t.typeKey == v);
                      if (nameController.text.isEmpty) {
                        nameController.text = dbType.isNotEmpty
                            ? dbType.first.displayName
                            : CertificationType.fromString(v).label;
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Certification Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: InputDecoration(
                    labelText: 'Certification Number',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorityController,
                  decoration: InputDecoration(
                    labelText: 'Issuing Authority',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (date != null) {
                      setSheetState(() => expirationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiration Date',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      suffixIcon:
                          Icon(LucideIcons.calendar, color: colors.textSecondary),
                    ),
                    child: Text(
                      expirationDate != null
                          ? '${expirationDate!.month}/${expirationDate!.day}/${expirationDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                          color: expirationDate != null
                              ? colors.textPrimary
                              : colors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor:
                          colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      try {
                        final service =
                            ref.read(certificationServiceProvider);
                        await service.createCertification(
                          userId: ref
                                  .read(authStateProvider)
                                  .user
                                  ?.uid ??
                              '',
                          certificationTypeValue: selectedType,
                          certificationName: nameController.text,
                          certificationNumber:
                              numberController.text.isNotEmpty
                                  ? numberController.text
                                  : null,
                          issuingAuthority:
                              authorityController.text.isNotEmpty
                                  ? authorityController.text
                                  : null,
                          expirationDate: expirationDate,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _loadCertifications();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Save Certification',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  final ZaftoColors colors;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(30) : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(
                    color: isActive ? color : colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? color : colors.textSecondary,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final Certification cert;
  final ZaftoColors colors;
  final List<CertificationTypeConfig> certTypes;
  final VoidCallback onTap;

  const _CertCard({
    required this.cert,
    required this.colors,
    required this.certTypes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.award,
                  size: 20, color: _statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cert.certificationName,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(_getCertTypeLabel(cert.certificationTypeValue, certTypes),
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            _StatusBadge(cert: cert, colors: colors),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    if (cert.isExpired) return Colors.red;
    if (cert.isExpiringSoon) return Colors.orange;
    return Colors.green;
  }
}

class _StatusBadge extends StatelessWidget {
  final Certification cert;
  final ZaftoColors colors;

  const _StatusBadge({required this.cert, required this.colors});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String text;

    if (cert.isExpired || cert.status == CertificationStatus.expired) {
      badgeColor = Colors.red;
      text = 'Expired';
    } else if (cert.isExpiringSoon) {
      badgeColor = Colors.orange;
      text = 'Expiring';
    } else if (cert.status == CertificationStatus.revoked) {
      badgeColor = Colors.red;
      text = 'Revoked';
    } else {
      badgeColor = Colors.green;
      text = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

Widget _DetailRow(String label, String value, ZaftoColors colors) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style:
                  TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}
