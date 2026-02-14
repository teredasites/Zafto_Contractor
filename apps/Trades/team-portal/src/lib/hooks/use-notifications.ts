'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Notifications Hook — Real-time unread count + CRUD
// Same pattern as web-portal, same Supabase notifications table
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
      .channel('team-notifications-realtime')
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
