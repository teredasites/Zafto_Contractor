import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gallons to Liters Converter
class GallonsToLitersScreen extends ConsumerStatefulWidget {
  const GallonsToLitersScreen({super.key});
  @override
  ConsumerState<GallonsToLitersScreen> createState() => _GallonsToLitersScreenState();
}

class _GallonsToLitersScreenState extends ConsumerState<GallonsToLitersScreen> {
  final _gallonsController = TextEditingController();
  final _litersController = TextEditingController();
  bool _fromGallons = true;

  double? _gallons;
  double? _liters;
  double? _cubicMeters;

  void _calculate() {
    if (_fromGallons) {
      final gal = double.tryParse(_gallonsController.text);
      if (gal == null || gal < 0) {
        setState(() { _gallons = null; });
        return;
      }
      setState(() {
        _gallons = gal;
        _liters = gal * 3.78541;
        _cubicMeters = gal * 0.00378541;
      });
    } else {
      final lit = double.tryParse(_litersController.text);
      if (lit == null || lit < 0) {
        setState(() { _liters = null; });
        return;
      }
      setState(() {
        _liters = lit;
        _gallons = lit / 3.78541;
        _cubicMeters = lit / 1000;
      });
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gallonsController.clear();
    _litersController.clear();
    setState(() { _gallons = null; _liters = null; });
  }

  @override
  void dispose() {
    _gallonsController.dispose();
    _litersController.dispose();
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
        title: Text('Volume Converter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildDirectionToggle(colors),
            const SizedBox(height: 16),
            if (_fromGallons)
              ZaftoInputField(label: 'Gallons', unit: 'gal', hint: 'Enter gallons', controller: _gallonsController, onChanged: (_) => _calculate())
            else
              ZaftoInputField(label: 'Liters', unit: 'L', hint: 'Enter liters', controller: _litersController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null && _liters != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildDirectionToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(
        label: const Text('Gallons to Liters'),
        selected: _fromGallons,
        onSelected: (_) => setState(() { _fromGallons = true; _gallonsController.clear(); _litersController.clear(); _gallons = null; }),
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text('Liters to Gallons'),
        selected: !_fromGallons,
        onSelected: (_) => setState(() { _fromGallons = false; _gallonsController.clear(); _litersController.clear(); _liters = null; }),
      ),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('1 Gallon = 3.785 Liters', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('1 Cubic Meter = 264.17 Gallons', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Gallons', '${_gallons!.toStringAsFixed(2)} gal', isPrimary: _fromGallons),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${_liters!.toStringAsFixed(2)} L', isPrimary: !_fromGallons),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cubic Meters', '${_cubicMeters!.toStringAsFixed(4)} m³'),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
