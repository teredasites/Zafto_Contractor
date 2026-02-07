'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  User,
  Building2,
  Shield,
  Calendar,
  Mail,
  Clock,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { getSupabase } from '@/lib/supabase';
import { formatDate, formatRelativeTime } from '@/lib/utils';

interface UserDetail {
  id: string;
  full_name: string;
  email: string;
  role: string;
  company_id: string | null;
  created_at: string;
  phone?: string;
  last_login_at?: string;
}

interface CompanyInfo {
  name: string;
  subscription_tier: string;
}

interface AuditEntry {
  id: string;
  action: string;
  table_name: string;
  record_id: string;
  created_at: string;
  metadata: Record<string, unknown> | null;
}

export default function UserDetailPage() {
  const params = useParams();
  const id = params.id as string;

  const [user, setUser] = useState<UserDetail | null>(null);
  const [company, setCompany] = useState<CompanyInfo | null>(null);
  const [activity, setActivity] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [activityLoading, setActivityLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;

    const fetchData = async () => {
      const supabase = getSupabase();

      // Fetch user
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .single();

      if (userError || !userData) {
        setError('User not found');
        setLoading(false);
        setActivityLoading(false);
        return;
      }
      const userRow = userData as UserDetail;
      setUser(userRow);

      // Fetch company if user has one
      if (userRow.company_id) {
        const { data: companyData } = await supabase
          .from('companies')
          .select('name, subscription_tier')
          .eq('id', userRow.company_id)
          .single();

        if (companyData) {
          setCompany(companyData as CompanyInfo);
        }
      }

      setLoading(false);

      // Fetch recent activity
      const { data: activityData } = await supabase
        .from('audit_log')
        .select('*')
        .eq('user_id', id)
        .order('created_at', { ascending: false })
        .limit(20);

      if (activityData) {
        setActivity(activityData as AuditEntry[]);
      }
      setActivityLoading(false);
    };

    fetchData();
  }, [id]);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="h-9 w-20 rounded-lg skeleton-shimmer" />
          <div className="h-7 w-48 rounded skeleton-shimmer" />
        </div>
        <div className="h-48 rounded-xl skeleton-shimmer" />
        <div className="h-64 rounded-xl skeleton-shimmer" />
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="space-y-8 animate-fade-in">
        <Link href="/dashboard/users">
          <Button variant="ghost">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Users
          </Button>
        </Link>
        <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
          <User className="h-10 w-10 mb-3 opacity-40" />
          <p className="text-sm">{error || 'User not found'}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Back + Title */}
      <div className="flex items-center gap-3">
        <Link href="/dashboard/users">
          <Button variant="ghost" className="px-2.5">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            {user.full_name || 'Unnamed User'}
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-0.5">
            User profile and activity
          </p>
        </div>
      </div>

      {/* User Profile Card */}
      <Card>
        <CardHeader>
          <CardTitle>Profile</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-y-5 gap-x-8">
            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                <User className="h-4 w-4 text-[var(--text-secondary)]" />
              </div>
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                  Name
                </p>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {user.full_name || '--'}
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                <Mail className="h-4 w-4 text-[var(--text-secondary)]" />
              </div>
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                  Email
                </p>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {user.email}
                </p>
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                <Shield className="h-4 w-4 text-[var(--text-secondary)]" />
              </div>
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                  Role
                </p>
                <StatusBadge status={user.role || 'unknown'} />
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                <Building2 className="h-4 w-4 text-[var(--text-secondary)]" />
              </div>
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                  Company
                </p>
                {user.company_id && company ? (
                  <Link
                    href={`/dashboard/companies/${user.company_id}`}
                    className="text-sm font-medium text-[var(--accent)] hover:underline"
                  >
                    {company.name}
                    {company.subscription_tier && (
                      <span className="text-[var(--text-secondary)] font-normal ml-1.5">
                        ({company.subscription_tier})
                      </span>
                    )}
                  </Link>
                ) : (
                  <p className="text-sm text-[var(--text-secondary)]">--</p>
                )}
              </div>
            </div>

            <div className="flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                <Calendar className="h-4 w-4 text-[var(--text-secondary)]" />
              </div>
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                  Created
                </p>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {formatDate(user.created_at)}
                </p>
              </div>
            </div>

            {user.phone && (
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
                  <User className="h-4 w-4 text-[var(--text-secondary)]" />
                </div>
                <div>
                  <p className="text-xs text-[var(--text-secondary)] mb-0.5">
                    Phone
                  </p>
                  <p className="text-sm font-medium text-[var(--text-primary)]">
                    {user.phone}
                  </p>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
        </CardHeader>
        <CardContent>
          {activityLoading ? (
            <div className="space-y-3">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="flex items-center gap-3">
                  <div className="h-8 w-8 rounded-full skeleton-shimmer" />
                  <div className="flex-1 space-y-1.5">
                    <div className="h-3 w-3/4 rounded skeleton-shimmer" />
                    <div className="h-2.5 w-1/3 rounded skeleton-shimmer" />
                  </div>
                </div>
              ))}
            </div>
          ) : activity.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-[var(--text-secondary)]">
              <Clock className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No recent activity</p>
            </div>
          ) : (
            <div className="space-y-1">
              {activity.map((entry) => (
                <div
                  key={entry.id}
                  className="flex items-center justify-between py-2.5 border-b border-[var(--border)] last:border-0"
                >
                  <div className="flex items-center gap-3">
                    <div className="h-8 w-8 rounded-full bg-[var(--bg-elevated)] flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-medium text-[var(--text-secondary)]">
                        {entry.table_name?.[0]?.toUpperCase() || 'A'}
                      </span>
                    </div>
                    <div>
                      <p className="text-sm text-[var(--text-primary)]">
                        <span className="font-medium">{entry.action}</span>{' '}
                        <Badge variant="default">{entry.table_name}</Badge>
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">
                        {formatRelativeTime(entry.created_at)}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
