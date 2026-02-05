import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Paint Code Calculator - Find vehicle paint code locations
class PaintCodeScreen extends ConsumerStatefulWidget {
  const PaintCodeScreen({super.key});
  @override
  ConsumerState<PaintCodeScreen> createState() => _PaintCodeScreenState();
}

class _PaintCodeScreenState extends ConsumerState<PaintCodeScreen> {
  String _selectedMake = 'ford';

  final Map<String, Map<String, dynamic>> _paintCodeLocations = {
    'ford': {
      'make': 'Ford / Lincoln / Mercury',
      'locations': ['Driver door jamb sticker', 'Under the hood on strut tower', 'Driver side fender apron'],
      'label': 'Look for "EXT PNT" or color code',
      'example': 'UH, Z1, YZ, M7',
    },
    'gm': {
      'make': 'GM (Chevy, GMC, Cadillac, Buick)',
      'locations': ['Driver door jamb sticker', 'Glove box area', 'Trunk lid (older vehicles)'],
      'label': 'Look for "BC/CC" or "U" code',
      'example': 'WA8555, 8624, GBA',
    },
    'chrysler': {
      'make': 'Chrysler / Dodge / Jeep / Ram',
      'locations': ['Driver door jamb sticker', 'Under the hood (rad support)'],
      'label': 'Look for "PNT" or color code',
      'example': 'PW7, PXR, PAU',
    },
    'toyota': {
      'make': 'Toyota / Lexus / Scion',
      'locations': ['Driver door jamb sticker', 'Engine bay firewall (older)'],
      'label': 'Look for "C/TR" section',
      'example': '040, 1D6, 3R3, 1G3',
    },
    'honda': {
      'make': 'Honda / Acura',
      'locations': ['Driver door jamb sticker', 'Inside driver door pillar'],
      'label': 'Look for "COLOR" line',
      'example': 'NH731P, B92P, R81',
    },
    'nissan': {
      'make': 'Nissan / Infiniti',
      'locations': ['Driver door jamb sticker', 'Under hood firewall'],
      'label': 'Look for color code',
      'example': 'QAB, K23, GAB, RAY',
    },
    'vw': {
      'make': 'VW / Audi / Porsche',
      'locations': ['Spare tire well/trunk floor', 'Service booklet', 'Driver door jamb'],
      'label': 'Look for "L" followed by code',
      'example': 'LA7W, LY7W, L041',
    },
    'bmw': {
      'make': 'BMW / Mini',
      'locations': ['Under the hood strut tower', 'Driver door jamb', 'Trunk lid'],
      'label': '3-digit code',
      'example': '300, 475, A96',
    },
    'mercedes': {
      'make': 'Mercedes-Benz',
      'locations': ['Driver door jamb sticker', 'Under hood radiator support', 'Driver B-pillar'],
      'label': '3-digit code',
      'example': '040, 197, 890',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paint Code Finder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            _buildMakeSelector(colors),
            const SizedBox(height: 24),
            _buildLocationInfo(colors),
            const SizedBox(height: 24),
            _buildGeneralTips(colors),
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
        Icon(LucideIcons.paintBucket, color: colors.accentPrimary, size: 32),
        const SizedBox(height: 8),
        Text('Find your vehicle paint code for touch-up or respray', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildMakeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT MANUFACTURER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _paintCodeLocations.keys.map((key) => _buildMakeChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildMakeChip(ZaftoColors colors, String key) {
    final isSelected = _selectedMake == key;
    final name = key.toUpperCase();
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedMake = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(name, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLocationInfo(ZaftoColors colors) {
    final info = _paintCodeLocations[_selectedMake]!;
    final locations = info['locations'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(info['make'], style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Text('LOCATIONS:', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...locations.map((loc) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(LucideIcons.mapPin, size: 14, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(loc, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ]),
        )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info['label'], style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Examples: ${info['example']}', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontFamily: 'monospace')),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGeneralTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PAINT CODE TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Code is usually on a sticker/plate with VIN', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• May be listed as "EXT", "PNT", "C/TR", or "COLOR"', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• 2-4 character alphanumeric code', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Different from interior trim code', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Verify code matches when ordering paint', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Faded paint may not match new paint exactly', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
