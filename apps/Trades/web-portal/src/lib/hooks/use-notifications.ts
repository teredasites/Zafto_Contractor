'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Notifications Hook — Real-time unread count + CRUD
// Matches Flutter notification_repository.dart pattern
// ============================================================

export type NotificationType =
  | 'job_assigned'
  | 'invoice_paid'
  | 'bid_accepted'
  | 'bid_rejected'
  | 'change_order_approved'
  | 'change_order_rejected'
  | 'time_entry_approved'
  | 'time_entry_rejected'
  | 'customer_message'
  | 'dead_man_switch'
  | 'payment_reported'
  | 'payment_verified'
  | 'payment_disputed'
  | 'payment_rejected'
  | 'hap_payment_due'
  | 'recertification_upcoming'
  | 'system';

export interface NotificationData {
  id: string;
  companyId: string;
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
  entityType: string | null;
  entityId: string | null;
  isRead: boolean;
  readAt: string | null;
  createdAt: string;
}

function mapNotification(row: Record<string, unknown>): NotificationData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: row.user_id as string,
    title: row.title as string,
    body: row.body as string,
    type: (row.type as NotificationType) || 'system',
    entityType: row.entity_type as string | null,
    entityId: row.entity_id as string | null,
    isRead: row.is_read as boolean,
    readAt: row.read_at as string | null,
    createdAt: row.created_at as string,
  };
}

export function useNotifications() {
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  const fetchNotifications = useCallback(async () => {
    const supabase = getSupabase();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setLoading(false);
      return;
    }

    const { data, error: err } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (err) {
      setError(err.message);
      setLoading(false);
      return;
    }
    setNotifications((data || []).map(mapNotification));
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchNotifications();

    const supabase = getSupabase();
    const channel = supabase
      .channel('notifications-realtime')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'notifications' },
        (payload: { new: Record<string, unknown> }) => {
          const newNotif = mapNotification(payload.new);
          setNotifications((prev) => [newNotif, ...prev].slice(0, 50));
        },
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'notifications' },
        (_payload: unknown) => fetchNotifications(),
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchNotifications]);

  const markAsRead = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true, readAt: new Date().toISOString() } : n)),
    );
  };

  const markAllAsRead = async () => {
    const supabase = getSupabase();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    const { error: err } = await supabase
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('user_id', user.id)
      .eq('is_read', false);
    if (err) throw err;
    setNotifications((prev) =>
      prev.map((n) => ({ ...n, isRead: true, readAt: n.readAt || new Date().toISOString() })),
    );
  };

  return { notifications, unreadCount, loading, error, markAsRead, markAllAsRead };
}

// ── Notification Preferences Hook ────────────────────────────────
export interface NotificationPreferences {
  invoice_overdue: { in_app: boolean; email: boolean; sms: boolean };
  bid_expired: { in_app: boolean; email: boolean; sms: boolean };
  job_past_deadline: { in_app: boolean; email: boolean; sms: boolean };
  cert_expiring: { in_app: boolean; email: boolean; sms: boolean };
  service_visit_due: { in_app: boolean; email: boolean; sms: boolean };
  missed_clockout: { in_app: boolean; email: boolean; sms: boolean };
}

export const TRIGGER_LABELS: Record<string, string> = {
  invoice_overdue: 'Overdue Invoices',
  bid_expired: 'Expired Bids',
  job_past_deadline: 'Jobs Past Deadline',
  cert_expiring: 'Expiring Certifications',
  service_visit_due: 'Service Visits Due',
  missed_clockout: 'Missed Clock-Outs',
};

export const DEFAULT_NOTIF_PREFS: NotificationPreferences = {
  invoice_overdue: { in_app: true, email: false, sms: false },
  bid_expired: { in_app: true, email: false, sms: false },
  job_past_deadline: { in_app: true, email: false, sms: false },
  cert_expiring: { in_app: true, email: false, sms: false },
  service_visit_due: { in_app: true, email: false, sms: false },
  missed_clockout: { in_app: true, email: false, sms: false },
};

export function useNotificationPreferences() {
  const [prefs, setPrefs] = useState<NotificationPreferences>(DEFAULT_NOTIF_PREFS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }
      const { data } = await supabase.from('users').select('notification_preferences').eq('id', user.id).single();
      if (data?.notification_preferences) {
        setPrefs({ ...DEFAULT_NOTIF_PREFS, ...data.notification_preferences });
      }
      setLoading(false);
    };
    load();
  }, []);

  const updatePrefs = async (newPrefs: NotificationPreferences) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    await supabase.from('users').update({ notification_preferences: newPrefs }).eq('id', user.id);
    setPrefs(newPrefs);
  };

  return { prefs, loading, updatePrefs };
}

// ── Automated Notifications (from notification_log) ──────────────
export function useNotificationLog() {
  const [alerts, setAlerts] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAlerts = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('notification_log')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setAlerts((data || []).map((n: Record<string, unknown>) => ({
        id: n.id as string,
        companyId: n.company_id as string,
        userId: n.user_id as string,
        title: n.title as string,
        body: (n.body as string) || '',
        type: (n.trigger_type as NotificationType) || 'system',
        entityType: n.entity_type as string | null,
        entityId: n.entity_id as string | null,
        isRead: n.is_read as boolean,
        readAt: n.read_at as string | null,
        createdAt: n.created_at as string,
      })));
    } catch {
      // Silent
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAlerts(); }, [fetchAlerts]);

  const markAlertRead = async (id: string) => {
    const supabase = getSupabase();
    await supabase.from('notification_log').update({ is_read: true, read_at: new Date().toISOString() }).eq('id', id);
    setAlerts((prev) => prev.map((a) => a.id === id ? { ...a, isRead: true } : a));
  };

  return { alerts, loading, markAlertRead, refetch: fetchAlerts };
}

// ── Google Calendar Status Hook ──────────────────────────────────
export function useGoogleCalendar() {
  const [connected, setConnected] = useState(false);
  const [email, setEmail] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const check = async () => {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }
      const { data } = await supabase.from('users').select('google_calendar_connected, google_calendar_email').eq('id', user.id).single();
      if (data) {
        setConnected(data.google_calendar_connected || false);
        setEmail(data.google_calendar_email || null);
      }
      setLoading(false);
    };
    check();
  }, []);

  const disconnect = async () => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;

    await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/google-calendar-sync`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ action: 'disconnect' }),
    });
    setConnected(false);
    setEmail(null);
  };

  const syncNow = async () => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return null;

    const res = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/google-calendar-sync`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ action: 'sync-to-google' }),
    });
    return res.json();
  };

  return { connected, email, loading, disconnect, syncNow };
}
