import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// OBD2 Code Lookup - Trouble code definitions
class Obd2LookupScreen extends ConsumerStatefulWidget {
  const Obd2LookupScreen({super.key});
  @override
  ConsumerState<Obd2LookupScreen> createState() => _Obd2LookupScreenState();
}

class _Obd2LookupScreenState extends ConsumerState<Obd2LookupScreen> {
  final _codeController = TextEditingController();
  String? _codeType;
  String? _codeSystem;
  String? _codeDescription;

  static const Map<String, String> _commonCodes = {
    'P0300': 'Random/Multiple Cylinder Misfire Detected',
    'P0301': 'Cylinder 1 Misfire Detected',
    'P0302': 'Cylinder 2 Misfire Detected',
    'P0303': 'Cylinder 3 Misfire Detected',
    'P0171': 'System Too Lean (Bank 1)',
    'P0172': 'System Too Rich (Bank 1)',
    'P0420': 'Catalyst System Efficiency Below Threshold (Bank 1)',
    'P0430': 'Catalyst System Efficiency Below Threshold (Bank 2)',
    'P0440': 'Evaporative Emission Control System Malfunction',
    'P0442': 'Evaporative Emission Control System Leak Detected (small leak)',
    'P0455': 'Evaporative Emission Control System Leak Detected (large leak)',
    'P0500': 'Vehicle Speed Sensor Malfunction',
    'P0505': 'Idle Control System Malfunction',
    'P0128': 'Coolant Thermostat (Coolant Temperature Below Thermostat Regulating Temperature)',
    'P0135': 'O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 1)',
    'P0141': 'O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 2)',
    'P0401': 'Exhaust Gas Recirculation Flow Insufficient Detected',
    'P0700': 'Transmission Control System Malfunction',
    'P0715': 'Input/Turbine Speed Sensor Circuit Malfunction',
    'P0720': 'Output Speed Sensor Circuit Malfunction',
  };

  void _lookup() {
    final code = _codeController.text.toUpperCase().trim();
    if (code.isEmpty || code.length < 5) {
      setState(() { _codeType = null; });
      return;
    }

    String type, system;
    switch (code[0]) {
      case 'P': type = 'Powertrain'; break;
      case 'B': type = 'Body'; break;
      case 'C': type = 'Chassis'; break;
      case 'U': type = 'Network/Communication'; break;
      default: type = 'Unknown';
    }

    final digit1 = code.length > 1 ? code[1] : '0';
    if (digit1 == '0') {
      system = 'Generic (SAE Standard)';
    } else if (digit1 == '1') {
      system = 'Manufacturer Specific';
    } else {
      system = 'Generic';
    }

    final description = _commonCodes[code] ?? 'Code not in database - consult repair manual';

    setState(() {
      _codeType = type;
      _codeSystem = system;
      _codeDescription = description;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _codeController.clear();
    setState(() { _codeType = null; });
  }

  @override
  void dispose() {
    _codeController.dispose();
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
        title: Text('OBD2 Code Lookup', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 2),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'P0420',
                hintStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.bgElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _lookup(),
            ),
            const SizedBox(height: 32),
            if (_codeType != null) _buildResultsCard(colors),
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
        Text('P = Powertrain | B = Body | C = Chassis | U = Network', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        Text('Enter the 5-character diagnostic code', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildResultRow(colors, 'Type', _codeType!),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Category', _codeSystem!),
        const SizedBox(height: 16),
        Text('DESCRIPTION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(_codeDescription!, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
