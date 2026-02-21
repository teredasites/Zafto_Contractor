// ZAFTO Price Book Item Model
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Company-specific known prices for one-click use in estimates/invoices.
// S130 Owner Directive implementation.

import 'package:equatable/equatable.dart';

class PriceBookItem extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String? category;
  final String? trade;
  final double unitPrice;
  final String unitOfMeasure;
  final String? description;
  final String? sku;
  final String? supplier;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PriceBookItem({
    required this.id,
    required this.companyId,
    required this.name,
    this.category,
    this.trade,
    required this.unitPrice,
    required this.unitOfMeasure,
    this.description,
    this.sku,
    this.supplier,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted price string
  String get formattedPrice => '\$${unitPrice.toStringAsFixed(2)}/${unitOfMeasure}';

  /// Total cost for a given quantity
  double totalFor(double quantity) => unitPrice * quantity;

  factory PriceBookItem.fromJson(Map<String, dynamic> json) {
    return PriceBookItem(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      trade: json['trade'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'each',
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      supplier: json['supplier'] as String?,
      isActive: json['is_active'] != false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'category': category,
        'trade': trade,
        'unit_price': unitPrice,
        'unit_of_measure': unitOfMeasure,
        'description': description,
        'sku': sku,
        'supplier': supplier,
        'is_active': isActive,
      };

  PriceBookItem copyWith({
    String? id,
    String? companyId,
    String? name,
    String? category,
    String? trade,
    double? unitPrice,
    String? unitOfMeasure,
    String? description,
    String? sku,
    String? supplier,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PriceBookItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      category: category ?? this.category,
      trade: trade ?? this.trade,
      unitPrice: unitPrice ?? this.unitPrice,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      supplier: supplier ?? this.supplier,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        category,
        trade,
        unitPrice,
        unitOfMeasure,
        sku,
        supplier,
        isActive,
      ];
}
