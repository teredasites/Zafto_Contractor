'use client';

import { useEffect, useState } from 'react';
import {
  Database,
  CreditCard,
  Globe,
  AlertTriangle,
  Cpu,
  ShoppingCart,
  GitBranch,
  Apple,
  Mail,
  FolderKey,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge';
import { getSupabase } from '@/lib/supabase';
import { formatDate, formatRelativeTime } from '@/lib/utils';

interface ServiceCredential {
  id: string;
  service_name: string;
  credentials: Record<string, unknown>;
  last_rotated_at: string | null;
  rotation_interval_days: number | null;
  next_rotation_at: string | null;
  status: 'active' | 'expired' | 'revoked' | 'rotating';
  created_at: string;
  updated_at: string;
}

interface StaticService {
  name: string;
  description: string;
  icon: React.ReactNode;
}

const STATIC_SERVICES: StaticService[] = [
  {
    name: 'Supabase',
    description: 'PostgreSQL database, authentication, storage, edge functions',
    icon: <Database className="h-5 w-5" />,
  },
  {
    name: 'Stripe',
    description: 'Payment processing, subscriptions, billing',
    icon: <CreditCard className="h-5 w-5" />,
  },
  {
    name: 'Cloudflare',
    description: 'CDN, DNS, WAF, DDoS protection',
    icon: <Globe className="h-5 w-5" />,
  },
  {
    name: 'Sentry',
    description: 'Error tracking, performance monitoring, alerting',
    icon: <AlertTriangle className="h-5 w-5" />,
  },
  {
    name: 'Claude API (Anthropic)',
    description: 'AI assistant, natural language processing, Z Intelligence',
    icon: <Cpu className="h-5 w-5" />,
  },
  {
    name: 'RevenueCat',
    description: 'In-app purchases, subscription management (mobile)',
    icon: <ShoppingCart className="h-5 w-5" />,
  },
  {
    name: 'GitHub',
    description: 'Source control, CI/CD pipelines, code review',
    icon: <GitBranch className="h-5 w-5" />,
  },
  {
    name: 'Apple Developer',
    description: 'iOS app distribution, App Store Connect, certificates',
    icon: <Apple className="h-5 w-5" />,
  },
  {
    name: 'MS 365',
    description: 'Business email (zafto.app domain), calendar',
    icon: <Mail className="h-5 w-5" />,
  },
];

export default function ServiceDirectoryPage() {
  const [credentials, setCredentials] = useState<ServiceCredential[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasDbData, setHasDbData] = useState(false);

  useEffect(() => {
    const fetchCredentials = async () => {
      try {
        const supabase = getSupabase();
        const { data, error } = await supabase
          .from('service_credentials')
          .select('*')
          .order('service_name');

        if (!error && data && data.length > 0) {
          setCredentials(data as ServiceCredential[]);
          setHasDbData(true);
        }
      } catch {
        // Table may not exist yet — fall back to static list
      }
      setLoading(false);
    };

    fetchCredentials();
  }, []);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          Service Directory
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Credential rotation tracking for all external services
        </p>
      </div>

      {/* Loading State */}
      {loading ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Card key={i}>
              <div className="flex items-start gap-3">
                <div className="h-10 w-10 rounded-lg skeleton-shimmer" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-3 w-48 rounded skeleton-shimmer" />
                  <div className="flex gap-4 mt-3">
                    <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                    <div className="h-3 w-24 rounded skeleton-shimmer" />
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      ) : hasDbData ? (
        /* DB-sourced credential cards */
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {credentials.map((cred) => (
            <Card key={cred.id}>
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                  <FolderKey className="h-5 w-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                      {cred.service_name}
                    </p>
                    <StatusBadge status={cred.status} />
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-y-2 text-xs text-[var(--text-secondary)]">
                    <div>
                      <span className="opacity-60">Last Rotated</span>
                      <p className="text-[var(--text-primary)] mt-0.5">
                        {cred.last_rotated_at
                          ? formatRelativeTime(cred.last_rotated_at)
                          : 'Never'}
                      </p>
                    </div>
                    <div>
                      <span className="opacity-60">Next Rotation</span>
                      <p className="text-[var(--text-primary)] mt-0.5">
                        {cred.next_rotation_at
                          ? formatDate(cred.next_rotation_at)
                          : 'Not scheduled'}
                      </p>
                    </div>
                    <div>
                      <span className="opacity-60">Rotation Interval</span>
                      <p className="text-[var(--text-primary)] mt-0.5">
                        {cred.rotation_interval_days
                          ? `${cred.rotation_interval_days} days`
                          : 'Not set'}
                      </p>
                    </div>
                    <div>
                      <span className="opacity-60">Created</span>
                      <p className="text-[var(--text-primary)] mt-0.5">
                        {formatDate(cred.created_at)}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        /* Static fallback list */
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {STATIC_SERVICES.map((service) => (
            <Card key={service.name}>
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                  {service.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                      {service.name}
                    </p>
                    <StatusBadge status="pending" />
                  </div>
                  <p className="text-xs text-[var(--text-secondary)] mt-1">
                    {service.description}
                  </p>
                  <div className="mt-3 grid grid-cols-2 gap-y-2 text-xs text-[var(--text-secondary)]">
                    <div>
                      <span className="opacity-60">Last Rotated</span>
                      <p className="text-[var(--text-primary)] mt-0.5">Never</p>
                    </div>
                    <div>
                      <span className="opacity-60">Next Rotation</span>
                      <p className="text-[var(--text-primary)] mt-0.5">Not scheduled</p>
                    </div>
                    <div>
                      <span className="opacity-60">Rotation Interval</span>
                      <p className="text-[var(--text-primary)] mt-0.5">Not set</p>
                    </div>
                    <div>
                      <span className="opacity-60">Status</span>
                      <p className="text-[var(--text-primary)] mt-0.5">Not tracked</p>
                    </div>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
