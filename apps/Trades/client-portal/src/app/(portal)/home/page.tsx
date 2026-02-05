'use client';
import { useState } from 'react';
import Link from 'next/link';
import { MapPin, FileText, CreditCard, FileSignature, Wrench, Star, X, ChevronRight, CheckCircle2, Building2, Shield } from 'lucide-react';

type Urgency = 'high' | 'medium' | 'low';
interface ActionCard { id: string; title: string; subtitle: string; detail?: string; urgency: Urgency; icon: typeof MapPin; cta: string; href: string; }

const cards: ActionCard[] = [
  { id: '1', title: 'Mike is on the way', subtitle: 'Panel upgrade — arriving in 12 min', detail: 'ETA: 12 min', urgency: 'high', icon: MapPin, cta: 'Track', href: '/projects/proj-1/tracker' },
  { id: '2', title: 'New Estimate Ready', subtitle: 'HVAC Replacement — 3 options available', detail: '$8,400 – $14,200', urgency: 'high', icon: FileText, cta: 'Review & Approve', href: '/projects/proj-2/estimate' },
  { id: '3', title: 'Invoice #1042 Due', subtitle: 'Electrical panel upgrade — due Feb 10', detail: '$2,400.00', urgency: 'high', icon: CreditCard, cta: 'Pay Now', href: '/payments/inv-1' },
  { id: '4', title: 'Service Agreement', subtitle: 'Annual HVAC maintenance plan — review & sign', urgency: 'medium', icon: FileSignature, cta: 'Sign', href: '/projects/proj-2/agreement' },
  { id: '5', title: 'Maintenance Recommended', subtitle: 'Your water heater is 8 years old (avg lifespan: 10)', urgency: 'low', icon: Wrench, cta: 'Schedule Service', href: '/request' },
  { id: '6', title: 'How was your service?', subtitle: 'Bathroom remodel completed 3 days ago', urgency: 'low', icon: Star, cta: 'Leave Review', href: '/review' },
];

const urgencyBorder: Record<Urgency, string> = {
  high: 'var(--accent)',
  medium: 'var(--warning)',
  low: 'var(--border-light)',
};

export default function HomePage() {
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());
  const visible = cards.filter(c => !dismissed.has(c.id)).sort((a, b) => { const o = { high: 0, medium: 1, low: 2 }; return o[a.urgency] - o[b.urgency]; });

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: 'var(--text)' }}>Good morning, Sarah</h1>
        <p className="text-sm mt-1" style={{ color: 'var(--text-muted)' }}>You have {visible.length} items that need attention</p>
      </div>

      {/* Action Cards */}
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

      {/* Property Section */}
      <div className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-bold" style={{ color: 'var(--text)' }}>Your Property</h2>
          <Link href="/my-home" className="text-xs font-medium flex items-center gap-1" style={{ color: 'var(--accent)' }}>View All <ChevronRight size={12} /></Link>
        </div>
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-lg flex items-center justify-center text-lg" style={{ backgroundColor: 'var(--bg-secondary)' }}>🏠</div>
          <div>
            <p className="text-sm font-medium" style={{ color: 'var(--text)' }}>142 Maple Drive, Hartford CT 06010</p>
            <p className="text-xs" style={{ color: 'var(--text-muted)' }}>6 pieces of equipment tracked</p>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Health Score', value: '92%', icon: CheckCircle2, valueColor: 'var(--success)' },
            { label: 'Equipment', value: '6', icon: Building2, valueColor: 'var(--text)' },
            { label: 'Next Service', value: 'Feb 28, 2026', icon: Shield, valueColor: 'var(--text)' },
          ].map(stat => (
            <div key={stat.label} className="rounded-lg p-3 text-center" style={{ backgroundColor: 'var(--bg-secondary)' }}>
              <p className="text-lg font-bold" style={{ color: stat.valueColor }}>{stat.value}</p>
              <p className="text-[10px] font-medium" style={{ color: 'var(--text-muted)' }}>{stat.label}</p>
            </div>
          ))}
        </div>
      </div>

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
