/// Electrician's Tool List - Design System v2.6
/// Comprehensive tool guide for apprentices and journeymen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class ToolListScreen extends ConsumerWidget {
  const ToolListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Electrician\'s Tool List', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEssential(colors),
            const SizedBox(height: 16),
            _buildHandTools(colors),
            const SizedBox(height: 16),
            _buildPowerTools(colors),
            const SizedBox(height: 16),
            _buildTestEquipment(colors),
            const SizedBox(height: 16),
            _buildSafetyGear(colors),
            const SizedBox(height: 16),
            _buildSpecialized(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEssential(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.star, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Day 1 Essentials', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Minimum tools to start work:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 8),
          _toolItem('Non-contact voltage tester', 'NCVT - Klein or Fluke', colors),
          _toolItem('Linesman pliers', '9" - Klein D2000', colors),
          _toolItem('Side cutters (dikes)', '8" diagonal cutters', colors),
          _toolItem('Wire strippers', 'Klein 11055 or similar', colors),
          _toolItem('Screwdrivers', '#2 Phillips, 1/4" & 5/16" flat', colors),
          _toolItem('Tape measure', '25\' with magnetic tip', colors),
          _toolItem('Torpedo level', '9" magnetic', colors),
          _toolItem('Utility knife', 'Retractable blade', colors),
          _toolItem('Electrical tape', 'Super 33+ black', colors),
          _toolItem('Tool pouch', 'Leather or nylon', colors),
        ],
      ),
    );
  }

  Widget _buildHandTools(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hand Tools', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _categoryHeader('Cutting & Stripping', colors),
          _toolItem('Cable cutters', 'For large wire/cable', colors),
          _toolItem('Cable ripper', 'For NM sheath', colors),
          _toolItem('Automatic strippers', 'Ideal/Klein', colors),
          _toolItem('Conduit reamer', 'Deburr cut conduit', colors),
          const SizedBox(height: 10),
          _categoryHeader('Pliers & Gripping', colors),
          _toolItem('Needle nose pliers', '8" long nose', colors),
          _toolItem('Channel locks', '10" & 12" tongue & groove', colors),
          _toolItem('Crimping tool', 'For lugs and terminals', colors),
          _toolItem('Pump pliers', 'Knipex Cobra or similar', colors),
          const SizedBox(height: 10),
          _categoryHeader('Screwdrivers', colors),
          _toolItem('Insulated set', '1000V rated', colors),
          _toolItem('Multi-bit driver', 'Klein 11-in-1', colors),
          _toolItem('Nut drivers', '1/4", 5/16", 3/8", 1/2"', colors),
          _toolItem('Robertson (square)', '#1 and #2', colors),
          _toolItem('Torx set', 'For some devices', colors),
          const SizedBox(height: 10),
          _categoryHeader('Other Hand Tools', colors),
          _toolItem('Hacksaw', 'For conduit/strut', colors),
          _toolItem('Files', 'Flat and round', colors),
          _toolItem('Hammer', '16oz claw', colors),
          _toolItem('Fish tape', '50-100\' steel or fiberglass', colors),
        ],
      ),
    );
  }

  Widget _buildPowerTools(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Power Tools', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _toolItem('Cordless drill/driver', '18V/20V - DeWalt, Milwaukee', colors),
          _toolItem('Impact driver', 'Essential for speed', colors),
          _toolItem('Hammer drill', 'For concrete/masonry', colors),
          _toolItem('Rotary hammer', 'SDS for bigger holes', colors),
          _toolItem('Hole saw kit', '7/8" to 4"', colors),
          _toolItem('Step bits', 'Unibit for knockouts', colors),
          _toolItem('Auger bits', 'For wood boring', colors),
          _toolItem('Reciprocating saw', 'Sawzall for demo', colors),
          _toolItem('Band saw', 'Portable for conduit', colors),
          _toolItem('Angle grinder', '4.5" for cutting/grinding', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 14, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Get drill & impact on same battery platform. Milwaukee M18 or DeWalt 20V are industry standards.', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestEquipment(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test Equipment', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _categoryHeader('Essential Testing', colors),
          _toolItem('Non-contact voltage tester', 'Fluke 1AC-II or Klein', colors),
          _toolItem('Outlet tester', 'Shows wiring faults', colors),
          _toolItem('Digital multimeter', 'Fluke 117 or similar', colors),
          _toolItem('Clamp meter', 'For current measurement', colors),
          const SizedBox(height: 10),
          _categoryHeader('Advanced Testing', colors),
          _toolItem('Megohmmeter (megger)', 'Insulation resistance', colors),
          _toolItem('Circuit tracer', 'Identify circuits', colors),
          _toolItem('Tone generator', 'Trace wires', colors),
          _toolItem('GFCI tester', 'Test GFCI function', colors),
          _toolItem('Rotation meter', '3-phase rotation', colors),
          _toolItem('Low-Z volt meter', 'Ghost voltage detection', colors),
          _toolItem('Thermal imager', 'Find hot spots', colors),
        ],
      ),
    );
  }

  Widget _buildSafetyGear(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: colors.accentError, size: 18),
              const SizedBox(width: 8),
              Text('Safety Equipment', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _toolItem('Safety glasses', 'ANSI Z87.1 rated', colors),
          _toolItem('Hard hat', 'Class E electrical rated', colors),
          _toolItem('Gloves', 'Leather + rubber insulating', colors),
          _toolItem('Hearing protection', 'For power tool use', colors),
          _toolItem('Dust mask / respirator', 'N95 minimum', colors),
          _toolItem('High-vis vest', 'For job site', colors),
          _toolItem('Steel toe boots', 'EH rated', colors),
          _toolItem('Knee pads', 'Gel insert type', colors),
          _toolItem('Voltage rated gloves', 'Class 00 or higher for live work', colors),
          _toolItem('Face shield', 'Arc flash rated if needed', colors),
          _toolItem('First aid kit', 'Job box essential', colors),
          _toolItem('Fire extinguisher', 'ABC rated', colors),
        ],
      ),
    );
  }

  Widget _buildSpecialized(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Specialized Tools', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _categoryHeader('Conduit Work', colors),
          _toolItem('Hand bender', '1/2", 3/4", 1" EMT', colors),
          _toolItem('Hydraulic bender', 'For larger conduit', colors),
          _toolItem('Conduit reamer', 'Deburr cut ends', colors),
          _toolItem('Threading machine', 'For rigid conduit', colors),
          _toolItem('Knockout set', 'Greenlee or similar', colors),
          const SizedBox(height: 10),
          _categoryHeader('Wire Pulling', colors),
          _toolItem('Fish tape', 'Steel, fiberglass, or nylon', colors),
          _toolItem('Pulling rope', 'Mule tape', colors),
          _toolItem('Wire lubricant', 'Ideal Yellow 77', colors),
          _toolItem('Cable roller', 'For long pulls', colors),
          _toolItem('Tugger/puller', 'For big wire pulls', colors),
          const SizedBox(height: 10),
          _categoryHeader('Panel Work', colors),
          _toolItem('Torque screwdriver', 'For proper termination', colors),
          _toolItem('Wire markers', 'Brady or 3M', colors),
          _toolItem('Label maker', 'Brother P-Touch', colors),
          _toolItem('Panel schedule template', 'Magnetic or paper', colors),
        ],
      ),
    );
  }

  Widget _categoryHeader(String title, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _toolItem(String tool, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.wrench, color: colors.textTertiary, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: tool, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                TextSpan(text: ' - $note', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
