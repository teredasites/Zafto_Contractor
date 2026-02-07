'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';
import {
  mapTenant, mapLease, mapProperty, mapUnit,
  type TenantData, type LeaseData, type PropertyInfo, type UnitInfo,
} from './tenant-mappers';

export function useTenant() {
  const { user } = useAuth();
  const [tenant, setTenant] = useState<TenantData | null>(null);
  const [lease, setLease] = useState<LeaseData | null>(null);
  const [property, setProperty] = useState<PropertyInfo | null>(null);
  const [unit, setUnit] = useState<UnitInfo | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchTenant = useCallback(async () => {
    if (!user) { setLoading(false); return; }
    const supabase = getSupabase();

    // RLS tenants_self: auth_user_id = auth.uid()
    const { data: tenantRow } = await supabase
      .from('tenants')
      .select('*')
      .eq('auth_user_id', user.id)
      .is('deleted_at', null)
      .maybeSingle();

    if (!tenantRow) {
      setTenant(null);
      setLease(null);
      setProperty(null);
      setUnit(null);
      setLoading(false);
      return;
    }

    const t = mapTenant(tenantRow);
    setTenant(t);

    // Get active lease for this tenant
    const { data: leaseRow } = await supabase
      .from('leases')
      .select('*')
      .eq('tenant_id', t.id)
      .in('status', ['active', 'month_to_month', 'expiring'])
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (leaseRow) {
      const l = mapLease(leaseRow);
      setLease(l);

      // Get property + unit in parallel
      const [propRes, unitRes] = await Promise.all([
        supabase.from('properties').select('*').eq('id', l.propertyId).single(),
        supabase.from('units').select('*').eq('id', l.unitId).single(),
      ]);

      if (propRes.data) setProperty(mapProperty(propRes.data));
      if (unitRes.data) setUnit(mapUnit(unitRes.data));
    } else {
      setLease(null);
      setProperty(null);
      setUnit(null);
    }

    setLoading(false);
  }, [user]);

  useEffect(() => {
    fetchTenant();
  }, [fetchTenant]);

  return { tenant, lease, property, unit, loading, refresh: fetchTenant };
}
