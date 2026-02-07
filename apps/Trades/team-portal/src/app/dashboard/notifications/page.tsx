'use client';

import { Bell } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export default function NotificationsPage() {
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">Notifications</h1>
        <p className="text-sm text-muted mt-1">
          Stay updated on job assignments, schedule changes, and messages
        </p>
      </div>

      {/* Empty State */}
      <Card>
        <CardContent className="py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
              <Bell size={32} className="text-muted" />
            </div>
            <div className="space-y-1.5 max-w-sm">
              <p className="text-[15px] font-semibold text-main">
                No notifications yet
              </p>
              <p className="text-sm text-muted leading-relaxed">
                You&apos;ll be notified about new job assignments, schedule changes,
                and messages from your team.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
