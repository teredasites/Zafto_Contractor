// ZAFTO Line Item Suggester — SK8
// Maps room measurements + trade layer data to suggested estimate line items.
// Suggestions are pre-filled but user-editable before finalizing.
//
// Rules:
//   1. Room type + trade → standard items (bathroom+plumbing → toilet, sink, etc.)
//   2. Damage layer → remediation items (Class 3 water → demo, dry, replace)
//   3. Trade layer elements → counted items (5 receptacles → 5x rough-in)
//   4. Universal items: paint (wall+ceiling SF), flooring (floor SF), baseboard (LF)

import 'dart:ui' show Offset;

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/floor_plan_elements.dart';
import '../models/trade_layer.dart';
import 'room_measurement_calculator.dart';
import 'estimate_area_generator.dart';

// =============================================================================
// SUGGESTED LINE ITEM
// =============================================================================

class SuggestedLineItem {
  final String description;
  final String actionType;
  final double quantity;
  final String unitCode;
  final String trade;
  final String? zaftoCode;
  final double materialCost;
  final double laborCost;
  final double equipmentCost;

  const SuggestedLineItem({
    required this.description,
    this.actionType = 'add',
    required this.quantity,
    this.unitCode = 'EA',
    this.trade = 'general',
    this.zaftoCode,
    this.materialCost = 0,
    this.laborCost = 0,
    this.equipmentCost = 0,
  });

  double get unitPrice => materialCost + laborCost + equipmentCost;
  double get lineTotal => quantity * unitPrice;
}

// =============================================================================
// SUGGESTER
// =============================================================================

class LineItemSuggester {
  /// Generate suggested line items for each room in the estimate.
  /// Returns map of areaId → list of suggested items.
  Future<Map<String, List<SuggestedLineItem>>> suggestLineItems({
    required GeneratedEstimateResult estimateResult,
    required FloorPlanData planData,
    String? selectedTrade,
  }) async {
    final result = <String, List<SuggestedLineItem>>{};

    // Load pricing from estimate_items if available
    final pricing = await _loadPricing(selectedTrade);

    for (final area in estimateResult.areas) {
      final items = <SuggestedLineItem>[];

      // Universal items based on measurements
      items.addAll(_suggestUniversalItems(area.measurements, pricing));

      // Trade-specific items from trade layers
      final room = planData.rooms
          .where((r) => r.id == area.roomId)
          .firstOrNull;
      if (room != null) {
        items.addAll(_suggestTradeItems(
          room: room,
          planData: planData,
          measurements: area.measurements,
          selectedTrade: selectedTrade,
          pricing: pricing,
        ));
      }

      result[area.areaId] = items;
    }

    return result;
  }

  /// Save suggested line items to the database.
  Future<void> saveLineItems({
    required String estimateId,
    required Map<String, List<SuggestedLineItem>> itemsByArea,
  }) async {
    try {
      final rows = <Map<String, dynamic>>[];
      var sortOrder = 0;

      for (final entry in itemsByArea.entries) {
        final areaId = entry.key;
        for (final item in entry.value) {
          rows.add({
            'estimate_id': estimateId,
            'area_id': areaId,
            'description': item.description,
            'action_type': item.actionType,
            'quantity': item.quantity,
            'unit_code': item.unitCode,
            'material_cost': item.materialCost,
            'labor_cost': item.laborCost,
            'equipment_cost': item.equipmentCost,
            'unit_price': item.unitPrice,
            'line_total': item.lineTotal,
            'sort_order': sortOrder++,
            if (item.zaftoCode != null) 'zafto_code': item.zaftoCode,
          });
        }
      }

      if (rows.isNotEmpty) {
        await supabase.from('estimate_line_items').insert(rows);
      }
    } catch (e) {
      throw DatabaseError('Failed to save line items: $e', cause: e);
    }
  }

  // ===========================================================================
  // UNIVERSAL ITEMS (every room gets these)
  // ===========================================================================

  List<SuggestedLineItem> _suggestUniversalItems(
    RoomMeasurements m,
    Map<String, _PricingEntry> pricing,
  ) {
    final items = <SuggestedLineItem>[];

    // Paint — walls
    if (m.wallSf > 0) {
      final p = pricing['paint-walls'];
      items.add(SuggestedLineItem(
        description: 'Paint walls — ${m.roomName}',
        quantity: m.paintSfWallsOnly,
        unitCode: 'SF',
        trade: 'painting',
        zaftoCode: 'PAINT-WALL',
        materialCost: p?.materialCost ?? 0.35,
        laborCost: p?.laborCost ?? 0.85,
      ));
    }

    // Paint — ceiling
    if (m.ceilingSf > 0) {
      final p = pricing['paint-ceiling'];
      items.add(SuggestedLineItem(
        description: 'Paint ceiling — ${m.roomName}',
        quantity: m.paintSfCeilingOnly,
        unitCode: 'SF',
        trade: 'painting',
        zaftoCode: 'PAINT-CEIL',
        materialCost: p?.materialCost ?? 0.30,
        laborCost: p?.laborCost ?? 0.90,
      ));
    }

    // Baseboard
    if (m.baseboardLf > 0) {
      final p = pricing['baseboard'];
      items.add(SuggestedLineItem(
        description: 'Baseboard — ${m.roomName}',
        quantity: m.baseboardLf,
        unitCode: 'LF',
        trade: 'carpentry',
        zaftoCode: 'TRIM-BASE',
        materialCost: p?.materialCost ?? 2.50,
        laborCost: p?.laborCost ?? 3.00,
      ));
    }

    // Flooring
    if (m.floorSf > 0) {
      final p = pricing['flooring'];
      items.add(SuggestedLineItem(
        description: 'Flooring — ${m.roomName}',
        quantity: m.floorSf,
        unitCode: 'SF',
        trade: 'flooring',
        zaftoCode: 'FLOOR-STD',
        materialCost: p?.materialCost ?? 3.00,
        laborCost: p?.laborCost ?? 2.50,
      ));
    }

    return items;
  }

  // ===========================================================================
  // TRADE-SPECIFIC ITEMS
  // ===========================================================================

  List<SuggestedLineItem> _suggestTradeItems({
    required DetectedRoom room,
    required FloorPlanData planData,
    required RoomMeasurements measurements,
    String? selectedTrade,
    required Map<String, _PricingEntry> pricing,
  }) {
    final items = <SuggestedLineItem>[];

    // Scan trade layers for elements in/near this room
    for (final layer in planData.tradeLayers) {
      if (selectedTrade != null && layer.type != selectedTrade) continue;

      if (layer.tradeData != null) {
        items.addAll(_suggestFromTradeElements(
          layer: layer,
          room: room,
          planData: planData,
          pricing: pricing,
        ));
      }

      if (layer.damageData != null) {
        items.addAll(_suggestFromDamageData(
          layer: layer,
          room: room,
          measurements: measurements,
          pricing: pricing,
        ));
      }
    }

    return items;
  }

  List<SuggestedLineItem> _suggestFromTradeElements({
    required TradeLayer layer,
    required DetectedRoom room,
    required FloorPlanData planData,
    required Map<String, _PricingEntry> pricing,
  }) {
    final items = <SuggestedLineItem>[];
    if (layer.tradeData == null) return items;

    // Count trade elements by type within this room's bounds
    final elementCounts = <String, int>{};
    for (final element in layer.tradeData!.elements) {
      // Simple containment check: element position within room bounding box
      if (_isPointInRoom(element.position, room, planData)) {
        final key = '${layer.type}-${element.symbolType}';
        elementCounts[key] = (elementCounts[key] ?? 0) + 1;
      }
    }

    // Convert counts to line items
    for (final entry in elementCounts.entries) {
      final parts = entry.key.split('-');
      final trade = parts[0];
      final symbolType = parts.length > 1 ? parts.sublist(1).join('-') : 'item';
      final count = entry.value;

      items.add(SuggestedLineItem(
        description: '${_humanize(symbolType)} rough-in — ${room.name}',
        actionType: 'add',
        quantity: count.toDouble(),
        unitCode: 'EA',
        trade: trade,
        materialCost: pricing['$trade-$symbolType']?.materialCost ?? 15.0,
        laborCost: pricing['$trade-$symbolType']?.laborCost ?? 45.0,
      ));
    }

    return items;
  }

  List<SuggestedLineItem> _suggestFromDamageData({
    required TradeLayer layer,
    required DetectedRoom room,
    required RoomMeasurements measurements,
    required Map<String, _PricingEntry> pricing,
  }) {
    final items = <SuggestedLineItem>[];
    if (layer.damageData == null) return items;

    // Check for damage zones overlapping this room
    for (final zone in layer.damageData!.zones) {
      final damageClass = zone.damageClass;

      // Water damage remediation by class
      if (damageClass == '1' || damageClass == '2' || damageClass == '3') {
        // Demo damaged drywall
        items.add(SuggestedLineItem(
          description: 'Demo drywall (Class $damageClass water damage) — ${room.name}',
          actionType: 'remove',
          quantity: measurements.wallSf,
          unitCode: 'SF',
          trade: 'restoration',
          materialCost: 0,
          laborCost: pricing['demo-drywall']?.laborCost ?? 1.25,
        ));

        // Dry structure
        items.add(SuggestedLineItem(
          description: 'Structural drying (Class $damageClass) — ${room.name}',
          actionType: 'add',
          quantity: measurements.floorSf,
          unitCode: 'SF',
          trade: 'restoration',
          equipmentCost: pricing['structural-dry']?.equipmentCost ?? 2.50,
          laborCost: pricing['structural-dry']?.laborCost ?? 1.50,
        ));

        // Replace drywall (Class 2+)
        if (damageClass == '2' || damageClass == '3') {
          items.add(SuggestedLineItem(
            description: 'Replace drywall (Class $damageClass) — ${room.name}',
            actionType: 'replace',
            quantity: measurements.wallSf,
            unitCode: 'SF',
            trade: 'restoration',
            materialCost: pricing['replace-drywall']?.materialCost ?? 2.00,
            laborCost: pricing['replace-drywall']?.laborCost ?? 3.50,
          ));
        }
      }
    }

    // Equipment from moisture readings / containment
    final equipmentCount = layer.damageData!.barriers.length;
    if (equipmentCount > 0) {
      items.add(SuggestedLineItem(
        description: 'Drying equipment placement — ${room.name}',
        actionType: 'add',
        quantity: equipmentCount.toDouble(),
        unitCode: 'EA',
        trade: 'restoration',
        equipmentCost: pricing['drying-equipment']?.equipmentCost ?? 75.0,
        laborCost: pricing['drying-equipment']?.laborCost ?? 25.0,
      ));
    }

    return items;
  }

  // ===========================================================================
  // PRICING LOOKUP
  // ===========================================================================

  Future<Map<String, _PricingEntry>> _loadPricing(String? trade) async {
    try {
      var query = supabase
          .from('estimate_items')
          .select('zafto_code, material_cost, labor_cost, equipment_cost')
          .eq('is_common', true);

      if (trade != null) {
        query = query.eq('trade', trade);
      }

      final response = await query.limit(200);
      final map = <String, _PricingEntry>{};

      for (final row in (response as List)) {
        final r = row as Map<String, dynamic>;
        final code = (r['zafto_code'] as String?)?.toLowerCase() ?? '';
        if (code.isNotEmpty) {
          map[code] = _PricingEntry(
            materialCost: (r['material_cost'] as num?)?.toDouble() ?? 0,
            laborCost: (r['labor_cost'] as num?)?.toDouble() ?? 0,
            equipmentCost: (r['equipment_cost'] as num?)?.toDouble() ?? 0,
          );
        }
      }

      return map;
    } catch (_) {
      // Pricing lookup failure is non-critical — use defaults
      return {};
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Simple bounding-box check for whether a point is within a room.
  bool _isPointInRoom(
      Offset point, DetectedRoom room, FloorPlanData planData) {
    // Get room boundary walls and compute bounding box
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final wallId in room.wallIds) {
      final wall =
          planData.walls.where((w) => w.id == wallId).firstOrNull;
      if (wall == null) continue;

      minX = [minX, wall.start.dx, wall.end.dx].reduce((a, b) => a < b ? a : b);
      minY = [minY, wall.start.dy, wall.end.dy].reduce((a, b) => a < b ? a : b);
      maxX = [maxX, wall.start.dx, wall.end.dx].reduce((a, b) => a > b ? a : b);
      maxY = [maxY, wall.start.dy, wall.end.dy].reduce((a, b) => a > b ? a : b);
    }

    return point.dx >= minX &&
        point.dx <= maxX &&
        point.dy >= minY &&
        point.dy <= maxY;
  }

  /// Convert camelCase/snake_case symbol type to human-readable.
  String _humanize(String s) {
    return s
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _PricingEntry {
  final double materialCost;
  final double laborCost;
  final double equipmentCost;

  const _PricingEntry({
    this.materialCost = 0,
    this.laborCost = 0,
    this.equipmentCost = 0,
  });
}
