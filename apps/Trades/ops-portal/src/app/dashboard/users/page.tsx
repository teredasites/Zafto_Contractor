'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Users, Search, ChevronRight, Mail } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { getSupabase } from '@/lib/supabase';
import { formatDate } from '@/lib/utils';

interface UserRow {
  id: string;
  full_name: string;
  email: string;
  role: string;
  company_id: string | null;
  created_at: string;
}

interface CompanyMap {
  [id: string]: string;
}

const ROLE_OPTIONS = ['all', 'owner', 'admin', 'office', 'tech', 'cpa', 'client'];

export default function UsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [companies, setCompanies] = useState<CompanyMap>({});
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');

  useEffect(() => {
    const fetchData = async () => {
      const supabase = getSupabase();

      // Fetch users
      const { data: usersData } = await supabase
        .from('users')
        .select('id, full_name, email, role, company_id, created_at')
        .order('created_at', { ascending: false });

      const usersList = (usersData || []) as UserRow[];
      setUsers(usersList);

      // Fetch company names for all unique company_ids
      const companyIds = [
        ...new Set(
          usersList.map((u) => u.company_id).filter(Boolean) as string[]
        ),
      ];

      if (companyIds.length > 0) {
        const { data: companiesData } = await supabase
          .from('companies')
          .select('id, name')
          .in('id', companyIds);

        if (companiesData) {
          const map: CompanyMap = {};
          for (const c of companiesData) {
            map[c.id] = c.name;
          }
          setCompanies(map);
        }
      }

      setLoading(false);
    };

    fetchData();
  }, []);

  const filtered = users.filter((u) => {
    const matchesSearch =
      (u.full_name || '').toLowerCase().includes(search.toLowerCase()) ||
      (u.email || '').toLowerCase().includes(search.toLowerCase());
    const matchesRole =
      roleFilter === 'all' || u.role?.toLowerCase() === roleFilter;
    return matchesSearch && matchesRole;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">Users</h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          All platform users across companies
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-secondary)]" />
          <Input
            placeholder="Search by name or email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="rounded-lg border border-[var(--border)] bg-[var(--bg-card)] px-3 py-2.5 text-sm text-[var(--text-primary)] focus:border-[var(--accent)] focus:outline-none focus:ring-2 focus:ring-[var(--accent)]/20 transition-colors"
        >
          {ROLE_OPTIONS.map((role) => (
            <option key={role} value={role}>
              {role === 'all' ? 'All Roles' : role.charAt(0).toUpperCase() + role.slice(1)}
            </option>
          ))}
        </select>
      </div>

      {/* Table */}
      <Card>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                  <div className="h-4 w-28 rounded skeleton-shimmer" />
                  <div className="h-4 w-24 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Users className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm">No users found</p>
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
                      Company
                    </th>
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Created
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((user) => (
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
                        {user.company_id && companies[user.company_id] ? (
                          <Link
                            href={`/dashboard/companies/${user.company_id}`}
                            className="text-sm text-[var(--accent)] hover:underline"
                          >
                            {companies[user.company_id]}
                          </Link>
                        ) : (
                          <span className="text-sm text-[var(--text-secondary)]">
                            --
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-2">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatDate(user.created_at)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <Link
                          href={`/dashboard/users/${user.id}`}
                          className="inline-flex items-center gap-1 text-sm text-[var(--accent)] hover:underline"
                        >
                          View
                          <ChevronRight className="h-3.5 w-3.5" />
                        </Link>
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
