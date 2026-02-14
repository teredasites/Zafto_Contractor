'use client';

import { useEffect, useState, useCallback } from 'react';
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
  RefreshCw,
  CheckCircle2,
  XCircle,
  Clock,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

type HealthStatus = 'healthy' | 'degraded' | 'down' | 'unknown' | 'checking';

interface ServiceCheck {
  name: string;
  category: string;
  icon: React.ReactNode;
  status: HealthStatus;
  latencyMs: number | null;
  lastChecked: string | null;
  error: string | null;
}

const STATUS_CONFIG: Record<HealthStatus, { label: string; variant: 'success' | 'warning' | 'danger' | 'default'; icon: React.ReactNode }> = {
  healthy: { label: 'Healthy', variant: 'success', icon: <CheckCircle2 className="h-3.5 w-3.5" /> },
  degraded: { label: 'Degraded', variant: 'warning', icon: <AlertTriangle className="h-3.5 w-3.5" /> },
  down: { label: 'Down', variant: 'danger', icon: <XCircle className="h-3.5 w-3.5" /> },
  unknown: { label: 'Unknown', variant: 'default', icon: <Clock className="h-3.5 w-3.5" /> },
  checking: { label: 'Checking...', variant: 'default', icon: <RefreshCw className="h-3.5 w-3.5 animate-spin" /> },
};

async function checkEndpoint(url: string, timeoutMs = 5000): Promise<{ ok: boolean; latencyMs: number; error?: string }> {
  const start = performance.now();
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const res = await fetch(url, { method: 'HEAD', signal: controller.signal, cache: 'no-store' });
    clearTimeout(timer);
    const latencyMs = Math.round(performance.now() - start);
    return { ok: res.ok || res.status === 401 || res.status === 403, latencyMs };
  } catch (err) {
    const latencyMs = Math.round(performance.now() - start);
    return { ok: false, latencyMs, error: err instanceof Error ? err.message : 'Connection failed' };
  }
}

const SERVICE_DEFINITIONS = [
  { name: 'Supabase (Database)', category: 'Infrastructure', icon: <Database className="h-5 w-5" />, checkUrl: null, checkId: 'supabase_db' },
  { name: 'Supabase (Auth)', category: 'Infrastructure', icon: <Shield className="h-5 w-5" />, checkUrl: null, checkId: 'supabase_auth' },
  { name: 'Supabase (Storage)', category: 'Infrastructure', icon: <HardDrive className="h-5 w-5" />, checkUrl: null, checkId: 'supabase_storage' },
  { name: 'Cloudflare (CDN/DNS)', category: 'Network', icon: <Globe className="h-5 w-5" />, checkUrl: 'https://zafto.cloud', checkId: 'cloudflare' },
  { name: 'Stripe (Payments)', category: 'Payments', icon: <CreditCard className="h-5 w-5" />, checkUrl: 'https://api.stripe.com', checkId: 'stripe' },
  { name: 'Sentry (Monitoring)', category: 'Observability', icon: <AlertTriangle className="h-5 w-5" />, checkUrl: 'https://status.sentry.io', checkId: 'sentry' },
  { name: 'Claude API (AI)', category: 'AI', icon: <Cpu className="h-5 w-5" />, checkUrl: 'https://api.anthropic.com', checkId: 'claude' },
  { name: 'RevenueCat (IAP)', category: 'Payments', icon: <ShoppingCart className="h-5 w-5" />, checkUrl: 'https://api.revenuecat.com/v1', checkId: 'revenuecat' },
  { name: 'SendGrid (Email)', category: 'Communication', icon: <Mail className="h-5 w-5" />, checkUrl: 'https://api.sendgrid.com', checkId: 'sendgrid' },
  { name: 'GitHub Actions (CI/CD)', category: 'DevOps', icon: <GitBranch className="h-5 w-5" />, checkUrl: 'https://api.github.com', checkId: 'github' },
];

export default function SystemStatusPage() {
  const [services, setServices] = useState<ServiceCheck[]>(
    SERVICE_DEFINITIONS.map(s => ({
      name: s.name,
      category: s.category,
      icon: s.icon,
      status: 'unknown',
      latencyMs: null,
      lastChecked: null,
      error: null,
    }))
  );
  const [checking, setChecking] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);

  const runChecks = useCallback(async () => {
    setChecking(true);

    // Mark all as checking
    setServices(prev => prev.map(s => ({ ...s, status: 'checking' as HealthStatus })));

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;

    const results = await Promise.allSettled(
      SERVICE_DEFINITIONS.map(async (def) => {
        let url = def.checkUrl;

        // Supabase services use project URL
        if (def.checkId === 'supabase_db' && supabaseUrl) {
          url = `${supabaseUrl}/rest/v1/`;
        } else if (def.checkId === 'supabase_auth' && supabaseUrl) {
          url = `${supabaseUrl}/auth/v1/settings`;
        } else if (def.checkId === 'supabase_storage' && supabaseUrl) {
          url = `${supabaseUrl}/storage/v1/`;
        }

        if (!url) {
          return { name: def.name, status: 'unknown' as HealthStatus, latencyMs: null, error: 'No URL configured' };
        }

        const result = await checkEndpoint(url);
        const status: HealthStatus = result.ok
          ? (result.latencyMs > 3000 ? 'degraded' : 'healthy')
          : 'down';

        return {
          name: def.name,
          status,
          latencyMs: result.latencyMs,
          error: result.error || null,
        };
      })
    );

    const now = new Date();
    setServices(prev => prev.map((s, i) => {
      const result = results[i];
      if (result.status === 'fulfilled') {
        return {
          ...s,
          status: result.value.status,
          latencyMs: result.value.latencyMs,
          lastChecked: now.toISOString(),
          error: result.value.error,
        };
      }
      return { ...s, status: 'down', lastChecked: now.toISOString(), error: 'Check failed' };
    }));

    setLastRefresh(now);
    setChecking(false);
  }, []);

  // Auto-check on mount
  useEffect(() => {
    runChecks();

    // Refresh every 60 seconds
    const interval = setInterval(runChecks, 60000);
    return () => clearInterval(interval);
  }, [runChecks]);

  const healthyCount = services.filter(s => s.status === 'healthy').length;
  const degradedCount = services.filter(s => s.status === 'degraded').length;
  const downCount = services.filter(s => s.status === 'down').length;

  const overallStatus: HealthStatus = downCount > 0 ? 'down' : degradedCount > 0 ? 'degraded' : healthyCount > 0 ? 'healthy' : 'unknown';
  const overallConfig = STATUS_CONFIG[overallStatus];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            System Status
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Live service health monitoring · Auto-refreshes every 60s
          </p>
        </div>
        <button
          onClick={runChecks}
          disabled={checking}
          className="flex items-center gap-2 px-3 py-2 text-sm font-medium rounded-lg bg-[var(--bg-elevated)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${checking ? 'animate-spin' : ''}`} />
          {checking ? 'Checking...' : 'Refresh'}
        </button>
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
                {healthyCount} healthy · {degradedCount} degraded · {downCount} down · {services.length - healthyCount - degradedCount - downCount} unknown
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            {lastRefresh && (
              <span className="text-xs text-[var(--text-secondary)]">
                Last check: {lastRefresh.toLocaleTimeString()}
              </span>
            )}
            <Badge variant={overallConfig.variant}>
              <span className="flex items-center gap-1">
                {overallConfig.icon}
                {overallConfig.label}
              </span>
            </Badge>
          </div>
        </div>
      </Card>

      {/* Service Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {services.map((service) => {
          const config = STATUS_CONFIG[service.status];
          return (
            <Card key={service.name}>
              <div className="flex items-start gap-3">
                <div className={`p-2 rounded-lg ${
                  service.status === 'healthy' ? 'bg-emerald-500/10 text-emerald-500' :
                  service.status === 'degraded' ? 'bg-amber-500/10 text-amber-500' :
                  service.status === 'down' ? 'bg-red-500/10 text-red-500' :
                  'bg-[var(--accent)]/10 text-[var(--accent)]'
                }`}>
                  {service.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-[var(--text-primary)] truncate">
                    {service.name}
                  </p>
                  <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                    {service.category}
                    {service.latencyMs !== null && ` · ${service.latencyMs}ms`}
                  </p>
                  {service.error && (
                    <p className="text-[10px] text-red-500 mt-0.5 truncate">{service.error}</p>
                  )}
                  <div className="flex items-center justify-between mt-3">
                    <Badge variant={config.variant}>
                      <span className="flex items-center gap-1">
                        {config.icon}
                        {config.label}
                      </span>
                    </Badge>
                    {service.lastChecked && (
                      <span className="text-[10px] text-[var(--text-secondary)]">
                        {new Date(service.lastChecked).toLocaleTimeString()}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
