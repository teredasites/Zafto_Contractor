'use client';

import { useEffect, useState } from 'react';
import {
  Database,
  Shield,
  HardDrive,
  Globe,
  CreditCard,
  AlertTriangle,
  Cpu,
  ShoppingCart,
  Mail,
  GitBranch,
  Activity,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface ServiceStatus {
  name: string;
  category: string;
  icon: React.ReactNode;
  status: 'unknown';
  lastChecked: string;
}

const SERVICES: ServiceStatus[] = [
  {
    name: 'Supabase (Database)',
    category: 'Infrastructure',
    icon: <Database className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Supabase (Auth)',
    category: 'Infrastructure',
    icon: <Shield className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Supabase (Storage)',
    category: 'Infrastructure',
    icon: <HardDrive className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Cloudflare (CDN/DNS)',
    category: 'Network',
    icon: <Globe className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Stripe (Payments)',
    category: 'Payments',
    icon: <CreditCard className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Sentry (Monitoring)',
    category: 'Observability',
    icon: <AlertTriangle className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'Claude API (AI)',
    category: 'AI',
    icon: <Cpu className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'RevenueCat (IAP)',
    category: 'Payments',
    icon: <ShoppingCart className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'MS 365 (Email)',
    category: 'Communication',
    icon: <Mail className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
  {
    name: 'GitHub Actions (CI/CD)',
    category: 'DevOps',
    icon: <GitBranch className="h-5 w-5" />,
    status: 'unknown',
    lastChecked: 'Not configured',
  },
];

export default function SystemStatusPage() {
  const [services, setServices] = useState<ServiceStatus[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate initial load — all services are placeholder status
    const timer = setTimeout(() => {
      setServices(SERVICES);
      setLoading(false);
    }, 400);

    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">
          System Status
        </h1>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          Service health monitoring will be live when API integrations are configured
        </p>
      </div>

      {/* Overall Status Bar */}
      <Card>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[var(--bg-elevated)]">
              <Activity className="h-5 w-5 text-[var(--text-secondary)]" />
            </div>
            <div>
              <p className="text-sm font-medium text-[var(--text-primary)]">
                Overall Platform Status
              </p>
              <p className="text-xs text-[var(--text-secondary)]">
                {services.length} services tracked
              </p>
            </div>
          </div>
          <Badge variant="warning">System Status: Not Configured</Badge>
        </div>
      </Card>

      {/* Service Cards Grid */}
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((i) => (
            <Card key={i}>
              <div className="flex items-start gap-3">
                <div className="h-10 w-10 rounded-lg skeleton-shimmer" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 w-32 rounded skeleton-shimmer" />
                  <div className="h-3 w-20 rounded skeleton-shimmer" />
                  <div className="h-5 w-16 rounded-full skeleton-shimmer" />
                </div>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {services.map((service) => (
            <Card key={service.name}>
              <div className="flex items-start gap-3">
                <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                  {service.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                    {service.name}
                  </p>
                  <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                    {service.category}
                  </p>
                  <div className="flex items-center justify-between mt-3">
                    <Badge variant="default">Unknown</Badge>
                    <span className="text-xs text-[var(--text-secondary)]">
                      {service.lastChecked}
                    </span>
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
