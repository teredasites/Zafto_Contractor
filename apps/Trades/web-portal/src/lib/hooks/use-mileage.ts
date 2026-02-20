'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

export type TripType = 'business' | 'personal' | 'commute' | 'medical' | 'charity';

// IRS Standard Mileage Rates (2025 rates — update annually)
const IRS_RATES: Record<TripType, number> = {
  business: 0.70,
  medical: 0.21,
  charity: 0.14,
  personal: 0,
  commute: 0,
};

export interface MileageTripData {
  id: string;
  companyId: string;
  userId: string;
  jobId: string | null;
  startAddress: string;
  endAddress: string;
  distanceMiles: number;
  startOdometer: number | null;
  endOdometer: number | null;
  purpose: string;
  tripType: TripType;
  tripDate: string;
  startLatitude: number | null;
  startLongitude: number | null;
  endLatitude: number | null;
  endLongitude: number | null;
  routeData: Record<string, unknown>;
  deductionAmount: number;
  createdAt: string;
}

function mapTrip(row: Record<string, unknown>): MileageTripData {
  const tripType = (row.trip_type as TripType) || 'business';
  const distanceMiles = (row.distance_miles as number) || 0;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    userId: (row.user_id as string) || '',
    jobId: (row.job_id as string) || null,
    startAddress: (row.start_address as string) || '',
    endAddress: (row.end_address as string) || '',
    distanceMiles,
    startOdometer: (row.start_odometer as number) ?? null,
    endOdometer: (row.end_odometer as number) ?? null,
    purpose: (row.purpose as string) || '',
    tripType,
    tripDate: (row.trip_date as string) || '',
    startLatitude: (row.start_latitude as number) ?? null,
    startLongitude: (row.start_longitude as number) ?? null,
    endLatitude: (row.end_latitude as number) ?? null,
    endLongitude: (row.end_longitude as number) ?? null,
    routeData: (row.route_data as Record<string, unknown>) || {},
    deductionAmount: distanceMiles * (IRS_RATES[tripType] || 0),
    createdAt: (row.created_at as string) || '',
  };
}

export function useMileage(options?: { userId?: string; dateRange?: { start: string; end: string } }) {
  const [trips, setTrips] = useState<MileageTripData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTrips = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('mileage_trips')
        .select('*')
        .is('deleted_at', null)
        .order('trip_date', { ascending: false });

      if (options?.userId) query = query.eq('user_id', options.userId);
      if (options?.dateRange) {
        query = query.gte('trip_date', options.dateRange.start).lte('trip_date', options.dateRange.end);
      }
      const { data, error: err } = await query;
      if (err) throw err;
      setTrips((data || []).map(mapTrip));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load mileage trips');
    } finally {
      setLoading(false);
    }
  }, [options?.userId, options?.dateRange?.start, options?.dateRange?.end]);

  useEffect(() => {
    fetchTrips();
    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-mileage')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'mileage_trips' }, () => fetchTrips())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchTrips]);

  const addTrip = async (data: {
    startAddress: string;
    endAddress: string;
    distanceMiles: number;
    purpose: string;
    tripType?: TripType;
    jobId?: string;
    tripDate?: string;
    startOdometer?: number;
    endOdometer?: number;
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error: err } = await supabase.from('mileage_trips').insert({
        company_id: user.app_metadata?.company_id,
        user_id: user.id,
        start_address: data.startAddress,
        end_address: data.endAddress,
        distance_miles: data.distanceMiles,
        purpose: data.purpose,
        trip_type: data.tripType || 'business',
        job_id: data.jobId || null,
        trip_date: data.tripDate || new Date().toISOString().split('T')[0],
        start_odometer: data.startOdometer ?? null,
        end_odometer: data.endOdometer ?? null,
      });
      if (err) throw err;
      await fetchTrips();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to add mileage trip');
      throw e;
    }
  };

  const deleteTrip = async (tripId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('mileage_trips')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', tripId);
      if (err) throw err;
      await fetchTrips();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete mileage trip');
      throw e;
    }
  };

  // Summaries
  const businessTrips = useMemo(() => trips.filter(t => t.tripType === 'business'), [trips]);
  const totalMiles = useMemo(() => trips.reduce((sum, t) => sum + t.distanceMiles, 0), [trips]);
  const totalBusinessMiles = useMemo(() => businessTrips.reduce((sum, t) => sum + t.distanceMiles, 0), [businessTrips]);
  const totalDeduction = useMemo(() => trips.reduce((sum, t) => sum + t.deductionAmount, 0), [trips]);

  // Monthly summary
  const monthlySummary = useMemo(() => {
    const months: Record<string, { miles: number; deduction: number; trips: number }> = {};
    for (const trip of trips) {
      const month = trip.tripDate.substring(0, 7); // YYYY-MM
      if (!months[month]) months[month] = { miles: 0, deduction: 0, trips: 0 };
      months[month].miles += trip.distanceMiles;
      months[month].deduction += trip.deductionAmount;
      months[month].trips += 1;
    }
    return Object.entries(months)
      .map(([month, data]) => ({ month, ...data }))
      .sort((a, b) => b.month.localeCompare(a.month));
  }, [trips]);

  return {
    trips,
    loading,
    error,
    addTrip,
    deleteTrip,
    businessTrips,
    totalMiles,
    totalBusinessMiles,
    totalDeduction,
    monthlySummary,
    irsRates: IRS_RATES,
    refresh: fetchTrips,
  };
}
