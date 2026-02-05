# ZAFTO Sprint 6.0 - Migration Quick Reference
**Last Updated:** January 29, 2026

---

## STATUS: CALCULATORS COMPLETE ✅

All 35 calculators migrated to Design System v2.6 on January 29, 2026.

---

## REMAINING WORK (61 screens)

### Diagrams (23)
```
ceiling_fan, dimmer_switch, four_way_switch, garage_subpanel,
gfci_wiring, grounding_electrode, low_voltage, motor_starter,
outlet_240v, photocell_timer, pool_spa_wiring, recessed_lighting,
service_entrance, single_pole_switch, smoke_detector, split_receptacle,
sub_panel, thermostat_wiring, three_phase_basics, three_way_switch,
transfer_switch, under_cabinet, vfd_wiring
```

### Reference (21)
```
aluminum_wiring, ampacity_table, apprentice_guide, common_mistakes,
conduit_dimensions, formulas, gfci_afci, grounding_vs_bonding,
hazardous_locations, knob_tube, motor_nameplate, nec_changes,
nec_navigation, outlet_config, permit_checklist, rough_in_checklist,
state_adoption, tool_list, troubleshooting, wire_color_code, wire_properties
```

### Tables (9)
```
awg_reference, box_fill_table, breaker_sizing_table, conduit_bend_multipliers,
derating_table, grounding_table, motor_fla_table, raceway_fill_table,
transformer_fla_table
```

### AI Scanner (5)
```
ai_scanner, credits_purchase, scan_result, scan_result_io, scan_result_stub
```

### Other (3)
```
nema_config, electrical_safety, blueprint_symbols
```

---

## MIGRATION CHECKLIST PER FILE

1. Change imports: AppTheme → zafto_colors + theme_provider
2. Add: `import 'package:flutter_riverpod/flutter_riverpod.dart';`
3. Add: `import 'package:lucide_icons/lucide_icons.dart';`
4. StatefulWidget → ConsumerStatefulWidget
5. State<X> → ConsumerState<X>
6. Add: `final colors = ref.watch(zaftoColorsProvider);`
7. Replace all AppTheme.X with colors.X
8. Replace all Icons.X with LucideIcons.x
9. Replace .withOpacity(x) with .withValues(alpha: x)
10. Remove custom private widget classes, inline them

---

## COLOR MAPPINGS

```dart
AppTheme.backgroundDark → colors.bgBase
AppTheme.cardDark → colors.bgElevated
AppTheme.surfaceDark → colors.bgElevated
AppTheme.textSecondary → colors.textSecondary
AppTheme.textTertiary → colors.textTertiary
AppTheme.border → colors.borderSubtle
AppTheme.primary → colors.accentPrimary
AppTheme.electrical → colors.accentPrimary
AppTheme.success → colors.accentSuccess
AppTheme.warning → colors.accentWarning
AppTheme.error → colors.accentError
AppTheme.info → colors.accentInfo
Colors.white → colors.textPrimary (for text)
Colors.black → Colors.white (for selected button text on light accent)
```

---

## ICON MAPPINGS

```dart
Icons.arrow_back_ios_new → LucideIcons.arrowLeft
Icons.refresh → LucideIcons.rotateCcw  
Icons.check_circle → LucideIcons.checkCircle
Icons.check_box → LucideIcons.checkSquare
Icons.check_box_outline_blank → LucideIcons.square
Icons.info_outline → LucideIcons.info
Icons.gavel → LucideIcons.scale
Icons.flash_on → LucideIcons.zap
Icons.warning_amber → LucideIcons.alertTriangle
Icons.settings → LucideIcons.settings
Icons.calculate → LucideIcons.calculator
Icons.remove_circle_outline → LucideIcons.minusCircle
Icons.add_circle_outline → LucideIcons.plusCircle
Icons.lightbulb → LucideIcons.lightbulb
Icons.power_off → LucideIcons.powerOff
Icons.electric_bolt → LucideIcons.zap
Icons.schema → LucideIcons.gitBranch
Icons.menu_book → LucideIcons.bookOpen
Icons.table_chart → LucideIcons.table2
Icons.camera_alt → LucideIcons.camera
Icons.help_outline → LucideIcons.helpCircle
```

---

## RUN COMMANDS

```batch
# Run app
cd /d "C:\Users\Developer LLC\Desktop\Tereda LLC\Zafto_Electrical"
call run_zafto.bat

# Analyze specific folder
C:\tools\flutter\bin\flutter.bat analyze lib/screens/diagrams/

# Port: 5000
# Browser: Brave only
```

---

## SAMPLE MIGRATION

### Before (AppTheme):
```dart
import '../../theme/app_theme.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
```

### After (Design System v2.6):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
```

---

## CRITICAL REMINDERS

1. **READ 11_DESIGN_SYSTEM.md** before starting
2. Use **semantic tokens** not raw colors
3. Test **all 10 themes** work correctly
4. **Checkpoint every 3-5 files** to avoid context issues
5. Update **SPRINT_STATUS.md** after each batch
