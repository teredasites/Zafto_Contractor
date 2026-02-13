// ZAFTO Estimate Area Generator — SK8
// Converts RoomMeasurements into estimate_areas rows.
// Links floor plan rooms to estimates via floor_plan_estimate_links bridge table.
// Sets auto_generated=true for all generated areas.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/estimate.dart';
import 'room_measurement_calculator.dart';

// =============================================================================
// GENERATED AREA RESULT
// =============================================================================

class GeneratedEstimateResult {
  final String estimateId;
  final List<GeneratedArea> areas;

  const GeneratedEstimateResult({
    required this.estimateId,
    required this.areas,
  });
}

class GeneratedArea {
  final String areaId;
  final String roomId;
  final String roomName;
  final RoomMeasurements measurements;

  const GeneratedArea({
    required this.areaId,
    required this.roomId,
    required this.roomName,
    required this.measurements,
  });
}

// =============================================================================
// GENERATOR
// =============================================================================

class EstimateAreaGenerator {
  /// Generate an estimate from room measurements.
  ///
  /// Flow:
  /// 1. Create new estimate row (draft status)
  /// 2. For each room measurement → create estimate_area row
  /// 3. Create floor_plan_estimate_links bridge records
  /// 4. Return generated result with IDs for line item population
  Future<GeneratedEstimateResult> generateFromMeasurements({
    required String companyId,
    required String floorPlanId,
    required String createdBy,
    required List<RoomMeasurements> measurements,
    String? jobId,
    String? customerId,
    String? propertyAddress,
    String title = 'Floor Plan Estimate',
  }) async {
    if (measurements.isEmpty) {
      throw ValidationError('No rooms to generate estimate from');
    }

    try {
      // 1. Create estimate
      final estimateResponse = await supabase
          .from('estimates')
          .insert({
            'company_id': companyId,
            'created_by': createdBy,
            'title': title,
            'estimate_type': 'regular',
            'status': 'draft',
            if (jobId != null) 'job_id': jobId,
            if (customerId != null) 'customer_id': customerId,
            if (propertyAddress != null) 'property_address': propertyAddress,
            'property_floor_plan_id': floorPlanId,
          })
          .select('id')
          .single();

      final estimateId = estimateResponse['id'] as String;

      // 2. Create areas from measurements
      final generatedAreas = <GeneratedArea>[];
      for (var i = 0; i < measurements.length; i++) {
        final m = measurements[i];

        final areaResponse = await supabase
            .from('estimate_areas')
            .insert({
              'estimate_id': estimateId,
              'name': m.roomName,
              'floor_number': 1,
              'area_sf': m.floorSf,
              'wall_sf': m.wallSf,
              'ceiling_sf': m.ceilingSf,
              'baseboard_lf': m.baseboardLf,
              'perimeter_ft': m.perimeterLf,
              'height_ft': m.wallHeight / 12.0,
              'window_count': m.windowCount,
              'door_count': m.doorCount,
              'sort_order': i,
            })
            .select('id')
            .single();

        final areaId = areaResponse['id'] as String;

        // 3. Create bridge link
        await supabase.from('floor_plan_estimate_links').insert({
          'floor_plan_id': floorPlanId,
          'room_id': m.roomId,
          'estimate_id': estimateId,
          'estimate_area_id': areaId,
          'auto_generated': true,
          'company_id': companyId,
        });

        generatedAreas.add(GeneratedArea(
          areaId: areaId,
          roomId: m.roomId,
          roomName: m.roomName,
          measurements: m,
        ));
      }

      return GeneratedEstimateResult(
        estimateId: estimateId,
        areas: generatedAreas,
      );
    } catch (e) {
      if (e is ValidationError) rethrow;
      throw DatabaseError(
        'Failed to generate estimate from floor plan: $e',
        cause: e,
      );
    }
  }
}
