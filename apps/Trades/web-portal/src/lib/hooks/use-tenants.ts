'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapTenant } from './pm-mappers';
import type { TenantData } from './pm-mappers';

export function useTenants() {
  const [tenants, setTenants] = useState<TenantData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTenants = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('tenants')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setTenants((data || []).map(mapTenant));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load tenants';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTenants();

    const supabase = getSupabase();
    const channel = supabase
      .channel('tenants-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tenants' }, () => {
        fetchTenants();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchTenants]);

  const createTenant = async (data: Partial<TenantData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('tenants')
      .insert({
        company_id: companyId,
        auth_user_id: data.authUserId || null,
        first_name: data.firstName || '',
        last_name: data.lastName || '',
        email: data.email || null,
        phone: data.phone || null,
        date_of_birth: data.dateOfBirth || null,
        emergency_contact_name: data.emergencyContactName || null,
        emergency_contact_phone: data.emergencyContactPhone || null,
        employer: data.employer || null,
        monthly_income: data.monthlyIncome || null,
        vehicle_info: data.vehicleInfo || null,
        pet_info: data.petInfo || null,
        notes: data.notes || null,
        status: data.status || 'applicant',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTenant = async (id: string, data: Partial<TenantData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.firstName !== undefined) updateData.first_name = data.firstName;
    if (data.lastName !== undefined) updateData.last_name = data.lastName;
    if (data.email !== undefined) updateData.email = data.email;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.dateOfBirth !== undefined) updateData.date_of_birth = data.dateOfBirth;
    if (data.emergencyContactName !== undefined) updateData.emergency_contact_name = data.emergencyContactName;
    if (data.emergencyContactPhone !== undefined) updateData.emergency_contact_phone = data.emergencyContactPhone;
    if (data.employer !== undefined) updateData.employer = data.employer;
    if (data.monthlyIncome !== undefined) updateData.monthly_income = data.monthlyIncome;
    if (data.vehicleInfo !== undefined) updateData.vehicle_info = data.vehicleInfo;
    if (data.petInfo !== undefined) updateData.pet_info = data.petInfo;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.authUserId !== undefined) updateData.auth_user_id = data.authUserId;

    const { error: err } = await supabase.from('tenants').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const deleteTenant = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('tenants')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  return {
    tenants,
    loading,
    error,
    createTenant,
    updateTenant,
    deleteTenant,
    refetch: fetchTenants,
  };
}

export function useTenant(id: string | undefined) {
  const [tenant, setTenant] = useState<TenantData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchTenant = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('tenants')
          .select('*')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        setTenant(data ? mapTenant(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Tenant not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchTenant();
    return () => { ignore = true; };
  }, [id]);

  return { tenant, loading, error };
}
