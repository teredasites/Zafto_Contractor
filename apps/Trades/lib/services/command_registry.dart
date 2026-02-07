/// App Command Registry - Design System v2.6
/// Central registry of all app destinations, actions, and searchable content
/// This is the "brain" that knows where everything is
/// Future: AI can query this to understand and navigate the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/certifications/certifications_screen.dart';

/// Command types for categorization and filtering
enum CommandType {
  calculator,
  reference,
  diagram,
  examPrep,
  job,
  invoice,
  customer,
  bid,
  fieldTool,
  timeClock,
  settings,
  action,
  aiScanner,
}

/// A single command/destination in the app
class AppCommand {
  final String id;
  final String title;
  final String? subtitle;
  final CommandType type;
  final IconData icon;
  final List<String> keywords; // For smart search
  final String? route; // Named route if applicable
  final Widget Function(BuildContext)? builder; // Screen builder
  final VoidCallback? action; // For actions like "New Job"
  final bool requiresAuth;
  final bool isPro; // Pro-only feature
  
  const AppCommand({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.icon,
    this.keywords = const [],
    this.route,
    this.builder,
    this.action,
    this.requiresAuth = false,
    this.isPro = false,
  });
  
  /// Smart search score - higher = better match
  double searchScore(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return 0;
    
    final titleLower = title.toLowerCase();
    final subtitleLower = (subtitle ?? '').toLowerCase();
    
    // Exact title match
    if (titleLower == q) return 100;
    
    // Title starts with query
    if (titleLower.startsWith(q)) return 90;
    
    // Title contains query
    if (titleLower.contains(q)) return 70;
    
    // Keyword exact match
    for (final kw in keywords) {
      if (kw.toLowerCase() == q) return 85;
    }
    
    // Keyword starts with
    for (final kw in keywords) {
      if (kw.toLowerCase().startsWith(q)) return 75;
    }
    
    // Keyword contains
    for (final kw in keywords) {
      if (kw.toLowerCase().contains(q)) return 60;
    }
    
    // Subtitle match
    if (subtitleLower.contains(q)) return 50;
    
    // Fuzzy: any word in title starts with query
    final titleWords = titleLower.split(' ');
    for (final word in titleWords) {
      if (word.startsWith(q)) return 65;
    }
    
    return 0;
  }
}

/// The central command registry
class CommandRegistry {
  static final CommandRegistry _instance = CommandRegistry._internal();
  factory CommandRegistry() => _instance;
  CommandRegistry._internal();
  
  final List<AppCommand> _commands = [];
  
  List<AppCommand> get allCommands => List.unmodifiable(_commands);
  
  void register(AppCommand command) {
    _commands.add(command);
  }
  
  void registerAll(List<AppCommand> commands) {
    _commands.addAll(commands);
  }
  
  void clear() => _commands.clear();
  
  /// Search commands with smart ranking
  List<AppCommand> search(String query, {CommandType? filterType, int limit = 20}) {
    if (query.trim().isEmpty && filterType == null) {
      return _commands.take(limit).toList();
    }
    
    var results = _commands.where((cmd) {
      if (filterType != null && cmd.type != filterType) return false;
      if (query.trim().isEmpty) return true;
      return cmd.searchScore(query) > 0;
    }).toList();
    
    if (query.trim().isNotEmpty) {
      results.sort((a, b) => b.searchScore(query).compareTo(a.searchScore(query)));
    }
    
    return results.take(limit).toList();
  }
  
  /// Get commands by type
  List<AppCommand> byType(CommandType type) {
    return _commands.where((cmd) => cmd.type == type).toList();
  }
  
  /// Get a specific command by ID
  AppCommand? byId(String id) {
    try {
      return _commands.firstWhere((cmd) => cmd.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Get suggested/frequent commands (can be personalized later)
  List<AppCommand> getSuggested({int limit = 8}) {
    final actions = _commands.where((c) => c.type == CommandType.action).take(4);
    final business = _commands.where((c) =>
      c.type == CommandType.job || c.type == CommandType.bid ||
      c.type == CommandType.invoice || c.type == CommandType.customer ||
      c.type == CommandType.timeClock
    ).take(4);
    return [...actions, ...business].take(limit).toList();
  }
}

/// Riverpod provider for the command registry
final commandRegistryProvider = Provider<CommandRegistry>((ref) {
  final registry = CommandRegistry();
  _registerAllCommands(registry);
  return registry;
});

/// Register all app commands - this is the master list
void _registerAllCommands(CommandRegistry registry) {
  registry.clear();
  
  // === QUICK ACTIONS ===
  registry.registerAll([
    AppCommand(
      id: 'action_new_job',
      title: 'New Job',
      subtitle: 'Create a new job',
      type: CommandType.action,
      icon: LucideIcons.plus,
      keywords: ['create', 'add', 'job', 'work'],
    ),
    AppCommand(
      id: 'action_new_invoice',
      title: 'New Invoice',
      subtitle: 'Create a new invoice',
      type: CommandType.action,
      icon: LucideIcons.filePlus,
      keywords: ['create', 'add', 'invoice', 'bill'],
    ),
    AppCommand(
      id: 'action_new_customer',
      title: 'New Customer',
      subtitle: 'Add a new customer',
      type: CommandType.action,
      icon: LucideIcons.userPlus,
      keywords: ['create', 'add', 'customer', 'client'],
    ),
    AppCommand(
      id: 'action_scan',
      title: 'AI Scanner',
      subtitle: 'Scan equipment with AI',
      type: CommandType.aiScanner,
      icon: LucideIcons.scan,
      keywords: ['scan', 'camera', 'ai', 'identify', 'equipment', 'nameplate'],
      isPro: true,
    ),
  ]);
  
  // === CALCULATORS ===
  registry.registerAll([
    AppCommand(
      id: 'calc_voltage_drop',
      title: 'Voltage Drop',
      subtitle: 'Calculate voltage drop in conductors',
      type: CommandType.calculator,
      icon: LucideIcons.arrowDown,
      keywords: ['vd', 'voltage', 'drop', 'wire', 'length', 'conductor', '3%', '5%'],
    ),
    AppCommand(
      id: 'calc_wire_sizing',
      title: 'Wire Sizing',
      subtitle: 'Size conductors for load',
      type: CommandType.calculator,
      icon: LucideIcons.plug,
      keywords: ['wire', 'awg', 'conductor', 'ampacity', 'size', 'gauge'],
    ),
    AppCommand(
      id: 'calc_conduit_fill',
      title: 'Conduit Fill',
      subtitle: 'Calculate conduit fill percentage',
      type: CommandType.calculator,
      icon: LucideIcons.pipette,
      keywords: ['conduit', 'fill', 'emt', 'pvc', 'rigid', 'chapter 9', '40%'],
    ),
    AppCommand(
      id: 'calc_box_fill',
      title: 'Box Fill',
      subtitle: 'Calculate junction box fill',
      type: CommandType.calculator,
      icon: LucideIcons.box,
      keywords: ['box', 'fill', 'junction', '314.16', 'cubic inch'],
    ),
    AppCommand(
      id: 'calc_dwelling_load',
      title: 'Dwelling Load',
      subtitle: 'Residential service calculation',
      type: CommandType.calculator,
      icon: LucideIcons.home,
      keywords: ['dwelling', 'residential', 'house', 'load', 'service', '220'],
    ),
    AppCommand(
      id: 'calc_commercial_load',
      title: 'Commercial Load',
      subtitle: 'Commercial service calculation',
      type: CommandType.calculator,
      icon: LucideIcons.building,
      keywords: ['commercial', 'building', 'load', 'service', '220'],
    ),
    AppCommand(
      id: 'calc_motor_circuit',
      title: 'Motor Circuit',
      subtitle: 'Motor branch circuit sizing',
      type: CommandType.calculator,
      icon: LucideIcons.cog,
      keywords: ['motor', 'branch', 'circuit', 'overload', 'fla', '430'],
    ),
    AppCommand(
      id: 'calc_motor_fla',
      title: 'Motor FLA',
      subtitle: 'Full load amps from Table 430',
      type: CommandType.calculator,
      icon: LucideIcons.gauge,
      keywords: ['motor', 'fla', 'full load', 'amps', 'horsepower', 'hp'],
    ),
    AppCommand(
      id: 'calc_ohms_law',
      title: "Ohm's Law",
      subtitle: 'V = I × R calculations',
      type: CommandType.calculator,
      icon: LucideIcons.zap,
      keywords: ['ohms', 'voltage', 'current', 'resistance', 'watts', 'power'],
    ),
    AppCommand(
      id: 'calc_ampacity',
      title: 'Ampacity',
      subtitle: 'Conductor ampacity with corrections',
      type: CommandType.calculator,
      icon: LucideIcons.thermometer,
      keywords: ['ampacity', '310.16', 'temperature', 'correction', 'adjustment'],
    ),
    AppCommand(
      id: 'calc_transformer',
      title: 'Transformer',
      subtitle: 'Transformer calculations',
      type: CommandType.calculator,
      icon: LucideIcons.arrowLeftRight,
      keywords: ['transformer', 'kva', 'primary', 'secondary', 'turns'],
    ),
    AppCommand(
      id: 'calc_grounding',
      title: 'Grounding',
      subtitle: 'GEC and EGC sizing',
      type: CommandType.calculator,
      icon: LucideIcons.anchor,
      keywords: ['ground', 'grounding', 'gec', 'egc', '250', 'electrode'],
    ),
    AppCommand(
      id: 'calc_service_entrance',
      title: 'Service Entrance',
      subtitle: 'Service conductor sizing',
      type: CommandType.calculator,
      icon: LucideIcons.doorOpen,
      keywords: ['service', 'entrance', 'main', 'feeder', '230'],
    ),
    AppCommand(
      id: 'calc_ev_charger',
      title: 'EV Charger',
      subtitle: 'Electric vehicle charger sizing',
      type: CommandType.calculator,
      icon: LucideIcons.car,
      keywords: ['ev', 'electric', 'vehicle', 'charger', 'tesla', '625'],
    ),
    AppCommand(
      id: 'calc_solar_pv',
      title: 'Solar PV',
      subtitle: 'Photovoltaic system sizing',
      type: CommandType.calculator,
      icon: LucideIcons.sun,
      keywords: ['solar', 'pv', 'photovoltaic', 'panel', '690'],
    ),
    AppCommand(
      id: 'calc_generator',
      title: 'Generator Sizing',
      subtitle: 'Standby generator calculations',
      type: CommandType.calculator,
      icon: LucideIcons.power,
      keywords: ['generator', 'standby', 'backup', 'transfer', '702'],
    ),
    AppCommand(
      id: 'calc_power_factor',
      title: 'Power Factor',
      subtitle: 'PF correction calculations',
      type: CommandType.calculator,
      icon: LucideIcons.activity,
      keywords: ['power', 'factor', 'pf', 'correction', 'capacitor', 'kvar'],
    ),
    AppCommand(
      id: 'calc_fault_current',
      title: 'Fault Current',
      subtitle: 'Available fault current',
      type: CommandType.calculator,
      icon: LucideIcons.alertTriangle,
      keywords: ['fault', 'current', 'aic', 'short', 'circuit', 'available'],
    ),
    AppCommand(
      id: 'calc_conduit_bending',
      title: 'Conduit Bending',
      subtitle: 'Offset, saddle, kick calculations',
      type: CommandType.calculator,
      icon: LucideIcons.cornerDownRight,
      keywords: ['bend', 'bending', 'offset', 'saddle', 'kick', 'conduit'],
    ),
    AppCommand(
      id: 'calc_pull_box',
      title: 'Pull Box',
      subtitle: 'Pull box sizing per 314.28',
      type: CommandType.calculator,
      icon: LucideIcons.square,
      keywords: ['pull', 'box', 'junction', '314.28', 'sizing'],
    ),
    AppCommand(
      id: 'calc_tap_rule',
      title: 'Tap Rules',
      subtitle: '10ft, 25ft tap calculations',
      type: CommandType.calculator,
      icon: LucideIcons.gitBranch,
      keywords: ['tap', 'rule', '10', '25', 'foot', 'feeder'],
    ),
    AppCommand(
      id: 'calc_unit_converter',
      title: 'Unit Converter',
      subtitle: 'Convert electrical units',
      type: CommandType.calculator,
      icon: LucideIcons.repeat,
      keywords: ['convert', 'unit', 'watts', 'amps', 'volts'],
    ),
    AppCommand(
      id: 'calc_power_converter',
      title: 'Power Converter',
      subtitle: 'kW, HP, VA conversions',
      type: CommandType.calculator,
      icon: LucideIcons.shuffle,
      keywords: ['power', 'convert', 'kw', 'hp', 'va', 'kva'],
    ),
    // ... more calculators can be added
  ]);
  
  // === REFERENCE ===
  registry.registerAll([
    AppCommand(
      id: 'ref_ampacity_table',
      title: 'Ampacity Table',
      subtitle: 'Table 310.16 - Conductor Ampacity',
      type: CommandType.reference,
      icon: LucideIcons.table,
      keywords: ['ampacity', '310.16', 'table', 'wire', 'conductor'],
    ),
    AppCommand(
      id: 'ref_wire_colors',
      title: 'Wire Color Codes',
      subtitle: 'Standard wire color identification',
      type: CommandType.reference,
      icon: LucideIcons.palette,
      keywords: ['color', 'wire', 'code', 'black', 'white', 'green', 'red'],
    ),
    AppCommand(
      id: 'ref_gfci_afci',
      title: 'GFCI/AFCI Requirements',
      subtitle: 'Protection requirements by location',
      type: CommandType.reference,
      icon: LucideIcons.shieldCheck,
      keywords: ['gfci', 'afci', 'protection', 'bathroom', 'kitchen', '210.8'],
    ),
    AppCommand(
      id: 'ref_conduit_dimensions',
      title: 'Conduit Dimensions',
      subtitle: 'EMT, PVC, Rigid dimensions',
      type: CommandType.reference,
      icon: LucideIcons.ruler,
      keywords: ['conduit', 'dimension', 'emt', 'pvc', 'rigid', 'size'],
    ),
    AppCommand(
      id: 'ref_formulas',
      title: 'Electrical Formulas',
      subtitle: 'Common electrical formulas',
      type: CommandType.reference,
      icon: LucideIcons.sigma,
      keywords: ['formula', 'equation', 'ohms', 'power', 'math'],
    ),
    AppCommand(
      id: 'ref_nec_changes',
      title: 'NEC Code Changes',
      subtitle: 'Recent NEC edition changes',
      type: CommandType.reference,
      icon: LucideIcons.fileText,
      keywords: ['nec', 'code', 'change', '2023', '2020', 'new'],
    ),
    AppCommand(
      id: 'ref_grounding_bonding',
      title: 'Grounding vs Bonding',
      subtitle: 'Understanding the difference',
      type: CommandType.reference,
      icon: LucideIcons.anchor,
      keywords: ['ground', 'bond', 'grounding', 'bonding', '250'],
    ),
    AppCommand(
      id: 'ref_hazardous',
      title: 'Hazardous Locations',
      subtitle: 'Class, Division, Zone classifications',
      type: CommandType.reference,
      icon: LucideIcons.flame,
      keywords: ['hazardous', 'class', 'division', 'zone', '500', 'explosive'],
    ),
    AppCommand(
      id: 'ref_motor_nameplate',
      title: 'Motor Nameplate',
      subtitle: 'Understanding motor data',
      type: CommandType.reference,
      icon: LucideIcons.tag,
      keywords: ['motor', 'nameplate', 'fla', 'hp', 'sf', 'service factor'],
    ),
    AppCommand(
      id: 'ref_nec_navigation',
      title: 'NEC Navigation',
      subtitle: 'How to navigate the code book',
      type: CommandType.reference,
      icon: LucideIcons.compass,
      keywords: ['nec', 'navigate', 'code', 'book', 'article', 'section'],
    ),
    AppCommand(
      id: 'ref_outlet_config',
      title: 'Outlet Configurations',
      subtitle: 'NEMA plug and receptacle types',
      type: CommandType.reference,
      icon: LucideIcons.plug,
      keywords: ['outlet', 'receptacle', 'nema', 'plug', 'configuration'],
    ),
    AppCommand(
      id: 'ref_state_adoption',
      title: 'State NEC Adoption',
      subtitle: 'NEC edition by state',
      type: CommandType.reference,
      icon: LucideIcons.map,
      keywords: ['state', 'adoption', 'nec', 'edition', 'code'],
    ),
  ]);
  
  // === EXAM PREP ===
  registry.registerAll([
    AppCommand(
      id: 'exam_practice',
      title: 'Practice Exam',
      subtitle: 'Timed practice questions',
      type: CommandType.examPrep,
      icon: LucideIcons.clipboardCheck,
      keywords: ['exam', 'practice', 'test', 'question', 'quiz'],
    ),
    AppCommand(
      id: 'exam_flashcards',
      title: 'Flashcards',
      subtitle: 'Study with flashcards',
      type: CommandType.examPrep,
      icon: LucideIcons.layers,
      keywords: ['flashcard', 'study', 'memorize', 'learn'],
    ),
    AppCommand(
      id: 'exam_by_topic',
      title: 'Study by Topic',
      subtitle: 'Questions organized by NEC article',
      type: CommandType.examPrep,
      icon: LucideIcons.bookOpen,
      keywords: ['topic', 'article', 'study', 'section'],
    ),
  ]);
  
  // === DIAGRAMS ===
  registry.registerAll([
    AppCommand(
      id: 'diagram_3way',
      title: '3-Way Switch',
      subtitle: 'Three-way switch wiring',
      type: CommandType.diagram,
      icon: LucideIcons.gitFork,
      keywords: ['3-way', 'three', 'switch', 'wiring', 'diagram'],
    ),
    AppCommand(
      id: 'diagram_4way',
      title: '4-Way Switch',
      subtitle: 'Four-way switch wiring',
      type: CommandType.diagram,
      icon: LucideIcons.gitFork,
      keywords: ['4-way', 'four', 'switch', 'wiring', 'diagram'],
    ),
    AppCommand(
      id: 'diagram_gfci',
      title: 'GFCI Wiring',
      subtitle: 'GFCI receptacle wiring',
      type: CommandType.diagram,
      icon: LucideIcons.shieldCheck,
      keywords: ['gfci', 'receptacle', 'wiring', 'diagram', 'load', 'line'],
    ),
  ]);
  
  // === BUSINESS ===
  registry.registerAll([
    AppCommand(
      id: 'jobs_hub',
      title: 'Jobs',
      subtitle: 'View all jobs',
      type: CommandType.job,
      icon: LucideIcons.briefcase,
      keywords: ['jobs', 'work', 'project', 'list'],
    ),
    AppCommand(
      id: 'invoices_hub',
      title: 'Invoices',
      subtitle: 'View all invoices',
      type: CommandType.invoice,
      icon: LucideIcons.fileText,
      keywords: ['invoice', 'bill', 'payment', 'list'],
    ),
    AppCommand(
      id: 'customers_hub',
      title: 'Customers',
      subtitle: 'View all customers',
      type: CommandType.customer,
      icon: LucideIcons.users,
      keywords: ['customer', 'client', 'contact', 'list'],
    ),
  ]);
  
  // === BIDS ===
  registry.registerAll([
    AppCommand(
      id: 'bids_hub',
      title: 'Bids',
      subtitle: 'View all bids and estimates',
      type: CommandType.bid,
      icon: LucideIcons.fileCheck,
      keywords: ['bids', 'estimate', 'proposal', 'quote', 'list'],
    ),
    AppCommand(
      id: 'action_new_bid',
      title: 'New Bid',
      subtitle: 'Create a new bid or estimate',
      type: CommandType.action,
      icon: LucideIcons.filePlus2,
      keywords: ['create', 'add', 'bid', 'estimate', 'proposal'],
    ),
  ]);

  // === TIME & SCHEDULING ===
  registry.registerAll([
    AppCommand(
      id: 'time_clock',
      title: 'Time Clock',
      subtitle: 'Clock in/out and track hours',
      type: CommandType.timeClock,
      icon: LucideIcons.clock,
      keywords: ['time', 'clock', 'hours', 'punch', 'in', 'out', 'track'],
    ),
    AppCommand(
      id: 'calendar',
      title: 'Calendar',
      subtitle: 'View schedule and appointments',
      type: CommandType.timeClock,
      icon: LucideIcons.calendar,
      keywords: ['calendar', 'schedule', 'appointment', 'date', 'event'],
    ),
  ]);

  // === FIELD TOOLS ===
  registry.registerAll([
    // Hub
    AppCommand(
      id: 'field_tools_hub',
      title: 'Field Tools',
      subtitle: 'All 19 field tools in one place',
      type: CommandType.fieldTool,
      icon: LucideIcons.wrench,
      keywords: ['field', 'tools', 'hub', 'all'],
    ),
    // Photo & Documentation
    AppCommand(
      id: 'tool_job_site_photos',
      title: 'Job Site Photos',
      subtitle: 'Capture photos with GPS and timestamps',
      type: CommandType.fieldTool,
      icon: LucideIcons.camera,
      keywords: ['photo', 'camera', 'capture', 'site', 'gps', 'picture'],
    ),
    AppCommand(
      id: 'tool_before_after',
      title: 'Before / After',
      subtitle: 'Side-by-side comparison photos',
      type: CommandType.fieldTool,
      icon: LucideIcons.columns,
      keywords: ['before', 'after', 'comparison', 'slider', 'photo'],
    ),
    AppCommand(
      id: 'tool_defect_markup',
      title: 'Defect Markup',
      subtitle: 'Annotate photos with drawings and notes',
      type: CommandType.fieldTool,
      icon: LucideIcons.edit3,
      keywords: ['markup', 'annotate', 'defect', 'draw', 'arrow', 'photo'],
    ),
    AppCommand(
      id: 'tool_voice_notes',
      title: 'Voice Notes',
      subtitle: 'Record audio notes on the job site',
      type: CommandType.fieldTool,
      icon: LucideIcons.mic,
      keywords: ['voice', 'audio', 'recording', 'notes', 'dictate', 'mic'],
    ),
    // Business & Tracking
    AppCommand(
      id: 'tool_mileage_tracker',
      title: 'Mileage Tracker',
      subtitle: 'GPS trip tracking for deductions',
      type: CommandType.fieldTool,
      icon: LucideIcons.car,
      keywords: ['mileage', 'gps', 'trip', 'tracking', 'drive', 'irs', 'deduction'],
    ),
    AppCommand(
      id: 'tool_receipt_scanner',
      title: 'Receipt Scanner',
      subtitle: 'Capture and organize expense receipts',
      type: CommandType.fieldTool,
      icon: LucideIcons.receipt,
      keywords: ['receipt', 'expense', 'scan', 'ocr', 'cost'],
    ),
    AppCommand(
      id: 'tool_client_signature',
      title: 'Client Signature',
      subtitle: 'Digital signature capture',
      type: CommandType.fieldTool,
      icon: LucideIcons.penTool,
      keywords: ['signature', 'sign', 'digital', 'approval', 'client'],
    ),
    AppCommand(
      id: 'tool_materials_tracker',
      title: 'Materials Tracker',
      subtitle: 'Track materials and equipment costs',
      type: CommandType.fieldTool,
      icon: LucideIcons.package,
      keywords: ['materials', 'equipment', 'inventory', 'cost', 'parts'],
    ),
    AppCommand(
      id: 'tool_daily_log',
      title: 'Daily Log',
      subtitle: 'Daily job reports with crew and weather',
      type: CommandType.fieldTool,
      icon: LucideIcons.clipboardList,
      keywords: ['daily', 'log', 'report', 'crew', 'weather', 'journal'],
    ),
    // Field Operations
    AppCommand(
      id: 'tool_punch_list',
      title: 'Punch List',
      subtitle: 'Task checklist with priority tracking',
      type: CommandType.fieldTool,
      icon: LucideIcons.checkSquare,
      keywords: ['punch', 'list', 'checklist', 'task', 'priority', 'todo'],
    ),
    AppCommand(
      id: 'tool_change_orders',
      title: 'Change Orders',
      subtitle: 'Scope changes and approval workflow',
      type: CommandType.fieldTool,
      icon: LucideIcons.fileDiff,
      keywords: ['change', 'order', 'scope', 'approval', 'co'],
    ),
    AppCommand(
      id: 'tool_job_completion',
      title: 'Job Completion',
      subtitle: 'Validate and close out jobs',
      type: CommandType.fieldTool,
      icon: LucideIcons.checkCircle,
      keywords: ['completion', 'close', 'validate', 'finish', 'done'],
    ),
    AppCommand(
      id: 'tool_sun_position',
      title: 'Sun Position',
      subtitle: 'Solar angles for panel placement',
      type: CommandType.fieldTool,
      icon: LucideIcons.sun,
      keywords: ['sun', 'solar', 'position', 'angle', 'panel', 'azimuth'],
    ),
    // Safety & Compliance
    AppCommand(
      id: 'tool_loto_logger',
      title: 'LOTO Logger',
      subtitle: 'Lock Out / Tag Out tracking',
      type: CommandType.fieldTool,
      icon: LucideIcons.lock,
      keywords: ['loto', 'lockout', 'tagout', 'safety', 'energy'],
    ),
    AppCommand(
      id: 'tool_incident_report',
      title: 'Incident Report',
      subtitle: 'OSHA incident documentation',
      type: CommandType.fieldTool,
      icon: LucideIcons.alertTriangle,
      keywords: ['incident', 'report', 'osha', 'accident', 'injury'],
    ),
    AppCommand(
      id: 'tool_safety_briefing',
      title: 'Safety Briefing',
      subtitle: 'Toolbox talks and crew sign-off',
      type: CommandType.fieldTool,
      icon: LucideIcons.shield,
      keywords: ['safety', 'briefing', 'toolbox', 'talk', 'meeting'],
    ),
    AppCommand(
      id: 'tool_confined_space',
      title: 'Confined Space',
      subtitle: 'Entry tracking and air monitoring',
      type: CommandType.fieldTool,
      icon: LucideIcons.box,
      keywords: ['confined', 'space', 'entry', 'air', 'permit', 'osha'],
    ),
    // Utilities
    AppCommand(
      id: 'tool_dead_man_switch',
      title: 'Dead Man Switch',
      subtitle: 'Lone worker safety timer',
      type: CommandType.fieldTool,
      icon: LucideIcons.userCheck,
      keywords: ['dead', 'man', 'switch', 'safety', 'lone', 'worker', 'timer'],
    ),
    AppCommand(
      id: 'tool_level_plumb',
      title: 'Level & Plumb',
      subtitle: 'Digital level with calibration',
      type: CommandType.fieldTool,
      icon: LucideIcons.ruler,
      keywords: ['level', 'plumb', 'bubble', 'calibration', 'angle'],
    ),
  ]);

  // === NOTIFICATIONS ===
  registry.registerAll([
    AppCommand(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'View all notifications',
      type: CommandType.action,
      icon: LucideIcons.bell,
      keywords: ['notifications', 'alerts', 'bell', 'unread', 'messages'],
    ),
  ]);

  // === SETTINGS ===
  registry.registerAll([
    AppCommand(
      id: 'settings_main',
      title: 'Settings',
      subtitle: 'App settings',
      type: CommandType.settings,
      icon: LucideIcons.settings,
      keywords: ['settings', 'preferences', 'config'],
    ),
    AppCommand(
      id: 'settings_theme',
      title: 'Theme',
      subtitle: 'Change app theme',
      type: CommandType.settings,
      icon: LucideIcons.palette,
      keywords: ['theme', 'dark', 'light', 'color', 'appearance'],
    ),
    AppCommand(
      id: 'settings_state',
      title: 'Select State',
      subtitle: 'Change your state for NEC edition',
      type: CommandType.settings,
      icon: LucideIcons.mapPin,
      keywords: ['state', 'location', 'nec', 'edition'],
    ),
    AppCommand(
      id: 'settings_profile',
      title: 'Profile',
      subtitle: 'Your profile settings',
      type: CommandType.settings,
      icon: LucideIcons.user,
      keywords: ['profile', 'account', 'user'],
    ),
    AppCommand(
      id: 'certifications',
      title: 'Certifications',
      subtitle: 'Employee licenses and certifications',
      type: CommandType.settings,
      icon: LucideIcons.award,
      keywords: ['certification', 'license', 'cert', 'epa', 'osha', 'cpr', 'cdl', 'nicet', 'iicrc'],
      builder: (_) => const CertificationsScreen(),
    ),
  ]);
}
