'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Building2,
  Users,
  Briefcase,
  Calendar,
  Mail,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { getSupabase } from '@/lib/supabase';
import { formatDate } from '@/lib/utils';

interface Company {
  id: string;
  name: string;
  subscription_tier: string;
  subscription_status: string;
  created_at: string;
  email?: string;
  phone?: string;
  address?: string;
}

interface CompanyUser {
  id: string;
  full_name: string;
  email: string;
  role: string;
  created_at: string;
}

export default function CompanyDetailPage() {
  const params = useParams();
  const id = params.id as string;

  const [company, setCompany] = useState<Company | null>(null);
  const [users, setUsers] = useState<CompanyUser[]>([]);
  const [jobsCount, setJobsCount] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;

    const fetchData = async () => {
      const supabase = getSupabase();

      // Fetch company
      const { data: companyData, error: companyError } = await supabase
        .from('companies')
        .select('*')
        .eq('id', id)
        .single();

      if (companyError || !companyData) {
        setError('Company not found');
        setLoading(false);
        return;
      }
      setCompany(companyData as Company);

      // Fetch company users
      const { data: usersData } = await supabase
        .from('users')
        .select('id, full_name, email, role, created_at')
        .eq('company_id', id)
        .order('created_at', { ascending: false });

      if (usersData) {
        setUsers(usersData as CompanyUser[]);
      }

      // Fetch jobs count
      const { count } = await supabase
        .from('jobs')
        .select('id', { count: 'exact', head: true })
        .eq('company_id', id);

      setJobsCount(count ?? 0);
      setLoading(false);
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
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-24 rounded-xl skeleton-shimmer" />
          ))}
        </div>
        <div className="h-64 rounded-xl skeleton-shimmer" />
      </div>
    );
  }

  if (error || !company) {
    return (
      <div className="space-y-8 animate-fade-in">
        <Link href="/dashboard/companies">
          <Button variant="ghost">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Companies
          </Button>
        </Link>
        <div className="flex flex-col items-center justify-center py-16 text-[var(--text-secondary)]">
          <Building2 className="h-10 w-10 mb-3 opacity-40" />
          <p className="text-sm">{error || 'Company not found'}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Back + Title */}
      <div className="flex items-center gap-3">
        <Link href="/dashboard/companies">
          <Button variant="ghost" className="px-2.5">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            {company.name}
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-0.5">
            Company details and team members
          </p>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
              <Users className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Users</p>
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {users.length}
              </p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
              <Briefcase className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Jobs</p>
              <p className="text-xl font-bold text-[var(--text-primary)]">
                {jobsCount}
              </p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
              <Calendar className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Created</p>
              <p className="text-sm font-medium text-[var(--text-primary)]">
                {formatDate(company.created_at)}
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* Company Info */}
      <Card>
        <CardHeader>
          <CardTitle>Company Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-y-4 gap-x-8">
            <div>
              <p className="text-xs text-[var(--text-secondary)] mb-1">Name</p>
              <p className="text-sm font-medium text-[var(--text-primary)]">
                {company.name}
              </p>
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)] mb-1">Plan</p>
              <p className="text-sm font-medium text-[var(--text-primary)] capitalize">
                {company.subscription_tier || '--'}
              </p>
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)] mb-1">Status</p>
              <StatusBadge status={company.subscription_status || 'unknown'} />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)] mb-1">
                Subscription Status
              </p>
              <StatusBadge status={company.subscription_status || 'unknown'} />
            </div>
            {company.email && (
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-1">Email</p>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {company.email}
                </p>
              </div>
            )}
            {company.phone && (
              <div>
                <p className="text-xs text-[var(--text-secondary)] mb-1">Phone</p>
                <p className="text-sm font-medium text-[var(--text-primary)]">
                  {company.phone}
                </p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>Team Members</CardTitle>
        </CardHeader>
        <CardContent>
          {users.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-[var(--text-secondary)]">
              <Users className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No users in this company</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Name
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Email
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Role
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Joined
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr
                      key={user.id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <Link
                          href={`/dashboard/users/${user.id}`}
                          className="text-sm font-medium text-[var(--text-primary)] hover:text-[var(--accent)] transition-colors"
                        >
                          {user.full_name || '--'}
                        </Link>
                      </td>
                      <td className="py-3 px-2">
                        <div className="flex items-center gap-1.5 text-sm text-[var(--text-secondary)]">
                          <Mail className="h-3.5 w-3.5 opacity-50" />
                          {user.email}
                        </div>
                      </td>
                      <td className="py-3 px-2">
                        <StatusBadge status={user.role || 'unknown'} />
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatDate(user.created_at)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
