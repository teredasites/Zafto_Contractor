import 'package:flutter/material.dart';

class NemaConfigScreen extends StatelessWidget {
  const NemaConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEMA Configurations'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.grey[850],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNamingGuide(),
            const SizedBox(height: 16),
            _buildSectionHeader('125V Configurations'),
            _buildNemaCard('5-15', '15A', '125V', '2P/3W', 'Standard household outlet', _draw515()),
            _buildNemaCard('5-20', '20A', '125V', '2P/3W', 'T-slot, 20A circuits', _draw520()),
            _buildNemaCard('5-30', '30A', '125V', '2P/3W', 'RV, some tools', _draw530()),
            _buildNemaCard('5-50', '50A', '125V', '2P/3W', 'Rare, high-amp 125V', _draw550()),
            const SizedBox(height: 16),
            _buildSectionHeader('250V Configurations (No Neutral)'),
            _buildNemaCard('6-15', '15A', '250V', '2P/3W', 'Small 240V equipment', _draw615()),
            _buildNemaCard('6-20', '20A', '250V', '2P/3W', 'Window AC, compressors', _draw620()),
            _buildNemaCard('6-30', '30A', '250V', '2P/3W', 'Some welders', _draw630()),
            _buildNemaCard('6-50', '50A', '250V', '2P/3W', 'Welders, plasma cutters', _draw650()),
            const SizedBox(height: 16),
            _buildSectionHeader('125/250V Configurations (With Neutral)'),
            _buildNemaCard('10-30', '30A', '125/250V', '3P/3W', 'OLD dryer (no ground)', _draw1030()),
            _buildNemaCard('10-50', '50A', '125/250V', '3P/3W', 'OLD range (no ground)', _draw1050()),
            _buildNemaCard('14-30', '30A', '125/250V', '3P/4W', 'Modern dryer', _draw1430()),
            _buildNemaCard('14-50', '50A', '125/250V', '3P/4W', 'Modern range, EV charging', _draw1450()),
            _buildNemaCard('14-60', '60A', '125/250V', '3P/4W', 'Large EV, equipment', _draw1460()),
            const SizedBox(height: 16),
            _buildSectionHeader('Locking Configurations'),
            _buildNemaCard('L5-20', '20A', '125V', '2P/3W', 'Locking, generators', _drawL520()),
            _buildNemaCard('L5-30', '30A', '125V', '2P/3W', 'Locking, RV hookup', _drawL530()),
            _buildNemaCard('L6-20', '20A', '250V', '2P/3W', 'Locking, 240V equipment', _drawL620()),
            _buildNemaCard('L6-30', '30A', '250V', '2P/3W', 'Locking, industrial', _drawL630()),
            _buildNemaCard('L14-30', '30A', '125/250V', '3P/4W', 'Locking, generators', _drawL1430()),
            const SizedBox(height: 24),
            _buildCodeNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildNamingGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEMA Naming Convention', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('  NEMA  14 - 50 R', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14)),
                Text('        │    │  └── R=Receptacle, P=Plug', style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace', fontSize: 11)),
                Text('        │    └───── Amperage (50A)', style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace', fontSize: 11)),
                Text('        └────────── Configuration series', style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace', fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _guideRow('5-xx', '125V, 2-pole, 3-wire (H, N, G)'),
          _guideRow('6-xx', '250V, 2-pole, 3-wire (H, H, G) - no neutral'),
          _guideRow('10-xx', '125/250V, 3-pole, 3-wire (H, H, N) - no ground'),
          _guideRow('14-xx', '125/250V, 3-pole, 4-wire (H, H, N, G)'),
          _guideRow('L prefix', 'Locking (twist-lock) configuration'),
        ],
      ),
    );
  }

  Widget _guideRow(String config, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(config, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(child: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNemaCard(String nema, String amps, String volts, String poles, String use, Widget diagram) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: diagram),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                      child: Text(nema, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Text('$amps • $volts', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(poles, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                Text(use, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Diagram widgets using simple shapes
  Widget _draw515() => _simpleOutlet(['═', '═', '◯'], 'H N G');
  Widget _draw520() => _simpleOutlet(['╔', '═', '◯'], 'H N G');
  Widget _draw530() => _simpleOutlet(['║', '║', '◯'], 'H N G');
  Widget _draw550() => _simpleOutlet(['▐', '▐', '◯'], 'H N G');
  
  Widget _draw615() => _simpleOutlet(['═', '═', '◯'], 'H H G');
  Widget _draw620() => _simpleOutlet(['╔', '═', '◯'], 'H H G');
  Widget _draw630() => _simpleOutlet(['║', '║', '◯'], 'H H G');
  Widget _draw650() => _simpleOutlet(['│', '─', '◯'], 'H H G');
  
  Widget _draw1030() => _threeProng();
  Widget _draw1050() => _threeProng();
  Widget _draw1430() => _fourProng();
  Widget _draw1450() => _fourProng();
  Widget _draw1460() => _fourProng();
  
  Widget _drawL520() => _lockingOutlet('125V');
  Widget _drawL530() => _lockingOutlet('125V');
  Widget _drawL620() => _lockingOutlet('250V');
  Widget _drawL630() => _lockingOutlet('250V');
  Widget _drawL1430() => _lockingOutlet('125/250');

  Widget _simpleOutlet(List<String> slots, String labels) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(slots[0], style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 8),
            Text(slots[1], style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        Text(slots[2], style: const TextStyle(color: Colors.green, fontSize: 12)),
        Text(labels, style: TextStyle(color: Colors.grey[600], fontSize: 8)),
      ],
    );
  }

  Widget _threeProng() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('/', style: TextStyle(color: Colors.red, fontSize: 14)),
            SizedBox(width: 12),
            Text('\\', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const Text('─', style: TextStyle(color: Colors.white, fontSize: 14)),
        Text('H H N', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
      ],
    );
  }

  Widget _fourProng() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('/', style: TextStyle(color: Colors.red, fontSize: 12)),
            SizedBox(width: 8),
            Text('\\', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('─', style: TextStyle(color: Colors.white, fontSize: 12)),
            SizedBox(width: 4),
            Text('◯', style: TextStyle(color: Colors.green, fontSize: 10)),
          ],
        ),
        Text('H H N G', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
      ],
    );
  }

  Widget _lockingOutlet(String voltage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Center(
            child: Text('L', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        Text(voltage, style: TextStyle(color: Colors.grey[500], fontSize: 8)),
      ],
    );
  }

  Widget _buildCodeNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC Requirements', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            '• 406.4(D)(3) - Replacement receptacles must match grounding\n'
            '• NEMA 10-xx (3-wire) no longer permitted for new installations\n'
            '• Use NEMA 14-xx (4-wire) for all new 125/250V circuits\n'
            '• Dryers and ranges require separate equipment ground\n'
            '• Match receptacle amperage to circuit breaker',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
