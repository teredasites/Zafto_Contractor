/// Calculator Registry - Central registry of all calculators across trades

import 'calculator_base.dart';

class CalculatorRegistry {
  static final CalculatorRegistry _instance = CalculatorRegistry._internal();
  factory CalculatorRegistry() => _instance;
  CalculatorRegistry._internal();

  final Map<String, CalculatorBase> _calculators = {};
  final Map<String, List<String>> _byTrade = {};
  final Map<String, List<String>> _byCategory = {};

  /// Register a calculator
  void register(CalculatorBase calculator) {
    _calculators[calculator.id] = calculator;

    // Index by trade
    _byTrade.putIfAbsent(calculator.trade, () => []);
    _byTrade[calculator.trade]!.add(calculator.id);

    // Index by category
    final categoryKey = '${calculator.trade}:${calculator.category}';
    _byCategory.putIfAbsent(categoryKey, () => []);
    _byCategory[categoryKey]!.add(calculator.id);
  }

  /// Get a calculator by ID
  CalculatorBase? get(String id) => _calculators[id];

  /// Get all calculators for a trade
  List<CalculatorBase> getByTrade(String trade) {
    final ids = _byTrade[trade] ?? [];
    return ids.map((id) => _calculators[id]!).toList();
  }

  /// Get all calculators for a category
  List<CalculatorBase> getByCategory(String trade, String category) {
    final key = '$trade:$category';
    final ids = _byCategory[key] ?? [];
    return ids.map((id) => _calculators[id]!).toList();
  }

  /// Search calculators by name or description
  List<CalculatorBase> search(String query, {String? trade}) {
    final lowerQuery = query.toLowerCase();
    return _calculators.values.where((calc) {
      if (trade != null && calc.trade != trade) return false;
      return calc.name.toLowerCase().contains(lowerQuery) ||
          calc.description.toLowerCase().contains(lowerQuery) ||
          calc.id.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get all registered trades
  List<String> get trades => _byTrade.keys.toList();

  /// Get all categories for a trade
  List<String> getCategories(String trade) {
    return _byCategory.keys
        .where((key) => key.startsWith('$trade:'))
        .map((key) => key.split(':')[1])
        .toSet()
        .toList();
  }

  /// Get total calculator count
  int get count => _calculators.length;

  /// Get count by trade
  Map<String, int> get countByTrade {
    return _byTrade.map((trade, ids) => MapEntry(trade, ids.length));
  }

  /// Export registry summary
  Map<String, dynamic> toJson() => {
    'total_calculators': count,
    'trades': trades,
    'count_by_trade': countByTrade,
    'calculators': _calculators.values.map((c) => {
      return {
        'id': c.id,
        'name': c.name,
        'trade': c.trade,
        'category': c.category,
      };
    }).toList(),
  };
}

/// Trade definitions
class TradeDefinition {
  final String id;
  final String name;
  final String icon;
  final List<String> categories;
  final bool isLicensed;

  const TradeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.categories,
    this.isLicensed = true,
  });
}

/// All supported trades
class Trades {
  static const electrical = TradeDefinition(
    id: 'electrical',
    name: 'Electrical',
    icon: 'bolt',
    categories: [
      'Wire Sizing',
      'Load Calculations',
      'Conduit & Raceway',
      'Motors',
      'Grounding',
      'Services',
      'Transformers',
    ],
  );

  static const plumbing = TradeDefinition(
    id: 'plumbing',
    name: 'Plumbing',
    icon: 'water_drop',
    categories: [
      'Pipe Sizing',
      'Drainage',
      'Venting',
      'Water Heaters',
      'Fixtures',
      'Gas Piping',
    ],
  );

  static const hvac = TradeDefinition(
    id: 'hvac',
    name: 'HVAC',
    icon: 'thermostat',
    categories: [
      'Load Calculations',
      'Refrigeration',
      'Ductwork',
      'Airflow',
      'Psychrometrics',
    ],
  );

  static const solar = TradeDefinition(
    id: 'solar',
    name: 'Solar',
    icon: 'solar_power',
    categories: [
      'System Sizing',
      'String Design',
      'Electrical',
      'Production',
    ],
  );

  static const gc = TradeDefinition(
    id: 'gc',
    name: 'General Contractor',
    icon: 'construction',
    categories: [
      'Concrete',
      'Framing',
      'Estimating',
      'Structural',
    ],
  );

  static const roofing = TradeDefinition(
    id: 'roofing',
    name: 'Roofing',
    icon: 'roofing',
    isLicensed: false,
    categories: [
      'Materials',
      'Estimating',
      'Ventilation',
    ],
  );

  static const remodeler = TradeDefinition(
    id: 'remodeler',
    name: 'Remodeler',
    icon: 'home_repair_service',
    isLicensed: false,
    categories: [
      'Kitchen',
      'Bath',
      'Flooring',
      'Estimating',
    ],
  );

  static const landscaping = TradeDefinition(
    id: 'landscaping',
    name: 'Landscaping',
    icon: 'grass',
    isLicensed: false,
    categories: [
      'Irrigation',
      'Hardscape',
      'Materials',
      'Estimating',
    ],
  );

  static const all = [
    electrical,
    plumbing,
    hvac,
    solar,
    gc,
    roofing,
    remodeler,
    landscaping,
  ];

  static const licensed = [
    electrical,
    plumbing,
    hvac,
    solar,
    gc,
  ];
}
