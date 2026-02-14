// ZAFTO Pricing Rule Model
// J3: Configurable pricing rules per company/trade.

import 'package:equatable/equatable.dart';

enum PricingRuleType {
  demandSurge,
  distanceMarkup,
  seasonal,
  urgency,
  complexity,
  repeatCustomer,
  materialMarket,
  timeOfDay;

  String get dbValue {
    switch (this) {
      case PricingRuleType.demandSurge: return 'demand_surge';
      case PricingRuleType.distanceMarkup: return 'distance_markup';
      case PricingRuleType.seasonal: return 'seasonal';
      case PricingRuleType.urgency: return 'urgency';
      case PricingRuleType.complexity: return 'complexity';
      case PricingRuleType.repeatCustomer: return 'repeat_customer';
      case PricingRuleType.materialMarket: return 'material_market';
      case PricingRuleType.timeOfDay: return 'time_of_day';
    }
  }

  static PricingRuleType fromDb(String? value) {
    switch (value) {
      case 'demand_surge': return PricingRuleType.demandSurge;
      case 'distance_markup': return PricingRuleType.distanceMarkup;
      case 'seasonal': return PricingRuleType.seasonal;
      case 'urgency': return PricingRuleType.urgency;
      case 'complexity': return PricingRuleType.complexity;
      case 'repeat_customer': return PricingRuleType.repeatCustomer;
      case 'material_market': return PricingRuleType.materialMarket;
      case 'time_of_day': return PricingRuleType.timeOfDay;
      default: return PricingRuleType.demandSurge;
    }
  }

  String get label {
    switch (this) {
      case PricingRuleType.demandSurge: return 'Demand Surge';
      case PricingRuleType.distanceMarkup: return 'Distance Markup';
      case PricingRuleType.seasonal: return 'Seasonal';
      case PricingRuleType.urgency: return 'Urgency';
      case PricingRuleType.complexity: return 'Complexity';
      case PricingRuleType.repeatCustomer: return 'Repeat Customer';
      case PricingRuleType.materialMarket: return 'Material Market';
      case PricingRuleType.timeOfDay: return 'Time of Day';
    }
  }

  String get description {
    switch (this) {
      case PricingRuleType.demandSurge: return 'Increase price when schedule is nearly full';
      case PricingRuleType.distanceMarkup: return 'Add markup based on drive distance';
      case PricingRuleType.seasonal: return 'Adjust pricing for peak/off-peak seasons';
      case PricingRuleType.urgency: return 'Premium for same-day or rush service';
      case PricingRuleType.complexity: return 'Adjust for high-complexity jobs';
      case PricingRuleType.repeatCustomer: return 'Loyalty discount for returning customers';
      case PricingRuleType.materialMarket: return 'Adjust for current material prices';
      case PricingRuleType.timeOfDay: return 'After-hours and weekend premiums';
    }
  }
}

class PricingRule extends Equatable {
  final String id;
  final String companyId;
  final PricingRuleType ruleType;
  final Map<String, dynamic> ruleConfig;
  final String? tradeType;
  final bool active;
  final int priority;
  final DateTime createdAt;

  const PricingRule({
    required this.id,
    required this.companyId,
    required this.ruleType,
    required this.ruleConfig,
    this.tradeType,
    required this.active,
    required this.priority,
    required this.createdAt,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      ruleType: PricingRuleType.fromDb(json['rule_type'] as String?),
      ruleConfig: Map<String, dynamic>.from(json['rule_config'] as Map? ?? {}),
      tradeType: json['trade_type'] as String?,
      active: json['active'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'rule_type': ruleType.dbValue,
    'rule_config': ruleConfig,
    'trade_type': tradeType,
    'active': active,
    'priority': priority,
  };

  PricingRule copyWith({
    String? id,
    String? companyId,
    PricingRuleType? ruleType,
    Map<String, dynamic>? ruleConfig,
    String? tradeType,
    bool? active,
    int? priority,
    DateTime? createdAt,
  }) {
    return PricingRule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      ruleType: ruleType ?? this.ruleType,
      ruleConfig: ruleConfig ?? this.ruleConfig,
      tradeType: tradeType ?? this.tradeType,
      active: active ?? this.active,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, ruleType, active];
}
