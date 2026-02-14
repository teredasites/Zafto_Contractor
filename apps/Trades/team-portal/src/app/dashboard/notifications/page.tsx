'use client';

import { Bell, Check, Loader2, Briefcase, FileText, DollarSign, MessageSquare, AlertTriangle, Info } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { useNotifications, type NotificationType } from '@/lib/hooks/use-notifications';

const typeIcon: Record<NotificationType, typeof Bell> = {
  job_assigned: Briefcase,
  invoice_paid: DollarSign,
  bid_accepted: FileText,
  bid_rejected: FileText,
  change_order_approved: Check,
  change_order_rejected: AlertTriangle,
  time_entry_approved: Check,
  time_entry_rejected: AlertTriangle,
  customer_message: MessageSquare,
  dead_man_switch: AlertTriangle,
  system: Info,
};

function timeAgo(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return new Date(dateStr).toLocaleDateString();
}

export default function NotificationsPage() {
  const { notifications, unreadCount, loading, markAsRead, markAllAsRead } = useNotifications();

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-main">Notifications</h1>
          <p className="text-sm text-muted mt-1">
            {unreadCount > 0 ? `${unreadCount} unread` : 'All caught up'}
          </p>
        </div>
        {unreadCount > 0 && (
          <button
            onClick={() => markAllAsRead()}
            className="text-[13px] font-medium text-accent hover:underline flex items-center gap-1.5"
          >
            <Check size={14} />
            Mark all read
          </button>
        )}
      </div>

      {loading ? (
        <Card>
          <CardContent className="py-16">
            <div className="flex items-center justify-center">
              <Loader2 size={24} className="animate-spin text-muted" />
            </div>
          </CardContent>
        </Card>
      ) : notifications.length === 0 ? (
        <Card>
          <CardContent className="py-16">
            <div className="flex flex-col items-center text-center gap-4">
              <div className="w-16 h-16 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
                <Bell size={32} className="text-muted" />
              </div>
              <div className="space-y-1.5 max-w-sm">
                <p className="text-[15px] font-semibold text-main">No notifications yet</p>
                <p className="text-sm text-muted leading-relaxed">
                  You&apos;ll be notified about new job assignments, schedule changes, and messages from your team.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {notifications.map((n) => {
                const Icon = typeIcon[n.type] || Bell;
                return (
                  <button
                    key={n.id}
                    onClick={() => { if (!n.isRead) markAsRead(n.id); }}
                    className={`w-full flex items-start gap-3 px-4 py-3.5 text-left transition-colors ${
                      n.isRead ? 'hover:bg-surface-hover' : 'bg-accent/5 hover:bg-accent/10'
                    }`}
                  >
                    <div className={`w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5 ${
                      n.isRead ? 'bg-slate-100 dark:bg-slate-800 text-muted' : 'bg-accent/10 text-accent'
                    }`}>
                      <Icon size={16} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className={`text-[13px] truncate ${n.isRead ? 'text-muted' : 'font-semibold text-main'}`}>
                          {n.title}
                        </p>
                        {!n.isRead && <div className="w-2 h-2 rounded-full bg-accent flex-shrink-0" />}
                      </div>
                      <p className="text-[12px] text-muted mt-0.5 line-clamp-2">{n.body}</p>
                      <p className="text-[11px] text-muted mt-1">{timeAgo(n.createdAt)}</p>
                    </div>
                  </button>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
