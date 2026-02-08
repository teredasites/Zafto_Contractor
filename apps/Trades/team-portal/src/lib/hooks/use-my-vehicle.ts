'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface VehicleData {
  id: string;
  companyId: string;
  assignedUserId: string | null;
  make: string;
  model: string;
  year: number;
  licensePlate: string;
  vin: string;
  color: string;
  currentMileage: number;
  status: 'active' | 'maintenance' | 'out_of_service' | 'retired';
  insuranceExpiry: string | null;
  registrationExpiry: string | null;
  lastInspection: string | null;
  notes: string;
  createdAt: string;
}

export interface VehicleMaintenanceData {
  id: string;
  vehicleId: string;
  maintenanceType: string;
  description: string;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  scheduledDate: string | null;
  completedDate: string | null;
  mileageAtService: number | null;
  cost: number;
  vendor: string;
  notes: string;
  createdAt: string;
}

export interface FuelLogData {
  id: string;
  vehicleId: string;
  userId: string;
  logDate: string;
  gallons: number;
  totalCost: number;
  pricePerGallon: number;
  mileage: number;
  station: string;
  notes: string;
  createdAt: string;
}

export interface FuelLogInput {
  logDate: string;
  gallons: number;
  totalCost: number;
  mileage: number;
  station: string;
  notes?: string;
}

export interface MaintenanceRequestInput {
  description: string;
  maintenanceType: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapVehicle(row: Record<string, unknown>): VehicleData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    assignedUserId: (row.assigned_user_id as string) || null,
    make: (row.make as string) || '',
    model: (row.model as string) || '',
    year: (row.year as number) || 0,
    licensePlate: (row.license_plate as string) || '',
    vin: (row.vin as string) || '',
    color: (row.color as string) || '',
    currentMileage: (row.current_mileage as number) || 0,
    status: (row.status as VehicleData['status']) || 'active',
    insuranceExpiry: (row.insurance_expiry as string) || null,
    registrationExpiry: (row.registration_expiry as string) || null,
    lastInspection: (row.last_inspection as string) || null,
    notes: (row.notes as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapMaintenance(row: Record<string, unknown>): VehicleMaintenanceData {
  return {
    id: row.id as string,
    vehicleId: row.vehicle_id as string,
    maintenanceType: (row.maintenance_type as string) || '',
    description: (row.description as string) || '',
    status: (row.status as VehicleMaintenanceData['status']) || 'scheduled',
    scheduledDate: (row.scheduled_date as string) || null,
    completedDate: (row.completed_date as string) || null,
    mileageAtService: (row.mileage_at_service as number) || null,
    cost: Number(row.cost || 0),
    vendor: (row.vendor as string) || '',
    notes: (row.notes as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

function mapFuelLog(row: Record<string, unknown>): FuelLogData {
  const gallons = Number(row.gallons || 0);
  const totalCost = Number(row.total_cost || 0);
  return {
    id: row.id as string,
    vehicleId: row.vehicle_id as string,
    userId: row.user_id as string,
    logDate: (row.log_date as string) || '',
    gallons,
    totalCost,
    pricePerGallon: gallons > 0 ? totalCost / gallons : 0,
    mileage: (row.mileage as number) || 0,
    station: (row.station as string) || '',
    notes: (row.notes as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ============================================================================
// HOOK: useMyVehicle (team portal — scoped to current user's assigned vehicle)
// ============================================================================

export function useMyVehicle() {
  const [vehicle, setVehicle] = useState<VehicleData | null>(null);
  const [maintenance, setMaintenance] = useState<VehicleMaintenanceData[]>([]);
  const [fuelLogs, setFuelLogs] = useState<FuelLogData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      // Fetch assigned vehicle
      const { data: vehicleData, error: vErr } = await supabase
        .from('vehicles')
        .select('*')
        .eq('assigned_user_id', user.id)
        .limit(1)
        .maybeSingle();

      if (vErr) throw vErr;

      if (!vehicleData) {
        setVehicle(null);
        setMaintenance([]);
        setFuelLogs([]);
        setLoading(false);
        return;
      }

      const mappedVehicle = mapVehicle(vehicleData as Record<string, unknown>);
      setVehicle(mappedVehicle);

      // Fetch maintenance and fuel logs for this vehicle
      const [maintRes, fuelRes] = await Promise.all([
        supabase
          .from('vehicle_maintenance')
          .select('*')
          .eq('vehicle_id', mappedVehicle.id)
          .order('scheduled_date', { ascending: false, nullsFirst: false })
          .limit(50),
        supabase
          .from('fuel_logs')
          .select('*')
          .eq('vehicle_id', mappedVehicle.id)
          .order('log_date', { ascending: false })
          .limit(50),
      ]);

      if (maintRes.error) throw maintRes.error;
      if (fuelRes.error) throw fuelRes.error;

      setMaintenance((maintRes.data || []).map((row: Record<string, unknown>) => mapMaintenance(row)));
      setFuelLogs((fuelRes.data || []).map((row: Record<string, unknown>) => mapFuelLog(row)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load vehicle data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-vehicle')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vehicles' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vehicle_maintenance' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'fuel_logs' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  // Computed: upcoming maintenance
  const upcomingMaintenance = useMemo(() =>
    maintenance.filter(m => m.status === 'scheduled' && m.scheduledDate).sort((a, b) => {
      const aTime = a.scheduledDate ? new Date(a.scheduledDate).getTime() : Infinity;
      const bTime = b.scheduledDate ? new Date(b.scheduledDate).getTime() : Infinity;
      return aTime - bTime;
    }),
    [maintenance]
  );

  const completedMaintenance = useMemo(() =>
    maintenance.filter(m => m.status === 'completed').sort((a, b) => {
      const aTime = a.completedDate ? new Date(a.completedDate).getTime() : 0;
      const bTime = b.completedDate ? new Date(b.completedDate).getTime() : 0;
      return bTime - aTime;
    }),
    [maintenance]
  );

  // Add fuel log
  const addFuelLog = async (input: FuelLogInput) => {
    if (!vehicle) throw new Error('No vehicle assigned');
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase.from('fuel_logs').insert({
      vehicle_id: vehicle.id,
      user_id: user.id,
      log_date: input.logDate,
      gallons: input.gallons,
      total_cost: input.totalCost,
      mileage: input.mileage,
      station: input.station,
      notes: input.notes || '',
    });

    if (err) throw err;
    await fetchData();
  };

  // Report issue (creates a maintenance request)
  const reportIssue = async (input: MaintenanceRequestInput) => {
    if (!vehicle) throw new Error('No vehicle assigned');
    const supabase = getSupabase();

    const { error: err } = await supabase.from('vehicle_maintenance').insert({
      vehicle_id: vehicle.id,
      maintenance_type: input.maintenanceType,
      description: input.description,
      status: 'scheduled',
      scheduled_date: new Date().toISOString(),
    });

    if (err) throw err;
    await fetchData();
  };

  return {
    vehicle, maintenance, fuelLogs,
    upcomingMaintenance, completedMaintenance,
    loading, error,
    addFuelLog, reportIssue,
    refetch: fetchData,
  };
}
