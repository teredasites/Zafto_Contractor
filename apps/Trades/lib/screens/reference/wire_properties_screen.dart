/// Wire Properties - Design System v2.6
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class WirePropertiesScreen extends ConsumerStatefulWidget {
  const WirePropertiesScreen({super.key});
  @override
  ConsumerState<WirePropertiesScreen> createState() => _WirePropertiesScreenState();
}

class _WirePropertiesScreenState extends ConsumerState<WirePropertiesScreen> {
  String _material = 'Copper';

  static const List<_WireProperty> _copperData = [
    _WireProperty(size: '18', area: 1620, strands: 1, diameter: 0.040, dcResist: 7.77),
    _WireProperty(size: '16', area: 2580, strands: 1, diameter: 0.051, dcResist: 4.89),
    _WireProperty(size: '14', area: 4110, strands: 1, diameter: 0.064, dcResist: 3.07),
    _WireProperty(size: '12', area: 6530, strands: 1, diameter: 0.081, dcResist: 1.93),
    _WireProperty(size: '10', area: 10380, strands: 1, diameter: 0.102, dcResist: 1.21),
    _WireProperty(size: '8', area: 16510, strands: 1, diameter: 0.128, dcResist: 0.764),
    _WireProperty(size: '6', area: 26240, strands: 7, diameter: 0.184, dcResist: 0.491),
    _WireProperty(size: '4', area: 41740, strands: 7, diameter: 0.232, dcResist: 0.308),
    _WireProperty(size: '3', area: 52620, strands: 7, diameter: 0.260, dcResist: 0.245),
    _WireProperty(size: '2', area: 66360, strands: 7, diameter: 0.292, dcResist: 0.194),
    _WireProperty(size: '1', area: 83690, strands: 19, diameter: 0.332, dcResist: 0.154),
    _WireProperty(size: '1/0', area: 105600, strands: 19, diameter: 0.373, dcResist: 0.122),
    _WireProperty(size: '2/0', area: 133100, strands: 19, diameter: 0.419, dcResist: 0.0967),
    _WireProperty(size: '3/0', area: 167800, strands: 19, diameter: 0.470, dcResist: 0.0766),
    _WireProperty(size: '4/0', area: 211600, strands: 19, diameter: 0.528, dcResist: 0.0608),
    _WireProperty(size: '250', area: 250000, strands: 37, diameter: 0.575, dcResist: 0.0515),
    _WireProperty(size: '300', area: 300000, strands: 37, diameter: 0.630, dcResist: 0.0429),
    _WireProperty(size: '350', area: 350000, strands: 37, diameter: 0.681, dcResist: 0.0367),
    _WireProperty(size: '400', area: 400000, strands: 37, diameter: 0.728, dcResist: 0.0321),
    _WireProperty(size: '500', area: 500000, strands: 37, diameter: 0.813, dcResist: 0.0258),
    _WireProperty(size: '600', area: 600000, strands: 61, diameter: 0.893, dcResist: 0.0214),
    _WireProperty(size: '750', area: 750000, strands: 61, diameter: 0.998, dcResist: 0.0171),
    _WireProperty(size: '1000', area: 1000000, strands: 61, diameter: 1.152, dcResist: 0.0129),
  ];

  static const List<_WireProperty> _aluminumData = [
    _WireProperty(size: '12', area: 6530, strands: 1, diameter: 0.081, dcResist: 3.18),
    _WireProperty(size: '10', area: 10380, strands: 1, diameter: 0.102, dcResist: 2.00),
    _WireProperty(size: '8', area: 16510, strands: 1, diameter: 0.128, dcResist: 1.26),
    _WireProperty(size: '6', area: 26240, strands: 7, diameter: 0.184, dcResist: 0.808),
    _WireProperty(size: '4', area: 41740, strands: 7, diameter: 0.232, dcResist: 0.508),
    _WireProperty(size: '2', area: 66360, strands: 7, diameter: 0.292, dcResist: 0.319),
    _WireProperty(size: '1', area: 83690, strands: 19, diameter: 0.332, dcResist: 0.253),
    _WireProperty(size: '1/0', area: 105600, strands: 19, diameter: 0.373, dcResist: 0.201),
    _WireProperty(size: '2/0', area: 133100, strands: 19, diameter: 0.419, dcResist: 0.159),
    _WireProperty(size: '3/0', area: 167800, strands: 19, diameter: 0.470, dcResist: 0.126),
    _WireProperty(size: '4/0', area: 211600, strands: 19, diameter: 0.528, dcResist: 0.100),
    _WireProperty(size: '250', area: 250000, strands: 37, diameter: 0.575, dcResist: 0.0847),
    _WireProperty(size: '300', area: 300000, strands: 37, diameter: 0.630, dcResist: 0.0707),
    _WireProperty(size: '500', area: 500000, strands: 37, diameter: 0.813, dcResist: 0.0424),
    _WireProperty(size: '750', area: 750000, strands: 61, diameter: 0.998, dcResist: 0.0282),
    _WireProperty(size: '1000', area: 1000000, strands: 61, diameter: 1.152, dcResist: 0.0212),
  ];

  List<_WireProperty> get _currentData => _material == 'Copper' ? _copperData : _aluminumData;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)), title: Text('Wire Properties', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))),
      body: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NEC Chapter 9 Table 8', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.textPrimary)), const SizedBox(height: 4), Text('Conductor properties - DC resistance at 75°C', style: TextStyle(color: colors.textTertiary, fontSize: 12))])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Expanded(child: _MaterialButton(label: 'Copper', isSelected: _material == 'Copper', colors: colors, onTap: () => setState(() => _material = 'Copper'))),
          const SizedBox(width: 8),
          Expanded(child: _MaterialButton(label: 'Aluminum', isSelected: _material == 'Aluminum', colors: colors, onTap: () => setState(() => _material = 'Aluminum'))),
        ])),
        const SizedBox(height: 16),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [_HeaderCell('Size', 2, colors), _HeaderCell('Area', 2, colors), _HeaderCell('Str', 1, colors), _HeaderCell('Ω/kft', 2, colors)])),
        Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)), border: Border.all(color: colors.borderDefault)),
          child: ListView.builder(padding: EdgeInsets.zero, itemCount: _currentData.length, itemBuilder: (context, index) {
            final w = _currentData[index];
            final isEven = index % 2 == 0;
            return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12), decoration: BoxDecoration(color: isEven ? Colors.transparent : colors.bgInset.withValues(alpha: 0.5)),
              child: Row(children: [
                Expanded(flex: 2, child: Text(w.size.contains('/') || int.tryParse(w.size) == null ? w.size : '${w.size} AWG', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary))),
                Expanded(flex: 2, child: Center(child: Text('${w.area}', style: TextStyle(fontSize: 11, color: colors.textSecondary)))),
                Expanded(flex: 1, child: Center(child: Text('${w.strands}', style: TextStyle(fontSize: 11, color: colors.textTertiary)))),
                Expanded(flex: 2, child: Center(child: Text(w.dcResist.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentPrimary)))),
              ]));
          }))),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _WireProperty { final String size; final int area; final int strands; final double diameter; final double dcResist; const _WireProperty({required this.size, required this.area, required this.strands, required this.diameter, required this.dcResist}); }

class _MaterialButton extends StatelessWidget {
  final String label; final bool isSelected; final ZaftoColors colors; final VoidCallback onTap;
  const _MaterialButton({required this.label, required this.isSelected, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderDefault)), child: Center(child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontWeight: FontWeight.w600)))));
}

class _HeaderCell extends StatelessWidget {
  final String text; final int flex; final ZaftoColors colors;
  const _HeaderCell(this.text, this.flex, this.colors);
  @override
  Widget build(BuildContext context) => Expanded(flex: flex, child: Center(child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: colors.textPrimary))));
}
