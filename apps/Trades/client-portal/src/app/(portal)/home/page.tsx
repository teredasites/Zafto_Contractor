'use client';
import { useState, useMemo } from 'react';
import Link from 'next/link';
import { MapPin, FileText, CreditCard, FileSignature, Hammer, Star, X, ChevronRight, CheckCircle2, Building2, Shield, AlertCircle, Home as HomeIcon, Wrench, ClipboardList, Calendar } from 'lucide-react';
import { useAuth } from '@/components/auth-provider';
import { useProjects } from '@/lib/hooks/use-projects';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useBids } from '@/lib/hooks/use-bids';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import { useTenant } from '@/lib/hooks/use-tenant';
import { useRentCharges } from '@/lib/hooks/use-rent-payments';
import { useMaintenanceRequests } from '@/lib/hooks/use-maintenance';
import { useHome } from '@/lib/hooks/use-home';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import { formatAddress, leaseStatusLabel } from '@/lib/hooks/tenant-mappers';

type Urgency = 'high' | 'medium' | 'low';
interface ActionCard { id: string; title: string; subtitle: string; detail?: string; urgency: Urgency; icon: typeof MapPin; cta: string; href: string; }

const urgencyBorder: Record<Urgency, string> = {
  high: 'var(--accent)',
  medium: 'var(--warning)',
  low: 'var(--border-light)',
};

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

function getFirstName(displayName: string | undefined): string {
  if (!displayName) return '';
  return displayName.split(' ')[0];
}

function LoadingSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header skeleton */}
      <div>
        <div className="h-7 w-56 rounded-md animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        <div className="h-4 w-40 rounded-md mt-2 animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
      </div>

      {/* Card skeletons */}
      <div className="space-y-3">
        {[1, 2, 3].map(i => (
          <div
            key={i}
            className="rounded-xl border p-4"
            style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)', borderLeftWidth: '3px', borderLeftColor: 'var(--border-light)' }}
          >
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-lg animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              <div className="flex-1 space-y-2">
                <div className="h-4 w-48 rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
                <div className="h-3 w-64 rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
              </div>
              <div className="h-4 w-16 rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            </div>
          </div>
        ))}
      </div>

      {/* Property skeleton */}
      <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="h-4 w-32 rounded animate-pulse mb-4" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        <div className="h-10 w-full rounded animate-pulse" style={{ backgroundColor: 'var(--bg-secondary)' }} />
      </div>
    </div>
  );
}

export default function HomePage() {
  const { profile, loading: authLoading } = useAuth();
  const { projects, loading: projectsLoading } = useProjects();
  const { invoices, loading: invoicesLoading } = useInvoices();
  const { bids, loading: bidsLoading } = useBids();
  const { orders, loading: ordersLoading } = useChangeOrders();
  const { tenant, lease, property, unit } = useTenant();
  const { balance, overdueCount } = useRentCharges();
  const { activeCount: maintenanceActive } = useMaintenanceRequests();
  const { equipment, healthScore, maintenanceDue } = useHome();

  const [dismissed, setDismissed] = useState<Set<string>>(new Set());

  const dataLoading = authLoading || projectsLoading || invoicesLoading || bidsLoading || ordersLoading;

  // Build action cards from real data
  const cards = useMemo<ActionCard[]>(() => {
    const result: ActionCard[] = [];

    // Overdue invoices — high urgency
    invoices
      .filter(inv => inv.status === 'overdue')
      .forEach(inv => {
        result.push({
          id: `inv-overdue-${inv.id}`,
          title: `Invoice ${inv.number} Overdue`,
          subtitle: `${inv.project || 'Invoice'}${inv.dueDate ? ' — was due ' + formatDate(inv.dueDate) : ''}`,
          detail: formatCurrency(inv.amount),
          urgency: 'high',
          icon: AlertCircle,
          cta: 'Pay Now',
          href: `/payments/${inv.id}`,
        });
      });

    // Due invoices — high urgency
    invoices
      .filter(inv => inv.status === 'due')
      .forEach(inv => {
        result.push({
          id: `inv-due-${inv.id}`,
          title: `Invoice ${inv.number} Due`,
          subtitle: `${inv.project || 'Invoice'}${inv.dueDate ? ' — due ' + formatDate(inv.dueDate) : ''}`,
          detail: formatCurrency(inv.amount),
          urgency: 'high',
          icon: CreditCard,
          cta: 'Pay Now',
          href: `/payments/${inv.id}`,
        });
      });

    // Pending bids — high urgency
    bids
      .filter(bid => bid.status === 'sent' || bid.status === 'pending')
      .forEach(bid => {
        result.push({
          id: `bid-${bid.id}`,
          title: `New Estimate Ready`,
          subtitle: `${bid.title || bid.number}${bid.totalAmount ? ' — ' + formatCurrency(bid.totalAmount) : ''}`,
          detail: bid.totalAmount ? formatCurrency(bid.totalAmount) : undefined,
          urgency: 'high',
          icon: FileText,
          cta: 'Review',
          href: `/projects`,
        });
      });

    // Pending change orders — medium urgency
    orders
      .filter(co => co.status === 'pending_approval')
      .forEach(co => {
        result.push({
          id: `co-${co.id}`,
          title: `Change Order ${co.orderNumber}`,
          subtitle: `${co.jobTitle || co.title}${co.amount ? ' — ' + formatCurrency(co.amount) : ''}`,
          detail: co.amount ? formatCurrency(co.amount) : undefined,
          urgency: 'medium',
          icon: FileSignature,
          cta: 'Review',
          href: `/projects`,
        });
      });

    // Active projects — low urgency
    projects
      .filter(proj => proj.status === 'active')
      .forEach(proj => {
        result.push({
          id: `proj-${proj.id}`,
          title: proj.name,
          subtitle: `${proj.trade ? proj.trade + ' — ' : ''}${proj.progress}% complete`,
          urgency: 'low',
          icon: Hammer,
          cta: 'View',
          href: `/projects/${proj.id}`,
        });
      });

    // Tenant: overdue rent — high urgency
    if (tenant && overdueCount > 0) {
      result.push({
        id: 'rent-overdue',
        title: `Rent Overdue`,
        subtitle: `${overdueCount} overdue charge${overdueCount !== 1 ? 's' : ''} — ${formatCurrency(balance)} due`,
        detail: formatCurrency(balance),
        urgency: 'high',
        icon: AlertCircle,
        cta: 'Pay Now',
        href: '/rent',
      });
    } else if (tenant && balance > 0) {
      // Rent due — medium urgency
      result.push({
        id: 'rent-due',
        title: 'Rent Due',
        subtitle: `Balance: ${formatCurrency(balance)}`,
        detail: formatCurrency(balance),
        urgency: 'medium',
        icon: CreditCard,
        cta: 'View',
        href: '/rent',
      });
    }

    // Tenant: active maintenance — medium urgency
    if (tenant && maintenanceActive > 0) {
      result.push({
        id: 'maintenance-active',
        title: `${maintenanceActive} Active Request${maintenanceActive !== 1 ? 's' : ''}`,
        subtitle: 'Maintenance requests in progress',
        urgency: 'medium',
        icon: Wrench,
        cta: 'Track',
        href: '/maintenance',
      });
    }

    // Tenant: lease expiring — medium urgency
    if (tenant && lease?.endDate) {
      const daysUntilExpiry = Math.ceil((new Date(lease.endDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      if (daysUntilExpiry > 0 && daysUntilExpiry <= 60) {
        result.push({
          id: 'lease-expiring',
          title: 'Lease Expiring Soon',
          subtitle: `${daysUntilExpiry} day${daysUntilExpiry !== 1 ? 's' : ''} remaining — expires ${formatDate(lease.endDate)}`,
          urgency: daysUntilExpiry <= 30 ? 'high' : 'medium',
          icon: Calendar,
          cta: 'View',
          href: '/lease',
        });
      }
    }

    return result;
  }, [invoices, bids, orders, projects, tenant, lease, balance, overdueCount, maintenanceActive]);

  const visible = cards
    .filter(c => !dismissed.has(c.id))
    .sort((a, b) => {
      const o: Record<Urgency, number> = { high: 0, medium: 1, low: 2 };
      return o[a.urgency] - o[b.urgency];
    });

  if (dataLoading) {
    return <LoadingSkeleton />;
  }

  const firstName = getFirstName(profile?.displayName);
  const greeting = getGreeting();

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: 'var(--text)' }}>
          {greeting}{firstName ? `, ${firstName}` : ''}
        </h1>
        <p className="text-sm mt-1" style={{ color: 'var(--text-muted)' }}>
          {visible.length > 0
            ? `You have ${visible.length} item${visible.length !== 1 ? 's' : ''} that need${visible.length === 1 ? 's' : ''} attention`
            : "You're all caught up!"}
        </p>
      </div>

      {/* Action Cards */}
      {visible.length > 0 ? (
        <div className="space-y-3">
          {visible.map((card, i) => {
            const Icon = card.icon;
            return (
              <div key={card.id} className="rounded-xl border p-4 transition-all hover:shadow-md animate-slide-up"
                style={{
                  backgroundColor: 'var(--surface)',
                  borderColor: 'var(--border-light)',
                  borderLeftWidth: '3px',
                  borderLeftColor: urgencyBorder[card.urgency],
                  animationDelay: `${i * 50}ms`,
                  animationFillMode: 'both',
                }}>
                <div className="flex items-start gap-3">
                  <div className="p-2 rounded-lg" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                    <Icon size={16} style={{ color: card.urgency === 'high' ? 'var(--accent)' : 'var(--text-muted)' }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{card.title}</h3>
                      {card.urgency === 'high' && <span className="w-2 h-2 rounded-full" style={{ backgroundColor: 'var(--accent)', animation: 'pulse-dot 2s ease-in-out infinite' }} />}
                    </div>
                    <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>{card.subtitle}</p>
                    {card.detail && <p className="text-sm font-semibold mt-1.5" style={{ color: card.urgency === 'high' ? 'var(--accent)' : 'var(--text)' }}>{card.detail}</p>}
                  </div>
                  <div className="flex items-center gap-2">
                    <Link href={card.href} className="text-xs font-semibold flex items-center gap-0.5 whitespace-nowrap" style={{ color: 'var(--accent)' }}>
                      {card.cta} <ChevronRight size={14} />
                    </Link>
                    <button onClick={() => setDismissed(new Set([...dismissed, card.id]))} className="p-1 rounded hover:bg-surface-hover">
                      <X size={14} style={{ color: 'var(--text-muted)' }} />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <CheckCircle2 size={32} style={{ color: 'var(--success)', margin: '0 auto 8px' }} />
          <p className="text-sm font-semibold" style={{ color: 'var(--text)' }}>You're all caught up!</p>
          <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>No action items right now. We'll notify you when something needs your attention.</p>
        </div>
      )}

      {/* Tenant: Rental Property Section */}
      {tenant && property && unit && lease ? (
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-bold" style={{ color: 'var(--text)' }}>Your Rental</h2>
            <Link href="/lease" className="text-xs font-medium flex items-center gap-1" style={{ color: 'var(--accent)' }}>Lease Details <ChevronRight size={12} /></Link>
          </div>
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <HomeIcon size={20} style={{ color: 'var(--text-muted)' }} />
            </div>
            <div>
              <p className="text-sm font-medium" style={{ color: 'var(--text)' }}>{formatAddress(property, unit)}</p>
              <p className="text-xs" style={{ color: 'var(--text-muted)' }}>
                {unit.bedrooms} bed / {unit.bathrooms} bath{unit.squareFootage ? ` / ${unit.squareFootage} sqft` : ''}
              </p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded-lg p-3 text-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <p className="text-lg font-bold" style={{ color: 'var(--accent)' }}>{formatCurrency(lease.rentAmount)}</p>
              <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Monthly Rent</p>
            </div>
            <Link href="/rent" className="rounded-lg p-3 text-center transition-colors hover:opacity-80" style={{ backgroundColor: balance > 0 ? 'color-mix(in srgb, var(--danger) 10%, transparent)' : 'var(--bg-secondary)' }}>
              <p className="text-lg font-bold" style={{ color: balance > 0 ? 'var(--danger)' : 'var(--success)' }}>
                {balance > 0 ? formatCurrency(balance) : 'Paid'}
              </p>
              <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Balance</p>
            </Link>
            <div className="rounded-lg p-3 text-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <p className="text-lg font-bold" style={{ color: 'var(--text)' }}>{leaseStatusLabel(lease.status)}</p>
              <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>Lease</p>
            </div>
          </div>
          <div className="flex gap-2 mt-4">
            <Link href="/rent" className="flex-1 text-center py-2 rounded-lg text-xs font-semibold transition-colors" style={{ backgroundColor: 'var(--accent)', color: 'white' }}>
              {balance > 0 ? 'Pay Rent' : 'Rent History'}
            </Link>
            <Link href="/maintenance" className="flex-1 text-center py-2 rounded-lg text-xs font-semibold border transition-colors" style={{ borderColor: 'var(--border-light)', color: 'var(--text)' }}>
              Request Maintenance
            </Link>
          </div>
        </div>
      ) : (
        /* Homeowner: Property Section (existing) */
        <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-bold" style={{ color: 'var(--text)' }}>Your Property</h2>
            <Link href="/my-home" className="text-xs font-medium flex items-center gap-1" style={{ color: 'var(--accent)' }}>View All <ChevronRight size={12} /></Link>
          </div>
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <HomeIcon size={20} style={{ color: 'var(--text-muted)' }} />
            </div>
            <div>
              <p className="text-sm font-medium" style={{ color: 'var(--text)' }}>Your property profile</p>
              <p className="text-xs" style={{ color: 'var(--text-muted)' }}>Equipment tracking &amp; service history</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            {[
              { label: 'Health Score', value: healthScore !== null ? `${healthScore}%` : '--', valueColor: healthScore !== null && healthScore >= 70 ? 'var(--success)' : healthScore !== null && healthScore >= 40 ? 'var(--warning)' : 'var(--text-muted)' },
              { label: 'Equipment', value: equipment.length > 0 ? String(equipment.length) : '--', valueColor: 'var(--text)' },
              { label: 'Next Service', value: maintenanceDue.length > 0 ? formatDate(maintenanceDue[0].nextDueDate) || '--' : '--', valueColor: 'var(--text)' },
            ].map(stat => (
              <div key={stat.label} className="rounded-lg p-3 text-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                <p className="text-lg font-bold" style={{ color: stat.valueColor }}>{stat.value}</p>
                <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Referral Banner */}
      <Link href="/referrals" className="block rounded-xl p-4 transition-all hover:opacity-90"
        style={{ background: 'linear-gradient(135deg, var(--accent), var(--accent-hover))' }}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
              <span className="text-white text-lg">🤝</span>
            </div>
            <div>
              <p className="text-sm font-semibold text-white">Know someone who needs a pro?</p>
              <p className="text-xs text-white/70">Share your contractor & earn rewards</p>
            </div>
          </div>
          <ChevronRight size={18} className="text-white/60" />
        </div>
      </Link>
    </div>
  );
}
