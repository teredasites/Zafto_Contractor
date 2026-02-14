'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ────────────────────────────────────────────────────────
// Types
// ────────────────────────────────────────────────────────

export type VehicleType = 'truck' | 'van' | 'trailer' | 'car' | 'equipment' | 'other';
export type VehicleStatus = 'active' | 'maintenance' | 'out_of_service' | 'retired';
export type MaintenanceType =
  | 'oil_change' | 'tire_rotation' | 'brake_service' | 'inspection'
  | 'engine' | 'transmission' | 'electrical' | 'body' | 'scheduled_service' | 'other';
export type MaintenanceStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
export type MaintenancePriority = 'low' | 'medium' | 'high' | 'critical';
export type FuelType = 'regular' | 'premium' | 'diesel' | 'e85';

export interface Vehicle {
  id: string;
  companyId: string;
  vehicleName: string;
  vehicleType: VehicleType;
  year: number | null;
  make: string | null;
  model: string | null;
  vin: string | null;
  licensePlate: string | null;
  color: string | null;
  currentOdometer: number | null;
  assignedToUserId: string | null;
  status: VehicleStatus;
  insurancePolicyNumber: string | null;
  insuranceExpiry: string | null;
  registrationExpiry: string | null;
  gpsDeviceId: string | null;
  lastGpsLat: number | null;
  lastGpsLng: number | null;
  lastGpsTimestamp: string | null;
  dailyRate: number | null;
  notes: string | null;
  photoPath: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface VehicleMaintenance {
  id: string;
  companyId: string;
  vehicleId: string;
  maintenanceType: MaintenanceType;
  title: string;
  description: string | null;
  status: MaintenanceStatus;
  priority: MaintenancePriority;
  scheduledDate: string | null;
  completedDate: string | null;
  completedByUserId: string | null;
  vendorName: string | null;
  partsCost: number | null;
  laborCost: number | null;
  totalCost: number | null;
  odometerAtService: number | null;
  nextDueDate: string | null;
  nextDueOdometer: number | null;
  receiptPath: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface FuelLog {
  id: string;
  companyId: string;
  vehicleId: string;
  loggedByUserId: string | null;
  fuelDate: string;
  gallons: number;
  pricePerGallon: number;
  totalCost: number;
  odometer: number | null;
  stationName: string | null;
  fuelType: FuelType;
  receiptPath: string | null;
  notes: string | null;
  createdAt: string;
}

// ────────────────────────────────────────────────────────
// Mappers (snake_case DB → camelCase TS)
// ────────────────────────────────────────────────────────

function mapVehicle(row: Record<string, unknown>): Vehicle {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    vehicleName: (row.vehicle_name as string) || '',
    vehicleType: (row.vehicle_type as VehicleType) || 'other',
    year: row.year != null ? Number(row.year) : null,
    make: (row.make as string) || null,
    model: (row.model as string) || null,
    vin: (row.vin as string) || null,
    licensePlate: (row.license_plate as string) || null,
    color: (row.color as string) || null,
    currentOdometer: row.current_odometer != null ? Number(row.current_odometer) : null,
    assignedToUserId: (row.assigned_to_user_id as string) || null,
    status: (row.status as VehicleStatus) || 'active',
    insurancePolicyNumber: (row.insurance_policy_number as string) || null,
    insuranceExpiry: (row.insurance_expiry as string) || null,
    registrationExpiry: (row.registration_expiry as string) || null,
    gpsDeviceId: (row.gps_device_id as string) || null,
    lastGpsLat: row.last_gps_lat != null ? Number(row.last_gps_lat) : null,
    lastGpsLng: row.last_gps_lng != null ? Number(row.last_gps_lng) : null,
    lastGpsTimestamp: (row.last_gps_timestamp as string) || null,
    dailyRate: row.daily_rate != null ? Number(row.daily_rate) : null,
    notes: (row.notes as string) || null,
    photoPath: (row.photo_path as string) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapMaintenance(row: Record<string, unknown>): VehicleMaintenance {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    vehicleId: (row.vehicle_id as string) || '',
    maintenanceType: (row.maintenance_type as MaintenanceType) || 'other',
    title: (row.title as string) || '',
    description: (row.description as string) || null,
    status: (row.status as MaintenanceStatus) || 'scheduled',
    priority: (row.priority as MaintenancePriority) || 'medium',
    scheduledDate: (row.scheduled_date as string) || null,
    completedDate: (row.completed_date as string) || null,
    completedByUserId: (row.completed_by_user_id as string) || null,
    vendorName: (row.vendor_name as string) || null,
    partsCost: row.parts_cost != null ? Number(row.parts_cost) : null,
    laborCost: row.labor_cost != null ? Number(row.labor_cost) : null,
    totalCost: row.total_cost != null ? Number(row.total_cost) : null,
    odometerAtService: row.odometer_at_service != null ? Number(row.odometer_at_service) : null,
    nextDueDate: (row.next_due_date as string) || null,
    nextDueOdometer: row.next_due_odometer != null ? Number(row.next_due_odometer) : null,
    receiptPath: (row.receipt_path as string) || null,
    notes: (row.notes as string) || null,
    createdAt: (row.created_at as string) || '',
    updatedAt: (row.updated_at as string) || '',
  };
}

function mapFuelLog(row: Record<string, unknown>): FuelLog {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    vehicleId: (row.vehicle_id as string) || '',
    loggedByUserId: (row.logged_by_user_id as string) || null,
    fuelDate: (row.fuel_date as string) || '',
    gallons: Number(row.gallons || 0),
    pricePerGallon: Number(row.price_per_gallon || 0),
    totalCost: Number(row.total_cost || 0),
    odometer: row.odometer != null ? Number(row.odometer) : null,
    stationName: (row.station_name as string) || null,
    fuelType: (row.fuel_type as FuelType) || 'regular',
    receiptPath: (row.receipt_path as string) || null,
    notes: (row.notes as string) || null,
    createdAt: (row.created_at as string) || '',
  };
}

// ────────────────────────────────────────────────────────
// Hook
// ────────────────────────────────────────────────────────

export function useFleet() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [maintenance, setMaintenance] = useState<VehicleMaintenance[]>([]);
  const [fuelLogs, setFuelLogs] = useState<FuelLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [vehiclesRes, maintenanceRes, fuelRes] = await Promise.all([
        supabase.from('vehicles').select('*').order('created_at', { ascending: false }),
        supabase.from('vehicle_maintenance').select('*').order('scheduled_date', { ascending: false }),
        supabase.from('fuel_logs').select('*').order('fuel_date', { ascending: false }),
      ]);

      if (vehiclesRes.error) throw vehiclesRes.error;
      if (maintenanceRes.error) throw maintenanceRes.error;
      if (fuelRes.error) throw fuelRes.error;

      setVehicles((vehiclesRes.data || []).map(mapVehicle));
      setMaintenance((maintenanceRes.data || []).map(mapMaintenance));
      setFuelLogs((fuelRes.data || []).map(mapFuelLog));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load fleet data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('vehicles-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vehicles' }, () => {
        fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchData]);

  // ── Mutations ──

  const addVehicle = async (data: Partial<Vehicle>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('vehicles')
      .insert({
        company_id: companyId,
        vehicle_name: data.vehicleName || 'Unnamed Vehicle',
        vehicle_type: data.vehicleType || 'other',
        year: data.year || null,
        make: data.make || null,
        model: data.model || null,
        vin: data.vin || null,
        license_plate: data.licensePlate || null,
        color: data.color || null,
        current_odometer: data.currentOdometer || null,
        assigned_to_user_id: data.assignedToUserId || null,
        status: data.status || 'active',
        insurance_policy_number: data.insurancePolicyNumber || null,
        insurance_expiry: data.insuranceExpiry || null,
        registration_expiry: data.registrationExpiry || null,
        gps_device_id: data.gpsDeviceId || null,
        daily_rate: data.dailyRate || null,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateVehicle = async (id: string, data: Partial<Vehicle>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.vehicleName !== undefined) updateData.vehicle_name = data.vehicleName;
    if (data.vehicleType !== undefined) updateData.vehicle_type = data.vehicleType;
    if (data.year !== undefined) updateData.year = data.year;
    if (data.make !== undefined) updateData.make = data.make;
    if (data.model !== undefined) updateData.model = data.model;
    if (data.vin !== undefined) updateData.vin = data.vin;
    if (data.licensePlate !== undefined) updateData.license_plate = data.licensePlate;
    if (data.color !== undefined) updateData.color = data.color;
    if (data.currentOdometer !== undefined) updateData.current_odometer = data.currentOdometer;
    if (data.assignedToUserId !== undefined) updateData.assigned_to_user_id = data.assignedToUserId;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.insurancePolicyNumber !== undefined) updateData.insurance_policy_number = data.insurancePolicyNumber;
    if (data.insuranceExpiry !== undefined) updateData.insurance_expiry = data.insuranceExpiry;
    if (data.registrationExpiry !== undefined) updateData.registration_expiry = data.registrationExpiry;
    if (data.dailyRate !== undefined) updateData.daily_rate = data.dailyRate;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase.from('vehicles').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const addMaintenance = async (data: Partial<VehicleMaintenance>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('vehicle_maintenance')
      .insert({
        company_id: companyId,
        vehicle_id: data.vehicleId,
        maintenance_type: data.maintenanceType || 'other',
        title: data.title || 'Untitled Maintenance',
        description: data.description || null,
        status: data.status || 'scheduled',
        priority: data.priority || 'medium',
        scheduled_date: data.scheduledDate || null,
        completed_date: data.completedDate || null,
        completed_by_user_id: data.completedByUserId || null,
        vendor_name: data.vendorName || null,
        parts_cost: data.partsCost || null,
        labor_cost: data.laborCost || null,
        total_cost: data.totalCost || null,
        odometer_at_service: data.odometerAtService || null,
        next_due_date: data.nextDueDate || null,
        next_due_odometer: data.nextDueOdometer || null,
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateMaintenance = async (id: string, data: Partial<VehicleMaintenance>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.maintenanceType !== undefined) updateData.maintenance_type = data.maintenanceType;
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.priority !== undefined) updateData.priority = data.priority;
    if (data.scheduledDate !== undefined) updateData.scheduled_date = data.scheduledDate;
    if (data.completedDate !== undefined) updateData.completed_date = data.completedDate;
    if (data.completedByUserId !== undefined) updateData.completed_by_user_id = data.completedByUserId;
    if (data.vendorName !== undefined) updateData.vendor_name = data.vendorName;
    if (data.partsCost !== undefined) updateData.parts_cost = data.partsCost;
    if (data.laborCost !== undefined) updateData.labor_cost = data.laborCost;
    if (data.totalCost !== undefined) updateData.total_cost = data.totalCost;
    if (data.odometerAtService !== undefined) updateData.odometer_at_service = data.odometerAtService;
    if (data.nextDueDate !== undefined) updateData.next_due_date = data.nextDueDate;
    if (data.nextDueOdometer !== undefined) updateData.next_due_odometer = data.nextDueOdometer;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase.from('vehicle_maintenance').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const addFuelLog = async (data: Partial<FuelLog>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('fuel_logs')
      .insert({
        company_id: companyId,
        vehicle_id: data.vehicleId,
        logged_by_user_id: user.id,
        fuel_date: data.fuelDate || new Date().toISOString().split('T')[0],
        gallons: data.gallons || 0,
        price_per_gallon: data.pricePerGallon || 0,
        total_cost: data.totalCost || 0,
        odometer: data.odometer || null,
        station_name: data.stationName || null,
        fuel_type: data.fuelType || 'regular',
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  // ── Computed values ──

  const activeVehicles = useMemo(
    () => vehicles.filter((v) => v.status === 'active'),
    [vehicles]
  );

  const maintenanceDue = useMemo(() => {
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    const cutoff = thirtyDaysFromNow.toISOString().split('T')[0];

    return maintenance.filter((m) => {
      if (m.status === 'completed' || m.status === 'cancelled') return false;
      if (m.status === 'scheduled') return true;
      if (m.nextDueDate && m.nextDueDate <= cutoff) return true;
      return false;
    });
  }, [maintenance]);

  const totalFleetCost = useMemo(() => {
    const fuelTotal = fuelLogs.reduce((sum, f) => sum + f.totalCost, 0);
    const maintenanceTotal = maintenance.reduce((sum, m) => sum + (m.totalCost || 0), 0);
    return fuelTotal + maintenanceTotal;
  }, [fuelLogs, maintenance]);

  // U22: Fleet → Ledger — auto-create expense from maintenance/fuel
  const createExpenseFromMaintenance = async (maintenanceId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    const record = maintenance.find((m) => m.id === maintenanceId);
    if (!record || !record.totalCost) return;

    await supabase.from('expenses').insert({
      company_id: companyId,
      created_by_user_id: user.id,
      category: 'vehicle_maintenance',
      description: `${record.title} — ${record.vehicleId}`,
      amount: record.totalCost,
      date: record.completedDate || new Date().toISOString(),
      vendor_name: record.vendorName || null,
    });
  };

  const createExpenseFromFuel = async (fuelLogId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    const companyId = user.app_metadata?.company_id;
    const record = fuelLogs.find((f) => f.id === fuelLogId);
    if (!record || !record.totalCost) return;

    await supabase.from('expenses').insert({
      company_id: companyId,
      created_by_user_id: user.id,
      category: 'fuel',
      description: `Fuel — ${record.gallons}gal`,
      amount: record.totalCost,
      date: record.fuelDate || new Date().toISOString(),
    });
  };

  // U22: Fleet → Dispatch — assign vehicle to tech
  const assignVehicleToUser = async (vehicleId: string, userId: string | null) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('vehicles').update({ assigned_to_user_id: userId }).eq('id', vehicleId);
    if (err) throw err;
  };

  return {
    vehicles,
    maintenance,
    fuelLogs,
    loading,
    error,
    addVehicle,
    updateVehicle,
    addMaintenance,
    updateMaintenance,
    addFuelLog,
    activeVehicles,
    maintenanceDue,
    totalFleetCost,
    createExpenseFromMaintenance,
    createExpenseFromFuel,
    assignVehicleToUser,
    refetch: fetchData,
  };
}
