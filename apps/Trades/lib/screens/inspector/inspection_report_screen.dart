import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/theme_provider.dart';
import 'package:zafto/models/inspection.dart';
import 'package:zafto/services/inspection_service.dart';
import 'package:zafto/core/supabase_client.dart';
import 'package:zafto/widgets/signature_capture_widget.dart';
import 'package:zafto/widgets/inspector/template_picker_sheet.dart';
import 'package:zafto/screens/inspector/inspection_execution_screen.dart';
import 'package:zafto/screens/inspector/create_template_screen.dart';

// ============================================================
// Inspection Report Screen
//
// Post-completion report view. Shows score, result, format
// selection, signature capture, and share/export actions.
// Opens full HTML report via Edge Function in browser for
// print/PDF. Signatures uploaded to Supabase storage.
// ============================================================

class InspectionReportScreen extends ConsumerStatefulWidget {
  final PmInspection inspection;

  const InspectionReportScreen({super.key, required this.inspection});

  @override
  ConsumerState<InspectionReportScreen> createState() =>
      _InspectionReportScreenState();
}

class _InspectionReportScreenState
    extends ConsumerState<InspectionReportScreen> {
  String _format = 'detailed';

  // Signature state
  Uint8List? _inspectorSig;
  Uint8List? _contactSig;
  bool _sigSaving = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final insp = widget.inspection;
    final score = insp.score ?? 0;
    final passed = score >= InspectionService.passThreshold;
    final resultColor = passed ? colors.accentSuccess : colors.accentError;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inspection Report',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── SCORE CARD ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              children: [
                // Score circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resultColor.withValues(alpha: 0.1),
                    border: Border.all(color: resultColor, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: resultColor,
                        ),
                      ),
                      Text(
                        passed ? 'PASS' : 'FAIL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: resultColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _typeLabel(insp.inspectionType),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(insp.completedDate ?? insp.createdAt),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textTertiary,
                  ),
                ),
                if (insp.notes != null && insp.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    insp.notes!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── REPORT FORMAT ──
          Text(
            'REPORT FORMAT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildFormatCards(colors),
          const SizedBox(height: 20),

          // ── SIGNATURES ──
          Text(
            'SIGNATURES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildSignatureCards(colors),
          const SizedBox(height: 20),

          // ── ACTIONS ──
          Text(
            'ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            colors,
            LucideIcons.externalLink,
            'View Full Report',
            'Open in browser for print/PDF',
            colors.accentPrimary,
            _openReport,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            colors,
            LucideIcons.mail,
            'Email Report',
            'Send to stakeholders via email',
            colors.accentPrimary,
            _emailReport,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            colors,
            LucideIcons.copy,
            'Copy Report Link',
            'Copy shareable link to clipboard',
            colors.textSecondary,
            _copyLink,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            colors,
            LucideIcons.filePlus,
            'Save as Template',
            'Reuse this checklist for future inspections',
            colors.accentSuccess,
            _saveAsTemplate,
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            colors,
            LucideIcons.refreshCw,
            'Start Re-Inspection',
            'Re-inspect failed/conditional items',
            Colors.orange,
            _startReinspection,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // FORMAT CARDS
  // ──────────────────────────────────────────────

  Widget _buildFormatCards(ZaftoColors colors) {
    final formats = [
      (
        'summary',
        'Summary',
        'High-level overview for owner/client',
        LucideIcons.fileText,
      ),
      (
        'detailed',
        'Detailed',
        'Full checklist results for contractor',
        LucideIcons.fileCheck,
      ),
      (
        'compliance',
        'Compliance',
        'For municipality/insurance carrier',
        LucideIcons.shield,
      ),
    ];

    return Column(
      children: formats.map((f) {
        final (value, label, desc, icon) = f;
        final isSelected = _format == value;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _format = value);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accentPrimary.withValues(alpha: 0.08)
                  : colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colors.accentPrimary.withValues(alpha: 0.4)
                    : colors.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color:
                        isSelected ? colors.accentPrimary : colors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colors.accentPrimary
                              : colors.textPrimary,
                        ),
                      ),
                      Text(
                        desc,
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colors.accentPrimary
                          : colors.textQuaternary,
                      width: 2,
                    ),
                    color: isSelected
                        ? colors.accentPrimary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────────────────────────────────
  // SIGNATURE CARDS
  // ──────────────────────────────────────────────

  Widget _buildSignatureCards(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildSigCard(
            colors,
            'Inspector',
            widget.inspection.signatureInspector != null || _inspectorSig != null,
            _inspectorSig,
            () => _captureSignature(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSigCard(
            colors,
            'Site Contact',
            widget.inspection.signatureContact != null || _contactSig != null,
            _contactSig,
            () => _captureSignature(false),
          ),
        ),
      ],
    );
  }

  Widget _buildSigCard(
    ZaftoColors colors,
    String label,
    bool signed,
    Uint8List? localSig,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: signed ? null : onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: signed
              ? colors.accentSuccess.withValues(alpha: 0.05)
              : colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: signed
                ? colors.accentSuccess.withValues(alpha: 0.3)
                : colors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  signed ? LucideIcons.checkCircle : LucideIcons.penTool,
                  size: 14,
                  color: signed ? colors.accentSuccess : colors.textQuaternary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: signed ? colors.accentSuccess : colors.textTertiary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (localSig != null)
              SizedBox(
                height: 40,
                child: Image.memory(localSig, fit: BoxFit.contain),
              )
            else if (signed)
              Text(
                'Signed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.accentSuccess,
                ),
              )
            else
              Text(
                'Tap to sign',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textQuaternary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ACTION CARD
  // ──────────────────────────────────────────────

  Widget _buildActionCard(
    ZaftoColors colors,
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────

  String _buildReportUrl() {
    final supabaseUrl = supabase.rest.url.replaceAll('/rest/v1', '');
    return '$supabaseUrl/functions/v1/generate-inspection-report'
        '?inspection_id=${widget.inspection.id}'
        '&format=$_format';
  }

  Future<void> _openReport() async {
    final url = _buildReportUrl();
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  Future<void> _emailReport() async {
    final url = _buildReportUrl();
    final subject = Uri.encodeComponent(
        'Inspection Report — ${_typeLabel(widget.inspection.inspectionType)}');
    final body = Uri.encodeComponent(
        'Please find the inspection report at the link below:\n\n$url');
    final emailUri = Uri.parse('mailto:?subject=$subject&body=$body');
    try {
      await launchUrl(emailUri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    final url = _buildReportUrl();
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report link copied'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAsTemplate() async {
    final insp = widget.inspection;

    // Load the inspection items to build template sections
    var prefillSections = <TemplateSection>[];
    try {
      final items =
          await ref.read(inspectionItemsProvider(insp.id).future);

      // Group items by area (section name)
      final sectionMap = <String, List<TemplateItem>>{};
      for (final item in items) {
        final area = item.area.isNotEmpty ? item.area : 'General';
        sectionMap.putIfAbsent(area, () => []);
        sectionMap[area]!.add(TemplateItem(
          name: item.itemName,
          sortOrder: item.sortOrder,
          weight: 1,
        ));
      }

      var sortIdx = 0;
      for (final entry in sectionMap.entries) {
        prefillSections.add(TemplateSection(
          name: entry.key,
          sortOrder: sortIdx++,
          items: entry.value,
        ));
      }
    } catch (_) {
      // If we can't load items, open empty — inspector can fill manually
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTemplateScreen(
          prefillSections:
              prefillSections.isNotEmpty ? prefillSections : null,
          prefillTrade: insp.trade,
          prefillType: insp.inspectionType,
        ),
      ),
    );
  }

  Future<void> _startReinspection() async {
    // Pick a template (or reuse the original)
    final template = await showTemplatePicker(context);
    if (template == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionExecutionScreen(
          template: template,
          inspectionType: widget.inspection.inspectionType,
          // Link to parent inspection for re-inspection chain
          inspection: PmInspection(
            parentInspectionId: widget.inspection.id,
            inspectionType: widget.inspection.inspectionType,
            trade: widget.inspection.trade,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future<void> _captureSignature(bool isInspector) async {
    final result = await SignatureCaptureDialog.show(
      context,
      title: isInspector ? 'Inspector Signature' : 'Site Contact Signature',
    );

    if (result == null) return;

    setState(() {
      if (isInspector) {
        _inspectorSig = result.image;
      } else {
        _contactSig = result.image;
      }
    });

    // Upload to Supabase
    await _uploadSignature(result, isInspector);
  }

  Future<void> _uploadSignature(
      SignatureResult result, bool isInspector) async {
    setState(() => _sigSaving = true);
    try {
      final bucket = 'signatures';
      final path =
          'inspections/${widget.inspection.id}/${isInspector ? "inspector" : "contact"}.png';

      await supabase.storage.from(bucket).uploadBinary(
            path,
            result.image,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final signedUrl = supabase.storage.from(bucket).getPublicUrl(path);

      final field =
          isInspector ? 'signature_inspector' : 'signature_contact';
      await supabase
          .from('pm_inspections')
          .update({field: signedUrl})
          .eq('id', widget.inspection.id);

      ref.read(inspectionsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save signature: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sigSaving = false);
    }
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _typeLabel(InspectionType type) {
    const labels = <InspectionType, String>{
      InspectionType.moveIn: 'Move-In',
      InspectionType.moveOut: 'Move-Out',
      InspectionType.routine: 'Routine',
      InspectionType.annual: 'Annual',
      InspectionType.maintenance: 'Maintenance',
      InspectionType.safety: 'Safety',
      InspectionType.roughIn: 'Rough-In',
      InspectionType.framing: 'Framing',
      InspectionType.foundation: 'Foundation',
      InspectionType.finalInspection: 'Final',
      InspectionType.permit: 'Permit',
      InspectionType.codeCompliance: 'Code Compliance',
      InspectionType.qcHoldPoint: 'QC Hold Point',
      InspectionType.reInspection: 'Re-Inspection',
      InspectionType.swppp: 'SWPPP',
      InspectionType.environmental: 'Environmental',
      InspectionType.ada: 'ADA',
      InspectionType.insuranceDamage: 'Insurance Damage',
      InspectionType.tpi: 'TPI',
      InspectionType.preConstruction: 'Pre-Construction',
      InspectionType.roofing: 'Roofing',
      InspectionType.fireLifeSafety: 'Fire/Life Safety',
      InspectionType.electrical: 'Electrical',
      InspectionType.plumbing: 'Plumbing',
      InspectionType.hvac: 'HVAC',
    };
    return labels[type] ?? type.name;
  }
}
