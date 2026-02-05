import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// VIN Decoder Calculator - Decode vehicle identification numbers
class VinDecoderScreen extends ConsumerStatefulWidget {
  const VinDecoderScreen({super.key});
  @override
  ConsumerState<VinDecoderScreen> createState() => _VinDecoderScreenState();
}

class _VinDecoderScreenState extends ConsumerState<VinDecoderScreen> {
  final _vinController = TextEditingController();

  Map<String, String>? _decoded;
  String? _error;

  final Map<String, String> _countryPrefixes = {
    '1': 'USA', '2': 'Canada', '3': 'Mexico',
    'J': 'Japan', 'K': 'Korea', 'L': 'China',
    'S': 'UK', 'V': 'France/Spain', 'W': 'Germany',
    'Y': 'Sweden/Finland', 'Z': 'Italy',
  };

  final Map<String, String> _yearCodes = {
    'A': '2010', 'B': '2011', 'C': '2012', 'D': '2013', 'E': '2014',
    'F': '2015', 'G': '2016', 'H': '2017', 'J': '2018', 'K': '2019',
    'L': '2020', 'M': '2021', 'N': '2022', 'P': '2023', 'R': '2024',
    'S': '2025', 'T': '2026', 'V': '2027', 'W': '2028', 'X': '2029',
    'Y': '2030', '1': '2031', '2': '2032', '3': '2033', '4': '2034',
  };

  void _decode() {
    final vin = _vinController.text.toUpperCase().replaceAll(' ', '');

    if (vin.isEmpty) {
      setState(() { _decoded = null; _error = null; });
      return;
    }

    if (vin.length != 17) {
      setState(() { _decoded = null; _error = 'VIN must be 17 characters'; });
      return;
    }

    // Check for invalid characters (I, O, Q not allowed)
    if (vin.contains('I') || vin.contains('O') || vin.contains('Q')) {
      setState(() { _decoded = null; _error = 'Invalid characters (I, O, Q not allowed)'; });
      return;
    }

    // Decode VIN
    final country = _getCountry(vin[0]);
    final year = _getYear(vin[9]);
    final plant = vin[10];
    final serial = vin.substring(11);

    setState(() {
      _error = null;
      _decoded = {
        'WMI (Manufacturer)': vin.substring(0, 3),
        'Country': country,
        'VDS (Description)': vin.substring(3, 9),
        'Check Digit': vin[8],
        'Model Year': year,
        'Plant Code': plant,
        'Serial Number': serial,
      };
    });
  }

  String _getCountry(String code) {
    for (final entry in _countryPrefixes.entries) {
      if (code == entry.key || (entry.key.length == 1 && code.startsWith(entry.key))) {
        return entry.value;
      }
    }
    return 'Unknown';
  }

  String _getYear(String code) {
    return _yearCodes[code] ?? 'Unknown';
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vinController.clear();
    setState(() { _decoded = null; _error = null; });
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('VIN Decoder', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInputCard(colors),
            const SizedBox(height: 24),
            if (_error != null) _buildErrorCard(colors),
            if (_decoded != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildVinStructure(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ENTER VIN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        TextField(
          controller: _vinController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 17,
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontFamily: 'monospace', letterSpacing: 2),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.bgBase,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            hintText: '17 characters',
            hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
            counterStyle: TextStyle(color: colors.textTertiary),
          ),
          onChanged: (_) => _decode(),
        ),
      ]),
    );
  }

  Widget _buildErrorCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.error.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.alertCircle, color: colors.error, size: 20),
        const SizedBox(width: 12),
        Text(_error!, style: TextStyle(color: colors.error, fontSize: 14)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DECODED INFORMATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._decoded!.entries.map((e) => _buildResultRow(colors, e.key, e.value)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _buildVinStructure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VIN STRUCTURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildStructureRow(colors, '1-3', 'World Manufacturer ID (WMI)'),
        _buildStructureRow(colors, '4-8', 'Vehicle Descriptor Section (VDS)'),
        _buildStructureRow(colors, '9', 'Check Digit'),
        _buildStructureRow(colors, '10', 'Model Year'),
        _buildStructureRow(colors, '11', 'Assembly Plant'),
        _buildStructureRow(colors, '12-17', 'Serial Number'),
        const SizedBox(height: 12),
        Text('Note: VDS interpretation varies by manufacturer', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildStructureRow(ZaftoColors colors, String pos, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
          child: Text(pos, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }
}
