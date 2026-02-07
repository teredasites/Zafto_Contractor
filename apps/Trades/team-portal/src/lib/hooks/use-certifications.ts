'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapCertification, mapCertificationType, type CertificationData, type CertificationTypeConfig } from './mappers';

// Employee sees their own certifications only (filtered by auth.uid())
export function useMyCertifications() {
  const [certifications, setCertifications] = useState<CertificationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCertifications = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const { data, error: err } = await supabase
        .from('certifications')
        .select('*')
        .eq('user_id', user.id)
        .order('expiration_date', { ascending: true, nullsFirst: false });

      if (err) throw err;
      setCertifications((data || []).map(mapCertification));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load certifications';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCertifications();

    const supabase = getSupabase();
    const channel = supabase
      .channel('team-certifications')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certifications' }, () => {
        fetchCertifications();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchCertifications]);

  return { certifications, loading, error, refresh: fetchCertifications };
}

// Fetch certification types (system defaults + company custom)
export function useCertificationTypes() {
  const [types, setTypes] = useState<CertificationTypeConfig[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTypes = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('certification_types')
        .select('*')
        .eq('is_active', true)
        .order('sort_order');

      if (err) throw err;
      setTypes((data || []).map(mapCertificationType));
    } catch {
      // If table doesn't exist yet, types will be empty
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTypes();
  }, [fetchTypes]);

  const typeMap = Object.fromEntries(types.map(t => [t.typeKey, t]));

  return { types, typeMap, loading };
}
