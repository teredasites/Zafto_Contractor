// ZAFTO Mold Remediation Repository
// Created: DEPTH35 — Assessments, moisture readings, remediation plans,
// equipment deployments, lab samples, clearance tests, state licensing.
//
// Tables: mold_assessments, mold_moisture_readings, mold_remediation_plans,
//         mold_equipment_deployments, mold_lab_samples, mold_clearance_tests,
//         mold_state_licensing

import '../core/supabase_client.dart';
import '../models/mold_remediation.dart';

class MoldRemediationRepository {
  static const _licensing = 'mold_state_licensing';
  static const _assessments = 'mold_assessments';
  static const _moistureReadings = 'mold_moisture_readings';
  static const _plans = 'mold_remediation_plans';
  static const _equipment = 'mold_equipment_deployments';
  static const _labSamples = 'mold_lab_samples';
  static const _clearance = 'mold_clearance_tests';

  // ══════════════════════════════════════════════════════════════
  // STATE LICENSING (system reference — read-only from app)
  // ══════════════════════════════════════════════════════════════

  /// Get all state licensing records
  Future<List<MoldStateLicensing>> getStateLicensing() async {
    final data = await supabase
        .from(_licensing)
        .select()
        .order('state_name');
    return data.map((row) => MoldStateLicensing.fromJson(row)).toList();
  }

  /// Get licensing for a specific state
  Future<MoldStateLicensing?> getStateLicensingByCode(String stateCode) async {
    final data = await supabase
        .from(_licensing)
        .select()
        .eq('state_code', stateCode)
        .maybeSingle();
    return data != null ? MoldStateLicensing.fromJson(data) : null;
  }

  /// Get states that require mold licensing
  Future<List<MoldStateLicensing>> getStatesRequiringLicense() async {
    final data = await supabase
        .from(_licensing)
        .select()
        .eq('license_required', true)
        .order('state_name');
    return data.map((row) => MoldStateLicensing.fromJson(row)).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // ASSESSMENTS
  // ══════════════════════════════════════════════════════════════

  /// Get all assessments for the company
  Future<List<MoldAssessment>> getAssessments(String companyId) async {
    final data = await supabase
        .from(_assessments)
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null)
        .order('assessment_date', ascending: false);
    return data.map((row) => MoldAssessment.fromJson(row)).toList();
  }

  /// Get assessments for a specific property
  Future<List<MoldAssessment>> getAssessmentsByProperty(
    String companyId,
    String propertyId,
  ) async {
    final data = await supabase
        .from(_assessments)
        .select()
        .eq('company_id', companyId)
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('assessment_date', ascending: false);
    return data.map((row) => MoldAssessment.fromJson(row)).toList();
  }

  /// Get assessments for a specific job
  Future<List<MoldAssessment>> getAssessmentsByJob(
    String companyId,
    String jobId,
  ) async {
    final data = await supabase
        .from(_assessments)
        .select()
        .eq('company_id', companyId)
        .eq('job_id', jobId)
        .isFilter('deleted_at', null)
        .order('assessment_date', ascending: false);
    return data.map((row) => MoldAssessment.fromJson(row)).toList();
  }

  /// Get single assessment by ID
  Future<MoldAssessment> getAssessment(String id) async {
    final data = await supabase
        .from(_assessments)
        .select()
        .eq('id', id)
        .single();
    return MoldAssessment.fromJson(data);
  }

  /// Create a new assessment
  Future<MoldAssessment> createAssessment(MoldAssessment assessment) async {
    final data = await supabase
        .from(_assessments)
        .insert(assessment.toJson())
        .select()
        .single();
    return MoldAssessment.fromJson(data);
  }

  /// Update an assessment (optimistic locking via updated_at)
  Future<MoldAssessment> updateAssessment(MoldAssessment assessment) async {
    final data = await supabase
        .from(_assessments)
        .update(assessment.toJson())
        .eq('id', assessment.id)
        .eq('updated_at', assessment.updatedAt)
        .select()
        .single();
    return MoldAssessment.fromJson(data);
  }

  /// Soft-delete an assessment
  Future<void> deleteAssessment(String id, String updatedAt) async {
    await supabase
        .from(_assessments)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  // ══════════════════════════════════════════════════════════════
  // MOISTURE READINGS (insert-only — sensor data is immutable)
  // ══════════════════════════════════════════════════════════════

  /// Get moisture readings for an assessment
  Future<List<MoldMoistureReading>> getMoistureReadings(
    String assessmentId,
  ) async {
    final data = await supabase
        .from(_moistureReadings)
        .select()
        .eq('assessment_id', assessmentId)
        .order('created_at', ascending: false);
    return data.map((row) => MoldMoistureReading.fromJson(row)).toList();
  }

  /// Get moisture readings by room
  Future<List<MoldMoistureReading>> getMoistureReadingsByRoom(
    String assessmentId,
    String roomName,
  ) async {
    final data = await supabase
        .from(_moistureReadings)
        .select()
        .eq('assessment_id', assessmentId)
        .eq('room_name', roomName)
        .order('created_at', ascending: false);
    return data.map((row) => MoldMoistureReading.fromJson(row)).toList();
  }

  /// Record a new moisture reading
  Future<MoldMoistureReading> createMoistureReading(
    MoldMoistureReading reading,
  ) async {
    final data = await supabase
        .from(_moistureReadings)
        .insert(reading.toJson())
        .select()
        .single();
    return MoldMoistureReading.fromJson(data);
  }

  // ══════════════════════════════════════════════════════════════
  // REMEDIATION PLANS
  // ══════════════════════════════════════════════════════════════

  /// Get remediation plans for the company
  Future<List<MoldRemediationPlan>> getRemediationPlans(
    String companyId,
  ) async {
    final data = await supabase
        .from(_plans)
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return data.map((row) => MoldRemediationPlan.fromJson(row)).toList();
  }

  /// Get plans for an assessment
  Future<List<MoldRemediationPlan>> getRemediationPlansByAssessment(
    String assessmentId,
  ) async {
    final data = await supabase
        .from(_plans)
        .select()
        .eq('assessment_id', assessmentId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return data.map((row) => MoldRemediationPlan.fromJson(row)).toList();
  }

  /// Get single plan
  Future<MoldRemediationPlan> getRemediationPlan(String id) async {
    final data = await supabase
        .from(_plans)
        .select()
        .eq('id', id)
        .single();
    return MoldRemediationPlan.fromJson(data);
  }

  /// Create a new remediation plan
  Future<MoldRemediationPlan> createRemediationPlan(
    MoldRemediationPlan plan,
  ) async {
    final data = await supabase
        .from(_plans)
        .insert(plan.toJson())
        .select()
        .single();
    return MoldRemediationPlan.fromJson(data);
  }

  /// Update a remediation plan (optimistic locking)
  Future<MoldRemediationPlan> updateRemediationPlan(
    MoldRemediationPlan plan,
  ) async {
    final data = await supabase
        .from(_plans)
        .update(plan.toJson())
        .eq('id', plan.id)
        .eq('updated_at', plan.updatedAt)
        .select()
        .single();
    return MoldRemediationPlan.fromJson(data);
  }

  /// Update plan status
  Future<void> updatePlanStatus(
    String id,
    String updatedAt,
    RemediationPlanStatus status,
  ) async {
    final patch = <String, dynamic>{'status': status.toJson()};
    final now = DateTime.now().toUtc().toIso8601String();
    if (status == RemediationPlanStatus.inProgress) {
      patch['started_at'] = now;
    } else if (status == RemediationPlanStatus.completed) {
      patch['completed_at'] = now;
    }
    await supabase
        .from(_plans)
        .update(patch)
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  /// Soft-delete a remediation plan
  Future<void> deleteRemediationPlan(String id, String updatedAt) async {
    await supabase
        .from(_plans)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  // ══════════════════════════════════════════════════════════════
  // EQUIPMENT DEPLOYMENTS
  // ══════════════════════════════════════════════════════════════

  /// Get equipment deployments for a remediation
  Future<List<MoldEquipmentDeployment>> getEquipmentByRemediation(
    String remediationId,
  ) async {
    final data = await supabase
        .from(_equipment)
        .select()
        .eq('remediation_id', remediationId)
        .order('deployed_at', ascending: false);
    return data.map((row) => MoldEquipmentDeployment.fromJson(row)).toList();
  }

  /// Get currently deployed equipment for company
  Future<List<MoldEquipmentDeployment>> getActiveDeployments(
    String companyId,
  ) async {
    final data = await supabase
        .from(_equipment)
        .select()
        .eq('company_id', companyId)
        .isFilter('retrieved_at', null)
        .order('deployed_at', ascending: false);
    return data.map((row) => MoldEquipmentDeployment.fromJson(row)).toList();
  }

  /// Deploy equipment
  Future<MoldEquipmentDeployment> createEquipmentDeployment(
    MoldEquipmentDeployment deployment,
  ) async {
    final json = deployment.toJson();
    json['deployed_at'] = deployment.deployedAt;
    final data = await supabase
        .from(_equipment)
        .insert(json)
        .select()
        .single();
    return MoldEquipmentDeployment.fromJson(data);
  }

  /// Update equipment deployment (e.g. update placement, notes)
  Future<MoldEquipmentDeployment> updateEquipmentDeployment(
    MoldEquipmentDeployment deployment,
  ) async {
    final json = deployment.toJson();
    final data = await supabase
        .from(_equipment)
        .update(json)
        .eq('id', deployment.id)
        .eq('updated_at', deployment.updatedAt)
        .select()
        .single();
    return MoldEquipmentDeployment.fromJson(data);
  }

  /// Mark equipment as retrieved
  Future<void> retrieveEquipment(
    String id,
    String updatedAt, {
    double? runtimeHours,
  }) async {
    await supabase
        .from(_equipment)
        .update({
          'retrieved_at': DateTime.now().toUtc().toIso8601String(),
          'runtime_hours': runtimeHours,
        })
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  // ══════════════════════════════════════════════════════════════
  // LAB SAMPLES
  // ══════════════════════════════════════════════════════════════

  /// Get lab samples for an assessment
  Future<List<MoldLabSample>> getLabSamplesByAssessment(
    String assessmentId,
  ) async {
    final data = await supabase
        .from(_labSamples)
        .select()
        .eq('assessment_id', assessmentId)
        .isFilter('deleted_at', null)
        .order('date_collected', ascending: false);
    return data.map((row) => MoldLabSample.fromJson(row)).toList();
  }

  /// Get all lab samples for company
  Future<List<MoldLabSample>> getLabSamples(String companyId) async {
    final data = await supabase
        .from(_labSamples)
        .select()
        .eq('company_id', companyId)
        .isFilter('deleted_at', null)
        .order('date_collected', ascending: false);
    return data.map((row) => MoldLabSample.fromJson(row)).toList();
  }

  /// Get single lab sample
  Future<MoldLabSample> getLabSample(String id) async {
    final data = await supabase
        .from(_labSamples)
        .select()
        .eq('id', id)
        .single();
    return MoldLabSample.fromJson(data);
  }

  /// Create a lab sample record
  Future<MoldLabSample> createLabSample(MoldLabSample sample) async {
    final json = sample.toJson();
    json['date_collected'] = sample.dateCollected;
    json['collected_by'] = sample.collectedBy;
    final data = await supabase
        .from(_labSamples)
        .insert(json)
        .select()
        .single();
    return MoldLabSample.fromJson(data);
  }

  /// Update a lab sample (e.g. record results)
  Future<MoldLabSample> updateLabSample(MoldLabSample sample) async {
    final json = sample.toJson();
    final data = await supabase
        .from(_labSamples)
        .update(json)
        .eq('id', sample.id)
        .eq('updated_at', sample.updatedAt)
        .select()
        .single();
    return MoldLabSample.fromJson(data);
  }

  /// Update lab sample status
  Future<void> updateLabSampleStatus(
    String id,
    String updatedAt,
    LabSampleStatus status,
  ) async {
    await supabase
        .from(_labSamples)
        .update({'status': status.toJson()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  /// Soft-delete a lab sample
  Future<void> deleteLabSample(String id, String updatedAt) async {
    await supabase
        .from(_labSamples)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }

  // ══════════════════════════════════════════════════════════════
  // CLEARANCE TESTS
  // ══════════════════════════════════════════════════════════════

  /// Get clearance tests for a remediation
  Future<List<MoldClearanceTest>> getClearanceTestsByRemediation(
    String remediationId,
  ) async {
    final data = await supabase
        .from(_clearance)
        .select()
        .eq('remediation_id', remediationId)
        .isFilter('deleted_at', null)
        .order('clearance_date', ascending: false);
    return data.map((row) => MoldClearanceTest.fromJson(row)).toList();
  }

  /// Get clearance tests for an assessment
  Future<List<MoldClearanceTest>> getClearanceTestsByAssessment(
    String assessmentId,
  ) async {
    final data = await supabase
        .from(_clearance)
        .select()
        .eq('assessment_id', assessmentId)
        .isFilter('deleted_at', null)
        .order('clearance_date', ascending: false);
    return data.map((row) => MoldClearanceTest.fromJson(row)).toList();
  }

  /// Get single clearance test
  Future<MoldClearanceTest> getClearanceTest(String id) async {
    final data = await supabase
        .from(_clearance)
        .select()
        .eq('id', id)
        .single();
    return MoldClearanceTest.fromJson(data);
  }

  /// Create a clearance test
  Future<MoldClearanceTest> createClearanceTest(
    MoldClearanceTest test,
  ) async {
    final json = test.toJson();
    json['clearance_date'] = test.clearanceDate;
    final data = await supabase
        .from(_clearance)
        .insert(json)
        .select()
        .single();
    return MoldClearanceTest.fromJson(data);
  }

  /// Update a clearance test (optimistic locking)
  Future<MoldClearanceTest> updateClearanceTest(
    MoldClearanceTest test,
  ) async {
    final json = test.toJson();
    json['certificate_url'] = test.certificateUrl;
    final data = await supabase
        .from(_clearance)
        .update(json)
        .eq('id', test.id)
        .eq('updated_at', test.updatedAt)
        .select()
        .single();
    return MoldClearanceTest.fromJson(data);
  }

  /// Soft-delete a clearance test
  Future<void> deleteClearanceTest(String id, String updatedAt) async {
    await supabase
        .from(_clearance)
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('updated_at', updatedAt);
  }
}
