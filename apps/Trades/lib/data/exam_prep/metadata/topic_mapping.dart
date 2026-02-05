/// Topic Mapping - Exam topic definitions and ZAFTO screen mappings

class ExamTopic {
  final String id;
  final String name;
  final String description;
  final List<String> necArticles;
  final List<String> relatedScreenIds;
  
  const ExamTopic({required this.id, required this.name, required this.description, required this.necArticles, required this.relatedScreenIds});
}

class ExamTopics {
  ExamTopics._();
  
  static const List<ExamTopic> all = [
    ExamTopic(id: 'GK', name: 'General Knowledge', description: 'Definitions, calculations, general requirements', necArticles: ['Article 100', '90', '110'], relatedScreenIds: ['formulas', 'unit_converter']),
    ExamTopic(id: 'SE', name: 'Services & Equipment', description: 'Service entrance, panels, disconnects', necArticles: ['230', '408'], relatedScreenIds: ['service_entrance', 'service_entrance_diagram']),
    ExamTopic(id: 'FD', name: 'Feeders', description: 'Feeder sizing, calculations, taps', necArticles: ['215', '220'], relatedScreenIds: ['dwelling_load', 'commercial_load']),
    ExamTopic(id: 'BC', name: 'Branch Circuits', description: 'Branch circuits, receptacles, GFCI/AFCI', necArticles: ['210', '406'], relatedScreenIds: ['gfci_afci', 'gfci_wiring']),
    ExamTopic(id: 'WM', name: 'Wiring Methods', description: 'Cables, conduit, raceways', necArticles: ['300', '310', '334', '358'], relatedScreenIds: ['conduit_fill', 'ampacity']),
    ExamTopic(id: 'ED', name: 'Equipment & Devices', description: 'Switches, receptacles, boxes', necArticles: ['404', '406', '314'], relatedScreenIds: ['box_fill', 'outlet_config']),
    ExamTopic(id: 'CD', name: 'Control Devices', description: 'Switches, controllers, overcurrent', necArticles: ['240', '404'], relatedScreenIds: ['breaker_sizing_table']),
    ExamTopic(id: 'MG', name: 'Motors & Generators', description: 'Motor circuits, protection, starters', necArticles: ['430', '440', '445'], relatedScreenIds: ['motor_circuit', 'motor_fla']),
    ExamTopic(id: 'SO', name: 'Special Occupancies', description: 'Hazardous, healthcare, pools', necArticles: ['500-590', '680'], relatedScreenIds: ['hazardous_locations', 'pool_spa_wiring']),
    ExamTopic(id: 'RE', name: 'Renewable Energy', description: 'Solar PV, battery storage, EV', necArticles: ['690', '625', '706'], relatedScreenIds: ['solar_pv', 'ev_charger']),
    ExamTopic(id: 'GB', name: 'Grounding & Bonding', description: 'Grounding systems, bonding', necArticles: ['250'], relatedScreenIds: ['grounding', 'grounding_electrode']),
    ExamTopic(id: 'CA', name: 'Calculations', description: 'Load calculations, sizing', necArticles: ['220', 'Annex D'], relatedScreenIds: ['dwelling_load', 'voltage_drop']),
  ];
  
  static ExamTopic? getById(String id) {
    try { return all.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }
  
  static List<ExamTopic> getByIds(List<String> ids) => all.where((t) => ids.contains(t.id)).toList();
}
