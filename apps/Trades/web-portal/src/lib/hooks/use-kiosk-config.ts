'use client';

// Kiosk Config hook — CRUD for kiosk time clock stations
// Manages: kiosk configs, access tokens, employee PINs

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export interface KioskAuthMethods {
  pin: boolean;
  password: boolean;
  face: boolean;
  name_tap: boolean;
}

export interface KioskSettings {
  auto_break_minutes: number;
  require_job_selection: boolean;
  allowed_hours_start: string | null;
  allowed_hours_end: string | null;
  show_company_logo: boolean;
  idle_timeout_seconds: number;
  allow_break_toggle: boolean;
  restrict_ip_ranges: string[];
  greeting_message: string | null;
}

export interface KioskBranding {
  primary_color: string | null;
  logo_url: string | null;
  background_url: string | null;
}

export interface KioskConfigData {
  id: string;
  companyId: string;
  name: string;
  accessToken: string;
  isActive: boolean;
  authMethods: KioskAuthMethods;
  settings: KioskSettings;
  branding: KioskBranding;
  createdBy: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface EmployeePin {
  id: string;
  userId: string;
  userName: string | null;
  hasPin: boolean;
  updatedAt: string;
}

// ── Mapper ──

function mapKiosk(row: Record<string, unknown>): KioskConfigData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    accessToken: row.access_token as string,
    isActive: (row.is_active as boolean) ?? true,
    authMethods: (row.auth_methods as KioskAuthMethods) ?? { pin: true, password: false, face: false, name_tap: true },
    settings: (row.settings as KioskSettings) ?? {
      auto_break_minutes: 0,
      require_job_selection: false,
      allowed_hours_start: null,
      allowed_hours_end: null,
      show_company_logo: true,
      idle_timeout_seconds: 30,
      allow_break_toggle: true,
      restrict_ip_ranges: [],
      greeting_message: null,
    },
    branding: (row.branding as KioskBranding) ?? { primary_color: null, logo_url: null, background_url: null },
    createdBy: (row.created_by as string) ?? null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

// ── Generate URL-safe token ──

function generateToken(length = 32): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, b => chars[b % chars.length]).join('');
}

// ── SHA-256 for PIN hashing (matches Edge Function) ──

async function hashPin(pin: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(pin);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

// ── Hook ──

export function useKioskConfig() {
  const [kiosks, setKiosks] = useState<KioskConfigData[]>([]);
  const [employeePins, setEmployeePins] = useState<EmployeePin[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('kiosk_configs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setKiosks((data || []).map(mapKiosk));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load kiosk configs');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchPins = useCallback(async () => {
    try {
      const supabase = getSupabase();

      // Get all employees
      const { data: employees } = await supabase
        .from('users')
        .select('id, full_name')
        .eq('is_active', true)
        .is('deleted_at', null)
        .order('full_name');

      // Get which employees have PINs
      const { data: pins } = await supabase
        .from('employee_kiosk_pins')
        .select('user_id, updated_at');

      const pinMap = new Map<string, string>();
      for (const p of pins || []) {
        pinMap.set(p.user_id, p.updated_at);
      }

      setEmployeePins(
        (employees || []).map((e: Record<string, unknown>) => ({
          id: e.id as string,
          userId: e.id as string,
          userName: (e.full_name as string) ?? null,
          hasPin: pinMap.has(e.id as string),
          updatedAt: pinMap.get(e.id as string) ?? '',
        }))
      );
    } catch {
      // Non-critical — don't set error state
    }
  }, []);

  useEffect(() => {
    fetch();
    fetchPins();
    const supabase = getSupabase();
    const channel = supabase
      .channel('kiosk-configs')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'kiosk_configs' }, () => { fetch(); })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'employee_kiosk_pins' }, () => { fetchPins(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch, fetchPins]);

  const createKiosk = async (input: {
    name: string;
    authMethods?: Partial<KioskAuthMethods>;
    settings?: Partial<KioskSettings>;
    branding?: Partial<KioskBranding>;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const token = generateToken();
    const authMethods: KioskAuthMethods = {
      pin: true, password: false, face: false, name_tap: true,
      ...input.authMethods,
    };

    const { data, error: err } = await supabase
      .from('kiosk_configs')
      .insert({
        company_id: companyId,
        name: input.name,
        access_token: token,
        is_active: true,
        auth_methods: authMethods,
        settings: {
          auto_break_minutes: 0,
          require_job_selection: false,
          allowed_hours_start: null,
          allowed_hours_end: null,
          show_company_logo: true,
          idle_timeout_seconds: 30,
          allow_break_toggle: true,
          restrict_ip_ranges: [],
          greeting_message: null,
          ...input.settings,
        },
        branding: {
          primary_color: null,
          logo_url: null,
          background_url: null,
          ...input.branding,
        },
        created_by: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    return data.id;
  };

  const updateKiosk = async (id: string, updates: {
    name?: string;
    isActive?: boolean;
    authMethods?: Partial<KioskAuthMethods>;
    settings?: Partial<KioskSettings>;
    branding?: Partial<KioskBranding>;
  }): Promise<void> => {
    const supabase = getSupabase();
    const existing = kiosks.find(k => k.id === id);
    if (!existing) throw new Error('Kiosk not found');

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const row: Record<string, any> = {};
    if (updates.name !== undefined) row.name = updates.name;
    if (updates.isActive !== undefined) row.is_active = updates.isActive;
    if (updates.authMethods) row.auth_methods = { ...existing.authMethods, ...updates.authMethods };
    if (updates.settings) row.settings = { ...existing.settings, ...updates.settings };
    if (updates.branding) row.branding = { ...existing.branding, ...updates.branding };

    const { error: err } = await supabase
      .from('kiosk_configs')
      .update(row)
      .eq('id', id);

    if (err) throw err;
  };

  const deleteKiosk = async (id: string): Promise<void> => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('kiosk_configs')
      .update({ deleted_at: new Date().toISOString(), is_active: false })
      .eq('id', id);

    if (err) throw err;
  };

  const regenerateToken = async (id: string): Promise<string> => {
    const supabase = getSupabase();
    const newToken = generateToken();

    const { error: err } = await supabase
      .from('kiosk_configs')
      .update({ access_token: newToken })
      .eq('id', id);

    if (err) throw err;
    return newToken;
  };

  const setEmployeePin = async (userId: string, pin: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    if (pin.length < 4 || pin.length > 8) {
      throw new Error('PIN must be 4-8 digits');
    }
    if (!/^\d+$/.test(pin)) {
      throw new Error('PIN must contain only digits');
    }

    const pinHash = await hashPin(pin);

    const { error: err } = await supabase
      .from('employee_kiosk_pins')
      .upsert({
        company_id: companyId,
        user_id: userId,
        pin_hash: pinHash,
      }, {
        onConflict: 'company_id,user_id',
      });

    if (err) throw err;
  };

  const removeEmployeePin = async (userId: string): Promise<void> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { error: err } = await supabase
      .from('employee_kiosk_pins')
      .delete()
      .eq('company_id', companyId)
      .eq('user_id', userId);

    if (err) throw err;
  };

  const getKioskUrl = (accessToken: string): string => {
    const base = typeof window !== 'undefined' && window.location.hostname === 'localhost'
      ? 'http://localhost:3001'
      : 'https://team.zafto.cloud';
    return `${base}/kiosk/${accessToken}`;
  };

  return {
    kiosks,
    employeePins,
    loading,
    error,
    createKiosk,
    updateKiosk,
    deleteKiosk,
    regenerateToken,
    setEmployeePin,
    removeEmployeePin,
    getKioskUrl,
    refetch: fetch,
  };
}
