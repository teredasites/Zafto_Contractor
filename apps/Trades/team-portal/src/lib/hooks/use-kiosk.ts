'use client';

// Kiosk hook — communicates with kiosk-clock Edge Function
// Token-based device auth, no user JWT required
// Actions: verify_token, verify_pin, clock_in, clock_out, start_break, end_break

import { useState, useEffect, useCallback, useRef } from 'react';

// ── Types ──

export interface KioskConfig {
  id: string;
  name: string;
  authMethods: {
    pin: boolean;
    password: boolean;
    face: boolean;
    name_tap: boolean;
  };
  settings: {
    auto_break_minutes: number;
    require_job_selection: boolean;
    allowed_hours_start: string | null;
    allowed_hours_end: string | null;
    show_company_logo: boolean;
    idle_timeout_seconds: number;
    allow_break_toggle: boolean;
    restrict_ip_ranges: string[];
    greeting_message: string | null;
  };
  branding: {
    primary_color: string | null;
    logo_url: string | null;
    background_url: string | null;
  };
}

export interface KioskEmployee {
  id: string;
  name: string;
  avatar: string | null;
  role: string;
  trade: string | null;
  hasPin: boolean;
  activeEntry: {
    entryId: string;
    clockIn: string;
    breakMinutes: number;
  } | null;
}

export interface KioskCompany {
  name: string;
  logo_url: string | null;
}

export type KioskScreen = 'loading' | 'error' | 'idle' | 'identify' | 'pin_entry' | 'confirm' | 'success';

// ── Edge Function caller ──

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;

async function callKioskFunction(body: Record<string, unknown>): Promise<Record<string, unknown>> {
  const res = await fetch(`${SUPABASE_URL}/functions/v1/kiosk-clock`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error || `Request failed (${res.status})`);
  }
  return data;
}

// ── Hook ──

export function useKiosk(accessToken: string) {
  const [screen, setScreen] = useState<KioskScreen>('loading');
  const [config, setConfig] = useState<KioskConfig | null>(null);
  const [company, setCompany] = useState<KioskCompany | null>(null);
  const [employees, setEmployees] = useState<KioskEmployee[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<KioskEmployee | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const idleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // ── Verify token and load config ──
  const verifyToken = useCallback(async () => {
    try {
      setScreen('loading');
      setError(null);

      const data = await callKioskFunction({
        action: 'verify_token',
        access_token: accessToken,
      });

      const kioskData = data.kiosk as KioskConfig;
      const companyData = data.company as KioskCompany;
      const employeeList = data.employees as KioskEmployee[];

      setConfig(kioskData);
      setCompany(companyData);
      setEmployees(employeeList);
      setScreen('idle');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to verify kiosk token');
      setScreen('error');
    }
  }, [accessToken]);

  // ── Refresh employee data (active entries, etc.) ──
  const refreshEmployees = useCallback(async () => {
    try {
      const data = await callKioskFunction({
        action: 'verify_token',
        access_token: accessToken,
      });
      setEmployees(data.employees as KioskEmployee[]);
    } catch {
      // Non-critical refresh
    }
  }, [accessToken]);

  // ── Idle timer management ──
  const resetIdleTimer = useCallback(() => {
    if (idleTimerRef.current) clearTimeout(idleTimerRef.current);
    if (config?.settings.idle_timeout_seconds) {
      idleTimerRef.current = setTimeout(() => {
        setSelectedEmployee(null);
        setSuccessMessage(null);
        setScreen('idle');
      }, config.settings.idle_timeout_seconds * 1000);
    }
  }, [config?.settings.idle_timeout_seconds]);

  // ── Navigation helpers ──
  const goToIdle = useCallback(() => {
    setSelectedEmployee(null);
    setSuccessMessage(null);
    setError(null);
    setScreen('idle');
    resetIdleTimer();
  }, [resetIdleTimer]);

  const goToIdentify = useCallback(() => {
    setSelectedEmployee(null);
    setError(null);
    setScreen('identify');
    resetIdleTimer();
  }, [resetIdleTimer]);

  const selectEmployee = useCallback((employee: KioskEmployee) => {
    setSelectedEmployee(employee);
    resetIdleTimer();

    // If PIN auth is required and employee has a PIN, go to PIN entry
    if (config?.authMethods.pin && employee.hasPin) {
      setScreen('pin_entry');
    } else {
      // Name-tap mode or no PIN set — go straight to confirm
      setScreen('confirm');
    }
  }, [config?.authMethods.pin, resetIdleTimer]);

  // ── Verify PIN ──
  const verifyPin = useCallback(async (pin: string): Promise<boolean> => {
    if (!selectedEmployee) return false;
    try {
      setActionLoading(true);
      resetIdleTimer();
      await callKioskFunction({
        action: 'verify_pin',
        access_token: accessToken,
        user_id: selectedEmployee.id,
        pin,
      });
      setScreen('confirm');
      return true;
    } catch {
      return false;
    } finally {
      setActionLoading(false);
    }
  }, [accessToken, selectedEmployee, resetIdleTimer]);

  // ── Clock In ──
  const clockIn = useCallback(async (jobId?: string) => {
    if (!selectedEmployee) return;
    try {
      setActionLoading(true);
      resetIdleTimer();

      const method = config?.authMethods.pin && selectedEmployee.hasPin
        ? 'kiosk_pin'
        : 'kiosk_name_tap';

      const result = await callKioskFunction({
        action: 'clock_in',
        access_token: accessToken,
        user_id: selectedEmployee.id,
        job_id: jobId,
        clock_in_method: method,
      });

      const clockInTime = new Date(result.clock_in as string).toLocaleTimeString([], {
        hour: 'numeric',
        minute: '2-digit',
      });
      setSuccessMessage(`Clocked in at ${clockInTime}`);
      setScreen('success');
      refreshEmployees();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to clock in');
    } finally {
      setActionLoading(false);
    }
  }, [accessToken, selectedEmployee, config?.authMethods.pin, resetIdleTimer, refreshEmployees]);

  // ── Clock Out ──
  const clockOut = useCallback(async () => {
    if (!selectedEmployee) return;
    try {
      setActionLoading(true);
      resetIdleTimer();

      const result = await callKioskFunction({
        action: 'clock_out',
        access_token: accessToken,
        user_id: selectedEmployee.id,
      });

      const totalMin = result.total_minutes as number;
      const hours = Math.floor(totalMin / 60);
      const mins = totalMin % 60;
      setSuccessMessage(`Clocked out — ${hours}h ${mins}m total`);
      setScreen('success');
      refreshEmployees();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to clock out');
    } finally {
      setActionLoading(false);
    }
  }, [accessToken, selectedEmployee, resetIdleTimer, refreshEmployees]);

  // ── Break Toggle ──
  const startBreak = useCallback(async () => {
    if (!selectedEmployee) return;
    try {
      setActionLoading(true);
      resetIdleTimer();
      await callKioskFunction({
        action: 'start_break',
        access_token: accessToken,
        user_id: selectedEmployee.id,
      });
      setSuccessMessage('Break started');
      setScreen('success');
      refreshEmployees();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to start break');
    } finally {
      setActionLoading(false);
    }
  }, [accessToken, selectedEmployee, resetIdleTimer, refreshEmployees]);

  const endBreak = useCallback(async () => {
    if (!selectedEmployee) return;
    try {
      setActionLoading(true);
      resetIdleTimer();
      const result = await callKioskFunction({
        action: 'end_break',
        access_token: accessToken,
        user_id: selectedEmployee.id,
      });
      const addedMins = result.break_minutes_added as number;
      setSuccessMessage(`Break ended — ${addedMins} min break`);
      setScreen('success');
      refreshEmployees();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to end break');
    } finally {
      setActionLoading(false);
    }
  }, [accessToken, selectedEmployee, resetIdleTimer, refreshEmployees]);

  // ── Init ──
  useEffect(() => {
    verifyToken();
    // Refresh employees every 60s to keep active entries current
    const interval = setInterval(refreshEmployees, 60000);
    return () => {
      clearInterval(interval);
      if (idleTimerRef.current) clearTimeout(idleTimerRef.current);
    };
  }, [verifyToken, refreshEmployees]);

  // ── Auto-return from success screen ──
  useEffect(() => {
    if (screen === 'success') {
      const timer = setTimeout(() => goToIdle(), 5000);
      return () => clearTimeout(timer);
    }
  }, [screen, goToIdle]);

  return {
    screen,
    config,
    company,
    employees,
    selectedEmployee,
    error,
    successMessage,
    actionLoading,
    goToIdle,
    goToIdentify,
    selectEmployee,
    verifyPin,
    clockIn,
    clockOut,
    startBreak,
    endBreak,
    refreshEmployees,
  };
}
