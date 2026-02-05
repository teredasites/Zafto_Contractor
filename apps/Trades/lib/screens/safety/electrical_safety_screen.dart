import 'package:flutter/material.dart';

class ElectricalSafetyScreen extends StatelessWidget {
  const ElectricalSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrical Safety'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.grey[850],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencySection(),
            const SizedBox(height: 16),
            _buildArcFlashBoundaries(),
            const SizedBox(height: 16),
            _buildPPECategories(),
            const SizedBox(height: 16),
            _buildLockoutTagout(),
            const SizedBox(height: 16),
            _buildFirstAid(),
            const SizedBox(height: 16),
            _buildSafeWorkPractices(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text('EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('If someone is being electrocuted:', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _emergencyStep('1', 'DO NOT touch them directly'),
          _emergencyStep('2', 'Disconnect power at source (breaker/disconnect)'),
          _emergencyStep('3', 'If can\'t disconnect, use non-conductive object to separate'),
          _emergencyStep('4', 'Call 911 immediately'),
          _emergencyStep('5', 'Begin CPR if not breathing and trained'),
          _emergencyStep('6', 'Treat for shock - lay flat, elevate legs'),
        ],
      ),
    );
  }

  Widget _emergencyStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(num, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildArcFlashBoundaries() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NFPA 70E Arc Flash Boundaries', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text('┌────────────────────────────────────────┐', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│        ARC FLASH BOUNDARY              │', style: TextStyle(color: Colors.orange[300], fontFamily: 'monospace', fontSize: 9)),
                Text('│  ┌──────────────────────────────────┐  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │      LIMITED APPROACH            │  │', style: TextStyle(color: Colors.yellow[300], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  ┌────────────────────────────┐  │  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  │    RESTRICTED APPROACH     │  │  │', style: TextStyle(color: Colors.red[300], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  │  ┌──────────────────────┐  │  │  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  │  │  PROHIBITED APPROACH │  │  │  │', style: TextStyle(color: Colors.red, fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  │  │    ⚡ HAZARD ⚡      │  │  │  │', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  │  └──────────────────────┘  │  │  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│  │  └────────────────────────────┘  │  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('│  └──────────────────────────────────┘  │', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
                Text('└────────────────────────────────────────┘', style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace', fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _boundaryRow('Arc Flash Boundary', 'Varies by incident energy', 'PPE required inside'),
          _boundaryRow('Limited Approach', '3.5 ft (50V-750V)', 'Qualified persons only'),
          _boundaryRow('Restricted Approach', '1 ft (50V-750V)', 'Qualified + PPE + plan'),
          _boundaryRow('Prohibited Approach', '0.083 ft (1 inch)', 'Same as direct contact'),
        ],
      ),
    );
  }

  Widget _boundaryRow(String boundary, String distance, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(boundary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text(distance, style: const TextStyle(color: Colors.amber, fontSize: 11))),
          Expanded(flex: 3, child: Text(requirement, style: const TextStyle(color: Colors.white60, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildPPECategories() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PPE Categories (NFPA 70E)', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ppeCategory('1', '4 cal/cm²', 'Arc-rated shirt/pants, safety glasses, hearing protection, leather gloves'),
          _ppeCategory('2', '8 cal/cm²', 'Arc-rated shirt/pants, arc-rated face shield, arc-rated balaclava, hearing protection'),
          _ppeCategory('3', '25 cal/cm²', 'Arc flash suit hood, arc-rated shirt/pants, arc-rated jacket, hearing protection'),
          _ppeCategory('4', '40 cal/cm²', 'Arc flash suit hood, arc-rated multilayer switching coat/pants, hearing protection'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange[900]?.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              '⚠️ PPE is the LAST line of defense. Always de-energize when possible.',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ppeCategory(String cat, String cal, String equipment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text(cat, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Min Arc Rating: $cal', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(equipment, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockoutTagout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text('Lockout/Tagout (LOTO)', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _lotoStep('1', 'Notify affected employees'),
          _lotoStep('2', 'Identify all energy sources'),
          _lotoStep('3', 'Shut down equipment normally'),
          _lotoStep('4', 'Isolate energy sources (open disconnects)'),
          _lotoStep('5', 'Apply LOCK to each isolation point'),
          _lotoStep('6', 'Apply TAG with your name and date'),
          _lotoStep('7', 'Verify zero energy (test with meter)'),
          _lotoStep('8', 'Perform work'),
          _lotoStep('9', 'Remove locks/tags only by installer'),
          _lotoStep('10', 'Restore energy, notify employees'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red[900]?.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'NEVER remove another person\'s lock. Each worker applies their OWN lock.',
              style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lotoStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text('$num.', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFirstAid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text('First Aid for Electrical Shock', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('After safely separating victim from power:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          _firstAidItem('Check responsiveness - tap shoulder, ask "Are you OK?"'),
          _firstAidItem('Call 911 or have someone call'),
          _firstAidItem('Check breathing - look, listen, feel for 10 seconds'),
          _firstAidItem('If not breathing - begin CPR (30 compressions : 2 breaths)'),
          _firstAidItem('If breathing - place in recovery position'),
          _firstAidItem('Check for burns at entry and exit points'),
          _firstAidItem('Cover burns with sterile dressing'),
          _firstAidItem('Treat for shock - lay flat, elevate legs if no spinal injury'),
          _firstAidItem('Monitor until EMS arrives'),
          const SizedBox(height: 12),
          const Text('⚠️ ALL electrical shock victims should be evaluated by medical professionals - internal injuries may not be visible.', style: TextStyle(color: Colors.orange, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _firstAidItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.green)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSafeWorkPractices() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Safe Work Practices', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _safetyItem('Always assume circuits are LIVE until verified dead'),
          _safetyItem('Test YOUR meter on known live source before and after'),
          _safetyItem('Use proper PPE for the hazard level'),
          _safetyItem('Never work alone on energized equipment'),
          _safetyItem('Keep one hand in pocket when testing live circuits'),
          _safetyItem('Remove all jewelry and metal objects'),
          _safetyItem('Use insulated tools rated for the voltage'),
          _safetyItem('Maintain 3-point contact on ladders'),
          _safetyItem('Inspect tools and cords before each use'),
          _safetyItem('Know location of nearest AED and first aid kit'),
          _safetyItem('Report all near-misses and unsafe conditions'),
        ],
      ),
    );
  }

  Widget _safetyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}
