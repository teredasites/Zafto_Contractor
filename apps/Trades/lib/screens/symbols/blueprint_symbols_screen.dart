import 'package:flutter/material.dart';

class BlueprintSymbolsScreen extends StatefulWidget {
  const BlueprintSymbolsScreen({super.key});

  @override
  State<BlueprintSymbolsScreen> createState() => _BlueprintSymbolsScreenState();
}

class _BlueprintSymbolsScreenState extends State<BlueprintSymbolsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Outlets', 'Switches', 'Lighting', 'Panels', 'Wiring', 'Misc'];

  final List<Map<String, String>> _symbols = [
    // Outlets
    {'symbol': '⊙', 'name': 'Duplex Receptacle', 'desc': 'Standard 120V outlet', 'category': 'Outlets'},
    {'symbol': '⊙WP', 'name': 'Weatherproof Outlet', 'desc': 'Outdoor/wet location', 'category': 'Outlets'},
    {'symbol': '⊙GFI', 'name': 'GFCI Receptacle', 'desc': 'Ground fault protected', 'category': 'Outlets'},
    {'symbol': '⊙4', 'name': 'Fourplex Outlet', 'desc': '4-gang receptacle', 'category': 'Outlets'},
    {'symbol': '⊙240', 'name': '240V Receptacle', 'desc': 'Dryer, range, etc', 'category': 'Outlets'},
    {'symbol': '⊙DW', 'name': 'Dishwasher', 'desc': 'Dedicated circuit', 'category': 'Outlets'},
    {'symbol': '⊙DISP', 'name': 'Disposal', 'desc': 'Garbage disposal', 'category': 'Outlets'},
    {'symbol': '⊙R', 'name': 'Range Outlet', 'desc': '50A 240V', 'category': 'Outlets'},
    {'symbol': '⊙D', 'name': 'Dryer Outlet', 'desc': '30A 240V', 'category': 'Outlets'},
    {'symbol': '⊙F', 'name': 'Floor Outlet', 'desc': 'Flush floor mount', 'category': 'Outlets'},
    {'symbol': '⊙△', 'name': 'Dedicated Circuit', 'desc': 'Single device only', 'category': 'Outlets'},
    {'symbol': '⊙H', 'name': 'Half-Hot Outlet', 'desc': 'Split receptacle', 'category': 'Outlets'},
    
    // Switches
    {'symbol': 'S', 'name': 'Single Pole Switch', 'desc': 'One location control', 'category': 'Switches'},
    {'symbol': 'S₂', 'name': 'Double Pole Switch', 'desc': '240V disconnect', 'category': 'Switches'},
    {'symbol': 'S₃', 'name': 'Three-Way Switch', 'desc': 'Two location control', 'category': 'Switches'},
    {'symbol': 'S₄', 'name': 'Four-Way Switch', 'desc': '3+ location control', 'category': 'Switches'},
    {'symbol': 'SD', 'name': 'Dimmer Switch', 'desc': 'Variable brightness', 'category': 'Switches'},
    {'symbol': 'SWP', 'name': 'Weatherproof Switch', 'desc': 'Outdoor rated', 'category': 'Switches'},
    {'symbol': 'SK', 'name': 'Key Switch', 'desc': 'Keyed operation', 'category': 'Switches'},
    {'symbol': 'ST', 'name': 'Timer Switch', 'desc': 'Timed operation', 'category': 'Switches'},
    {'symbol': 'SM', 'name': 'Motion Sensor', 'desc': 'Occupancy switch', 'category': 'Switches'},
    {'symbol': 'SF', 'name': 'Fan Speed Control', 'desc': 'Variable speed', 'category': 'Switches'},
    {'symbol': 'SP', 'name': 'Switch w/ Pilot', 'desc': 'Has indicator light', 'category': 'Switches'},
    
    // Lighting
    {'symbol': '○', 'name': 'Surface Light', 'desc': 'Ceiling mount', 'category': 'Lighting'},
    {'symbol': '⊗', 'name': 'Recessed Light', 'desc': 'Can/downlight', 'category': 'Lighting'},
    {'symbol': '○F', 'name': 'Fluorescent', 'desc': 'Linear fixture', 'category': 'Lighting'},
    {'symbol': '○LED', 'name': 'LED Fixture', 'desc': 'LED light', 'category': 'Lighting'},
    {'symbol': '▽', 'name': 'Wall Sconce', 'desc': 'Wall mounted', 'category': 'Lighting'},
    {'symbol': '◇', 'name': 'Track Lighting', 'desc': 'Track system', 'category': 'Lighting'},
    {'symbol': '⊕', 'name': 'Ceiling Fan', 'desc': 'Fan w/ or w/o light', 'category': 'Lighting'},
    {'symbol': '☼', 'name': 'Outdoor Light', 'desc': 'Exterior fixture', 'category': 'Lighting'},
    {'symbol': '○E', 'name': 'Emergency Light', 'desc': 'Battery backup', 'category': 'Lighting'},
    {'symbol': 'EXIT', 'name': 'Exit Sign', 'desc': 'Illuminated exit', 'category': 'Lighting'},
    {'symbol': '○UC', 'name': 'Under Cabinet', 'desc': 'Task lighting', 'category': 'Lighting'},
    {'symbol': '○P', 'name': 'Pendant', 'desc': 'Hanging fixture', 'category': 'Lighting'},
    {'symbol': '○V', 'name': 'Vapor Tight', 'desc': 'Wet/damp location', 'category': 'Lighting'},
    
    // Panels & Equipment
    {'symbol': '▣', 'name': 'Panel Board', 'desc': 'Breaker panel', 'category': 'Panels'},
    {'symbol': '▣M', 'name': 'Main Panel', 'desc': 'Service entrance', 'category': 'Panels'},
    {'symbol': '▣S', 'name': 'Sub Panel', 'desc': 'Branch panel', 'category': 'Panels'},
    {'symbol': '⊠', 'name': 'Junction Box', 'desc': 'Wire splice point', 'category': 'Panels'},
    {'symbol': '⊞', 'name': 'Pull Box', 'desc': 'Large junction', 'category': 'Panels'},
    {'symbol': '⊟', 'name': 'Disconnect', 'desc': 'Safety switch', 'category': 'Panels'},
    {'symbol': '◎', 'name': 'Meter Base', 'desc': 'Utility meter', 'category': 'Panels'},
    {'symbol': '⏚', 'name': 'Ground Rod', 'desc': 'Grounding electrode', 'category': 'Panels'},
    {'symbol': 'XFMR', 'name': 'Transformer', 'desc': 'Voltage conversion', 'category': 'Panels'},
    {'symbol': 'M', 'name': 'Motor', 'desc': 'Electric motor', 'category': 'Panels'},
    {'symbol': 'G', 'name': 'Generator', 'desc': 'Standby/portable', 'category': 'Panels'},
    
    // Wiring
    {'symbol': '───', 'name': 'Branch Circuit', 'desc': 'Concealed in ceiling/wall', 'category': 'Wiring'},
    {'symbol': '- - -', 'name': 'Concealed Floor', 'desc': 'In floor/slab', 'category': 'Wiring'},
    {'symbol': '═══', 'name': 'Exposed Conduit', 'desc': 'Surface mounted', 'category': 'Wiring'},
    {'symbol': '──2──', 'name': '2-Wire Circuit', 'desc': '1 hot + 1 neutral', 'category': 'Wiring'},
    {'symbol': '──3──', 'name': '3-Wire Circuit', 'desc': '2 hot + 1 neutral', 'category': 'Wiring'},
    {'symbol': '──4──', 'name': '4-Wire Circuit', 'desc': '3 hot + 1 neutral', 'category': 'Wiring'},
    {'symbol': '──H──', 'name': 'Home Run', 'desc': 'To panel', 'category': 'Wiring'},
    {'symbol': '↑', 'name': 'Wiring Up', 'desc': 'Rises to above', 'category': 'Wiring'},
    {'symbol': '↓', 'name': 'Wiring Down', 'desc': 'Drops to below', 'category': 'Wiring'},
    
    // Misc/Fire Alarm
    {'symbol': '⚠SD', 'name': 'Smoke Detector', 'desc': 'Fire alarm device', 'category': 'Misc'},
    {'symbol': '⚠CO', 'name': 'CO Detector', 'desc': 'Carbon monoxide', 'category': 'Misc'},
    {'symbol': '⚠H', 'name': 'Heat Detector', 'desc': 'Fire alarm', 'category': 'Misc'},
    {'symbol': '⌂', 'name': 'Doorbell', 'desc': 'Chime button', 'category': 'Misc'},
    {'symbol': '⌂C', 'name': 'Chime', 'desc': 'Doorbell chime', 'category': 'Misc'},
    {'symbol': '☎', 'name': 'Phone Outlet', 'desc': 'Telephone jack', 'category': 'Misc'},
    {'symbol': '📺', 'name': 'TV/Data Outlet', 'desc': 'Coax/ethernet', 'category': 'Misc'},
    {'symbol': 'T', 'name': 'Thermostat', 'desc': 'HVAC control', 'category': 'Misc'},
    {'symbol': '♨', 'name': 'Smoke/Heat Combo', 'desc': 'Dual sensor', 'category': 'Misc'},
    {'symbol': 'SPKR', 'name': 'Speaker', 'desc': 'Audio output', 'category': 'Misc'},
    {'symbol': 'CAM', 'name': 'Security Camera', 'desc': 'CCTV/IP camera', 'category': 'Misc'},
  ];

  List<Map<String, String>> get _filteredSymbols {
    return _symbols.where((s) {
      final matchesCategory = _selectedCategory == 'All' || s['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['desc']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Symbols'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.grey[850],
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildSymbolGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search symbols...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.amber,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymbolGrid() {
    final symbols = _filteredSymbols;
    if (symbols.isEmpty) {
      return Center(
        child: Text('No symbols found', style: TextStyle(color: Colors.grey[500])),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: symbols.length,
      itemBuilder: (context, index) {
        final s = symbols[index];
        return _buildSymbolCard(s);
      },
    );
  }

  Widget _buildSymbolCard(Map<String, String> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                s['symbol']!,
                style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(s['desc']!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(s['category']!, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
