/// Credits Purchase Screen - Design System v2.6
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/purchase_service.dart';
import '../../services/ai_service.dart';

class CreditsPurchaseScreen extends ConsumerStatefulWidget {
  const CreditsPurchaseScreen({super.key});
  @override
  ConsumerState<CreditsPurchaseScreen> createState() => _CreditsPurchaseScreenState();
}

class _CreditsPurchaseScreenState extends ConsumerState<CreditsPurchaseScreen> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() { super.initState(); _initialize(); }

  Future<void> _initialize() async {
    purchaseService.onError = (msg) { if (mounted) { setState(() => _isPurchasing = false); _showError(msg); } };
    purchaseService.onPurchaseComplete = (credits) { if (mounted) { setState(() => _isPurchasing = false); _showSuccess(credits); } };
    purchaseService.onPurchasePending = () { if (mounted) setState(() => _isPurchasing = true); };
    purchaseService.onPurchaseRestored = () { if (mounted) { setState(() => _isPurchasing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchases restored'))); } };
    await purchaseService.initialize();
    if (mounted) setState(() { _isLoading = false; if (!purchaseService.isAvailable) _error = 'Purchases not available on this device'; });
  }

  void _showError(String message) {
    final colors = ref.read(zaftoColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccess(int credits) {
    final colors = ref.read(zaftoColorsProvider);
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: colors.bgElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 48)),
        const SizedBox(height: 16),
        Text('Purchase Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 8),
        Text('+$credits scan credits added', style: TextStyle(color: colors.textSecondary)),
      ]),
      actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text('Start Scanning', style: TextStyle(color: colors.accentPrimary)))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Get Credits', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        actions: [TextButton(onPressed: _isPurchasing ? null : () => purchaseService.restorePurchases(), child: Text('Restore', style: TextStyle(color: colors.textSecondary)))]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _error != null ? _buildError(colors) : _buildContent(colors),
    );
  }

  Widget _buildError(ZaftoColors colors) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.alertCircle, color: Colors.red, size: 48), const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary))])));
  }

  Widget _buildContent(ZaftoColors colors) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildCurrentCredits(colors),
      const SizedBox(height: 24),
      Text('CHOOSE A PACKAGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 12),
      ...PurchaseService.packages.map((pkg) => _buildPackageCard(pkg, colors)),
      const SizedBox(height: 24),
      _buildFeaturesList(colors),
      const SizedBox(height: 24),
      _buildDisclaimer(colors),
    ]));
  }

  Widget _buildCurrentCredits(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.accentPrimary.withValues(alpha: 0.2), colors.bgElevated]), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(LucideIcons.zap, color: colors.accentPrimary, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Current Balance', style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text('${aiService.totalCredits} Credits', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary))])),
      ]));
  }

  Widget _buildPackageCard(CreditPackage pkg, ZaftoColors colors) {
    final isBestValue = pkg.productId == 'zafto_credits_50';
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: isBestValue ? colors.accentPrimary : colors.borderDefault, width: isBestValue ? 2 : 1)),
      child: Material(color: Colors.transparent, child: InkWell(onTap: _isPurchasing ? null : () { HapticFeedback.mediumImpact(); purchaseService.purchase(pkg.productId); },
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('${pkg.credits}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.accentPrimary)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(pkg.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)), if (isBestValue) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(4)), child: Text('BEST', style: TextStyle(color: colors.bgBase, fontSize: 9, fontWeight: FontWeight.w700)))]]),
            Text('${pkg.credits} scan credits', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
          ])),
          Text(pkg.price ?? '\$-.-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        ])))));
  }

  Widget _buildFeaturesList(ZaftoColors colors) {
    final features = ['Panel & breaker analysis', 'Nameplate data extraction', 'Wire identification', 'NEC violation scanning', 'Smart auto-detection'];
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What You Can Scan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary)),
        const SizedBox(height: 12),
        ...features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(LucideIcons.check, color: colors.accentSuccess, size: 16), const SizedBox(width: 10), Text(f, style: TextStyle(color: colors.textSecondary, fontSize: 13))]))),
      ]));
  }

  Widget _buildDisclaimer(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
      child: Text('Credits never expire. Prices may vary by region. All purchases are processed securely through your app store.', style: TextStyle(color: colors.textTertiary, fontSize: 11), textAlign: TextAlign.center));
  }
}
