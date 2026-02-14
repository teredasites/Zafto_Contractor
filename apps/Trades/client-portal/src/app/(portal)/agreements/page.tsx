'use client';

import { useState, useEffect } from 'react';
import { FileText, Calendar, Clock, CheckCircle2, AlertTriangle, Loader2, Shield, DollarSign, Wrench, ChevronRight, Inbox } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface Agreement {
  id: string;
  title: string;
  status: string;
  agreementType: string;
  billingFrequency: string;
  billingAmount: number;
  startDate: string | null;
  endDate: string | null;
  nextServiceDate: string | null;
  services: { name: string; description?: string }[];
  companyName: string;
}

interface Visit {
  id: string;
  scheduledDate: string;
  completedDate: string | null;
  status: string;
  notes: string | null;
}

const statusColors: Record<string, { bg: string; text: string; label: string }> = {
  active: { bg: 'bg-green-50', text: 'text-green-700', label: 'Active' },
  draft: { bg: 'bg-gray-50', text: 'text-gray-600', label: 'Draft' },
  expired: { bg: 'bg-red-50', text: 'text-red-700', label: 'Expired' },
  cancelled: { bg: 'bg-gray-100', text: 'text-gray-500', label: 'Cancelled' },
  pending_renewal: { bg: 'bg-amber-50', text: 'text-amber-700', label: 'Pending Renewal' },
};

const typeLabels: Record<string, string> = {
  maintenance: 'Maintenance Plan',
  service: 'Service Contract',
  warranty: 'Warranty Agreement',
  support: 'Support Plan',
  inspection: 'Inspection Agreement',
  other: 'Agreement',
};

const billingLabels: Record<string, string> = {
  monthly: '/month',
  quarterly: '/quarter',
  semi_annual: '/6 months',
  annual: '/year',
  one_time: ' one-time',
};

function formatDate(d: string | null): string {
  if (!d) return '--';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatCurrency(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n);
}

export default function MyAgreementsPage() {
  const [agreements, setAgreements] = useState<Agreement[]>([]);
  const [visits, setVisits] = useState<Record<string, Visit[]>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setError('Not authenticated'); setLoading(false); return; }

      // Get customer record for this user
      const { data: customer } = await supabase
        .from('customers')
        .select('id, company_id')
        .eq('portal_user_id', user.id)
        .single();

      if (!customer) {
        setAgreements([]);
        setLoading(false);
        return;
      }

      // Fetch agreements for this customer
      const { data: agData, error: agErr } = await supabase
        .from('service_agreements')
        .select('*, companies(name)')
        .eq('customer_id', customer.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (agErr) { setError(agErr.message); setLoading(false); return; }

      const mapped: Agreement[] = (agData || []).map((row: Record<string, unknown>) => ({
        id: row.id as string,
        title: row.title as string,
        status: row.status as string,
        agreementType: row.agreement_type as string,
        billingFrequency: row.billing_frequency as string,
        billingAmount: Number(row.billing_amount || 0),
        startDate: row.start_date as string | null,
        endDate: row.end_date as string | null,
        nextServiceDate: row.next_service_date as string | null,
        services: Array.isArray(row.services) ? row.services as Agreement['services'] : [],
        companyName: (row.companies as Record<string, unknown>)?.name as string || '',
      }));

      setAgreements(mapped);

      // Fetch visits for all agreements
      const agreementIds = mapped.map(a => a.id);
      if (agreementIds.length > 0) {
        const { data: visitData } = await supabase
          .from('service_agreement_visits')
          .select('*')
          .in('agreement_id', agreementIds)
          .is('deleted_at', null)
          .order('scheduled_date', { ascending: false });

        const visitMap: Record<string, Visit[]> = {};
        (visitData || []).forEach((v: Record<string, unknown>) => {
          const agId = v.agreement_id as string;
          if (!visitMap[agId]) visitMap[agId] = [];
          visitMap[agId].push({
            id: v.id as string,
            scheduledDate: v.scheduled_date as string,
            completedDate: v.completed_date as string | null,
            status: v.status as string,
            notes: v.notes as string | null,
          });
        });
        setVisits(visitMap);
      }

      setLoading(false);
    };

    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="h-8 w-8 text-orange-500 animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
        <AlertTriangle className="h-8 w-8 text-red-500 mx-auto mb-3" />
        <p className="text-red-600 text-sm">{error}</p>
      </div>
    );
  }

  if (agreements.length === 0) {
    return (
      <div className="space-y-5">
        <h1 className="text-xl font-bold text-gray-900">My Agreements</h1>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-12 text-center">
          <Inbox className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500 text-sm">No service agreements yet</p>
          <p className="text-gray-400 text-xs mt-1">Your maintenance plans and service contracts will appear here</p>
        </div>
      </div>
    );
  }

  const activeCount = agreements.filter(a => a.status === 'active').length;
  const nextVisit = agreements
    .filter(a => a.nextServiceDate)
    .sort((a, b) => new Date(a.nextServiceDate!).getTime() - new Date(b.nextServiceDate!).getTime())[0];

  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold text-gray-900">My Agreements</h1>

      {/* Summary */}
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 text-center">
          <Shield className="h-5 w-5 text-green-500 mx-auto mb-1" />
          <p className="text-2xl font-bold text-gray-900">{activeCount}</p>
          <p className="text-[11px] text-gray-500">Active Plans</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 text-center">
          <Calendar className="h-5 w-5 text-blue-500 mx-auto mb-1" />
          <p className="text-sm font-bold text-gray-900 mt-1">{nextVisit ? formatDate(nextVisit.nextServiceDate) : '--'}</p>
          <p className="text-[11px] text-gray-500">Next Service Visit</p>
        </div>
      </div>

      {/* Agreement List */}
      <div className="space-y-3">
        {agreements.map(agreement => {
          const sc = statusColors[agreement.status] || statusColors.draft;
          const isExpanded = expandedId === agreement.id;
          const agVisits = visits[agreement.id] || [];

          return (
            <div key={agreement.id} className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
              <button
                className="w-full p-4 text-left"
                onClick={() => setExpandedId(isExpanded ? null : agreement.id)}
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-orange-50 rounded-lg shrink-0">
                    <Wrench className="h-5 w-5 text-orange-500" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-gray-900 truncate">{agreement.title}</span>
                      <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${sc.bg} ${sc.text}`}>
                        {sc.label}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {typeLabels[agreement.agreementType] || 'Agreement'} · {agreement.companyName}
                    </p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="text-sm font-bold text-gray-900">
                      {formatCurrency(agreement.billingAmount)}{billingLabels[agreement.billingFrequency] || ''}
                    </p>
                    <ChevronRight className={`h-4 w-4 text-gray-400 ml-auto transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
                  </div>
                </div>
              </button>

              {isExpanded && (
                <div className="px-4 pb-4 border-t border-gray-50 pt-3 space-y-3">
                  {/* Dates */}
                  <div className="grid grid-cols-3 gap-2 text-xs">
                    <div>
                      <p className="text-gray-400">Start</p>
                      <p className="font-medium text-gray-700">{formatDate(agreement.startDate)}</p>
                    </div>
                    <div>
                      <p className="text-gray-400">End</p>
                      <p className="font-medium text-gray-700">{formatDate(agreement.endDate)}</p>
                    </div>
                    <div>
                      <p className="text-gray-400">Next Visit</p>
                      <p className="font-medium text-gray-700">{formatDate(agreement.nextServiceDate)}</p>
                    </div>
                  </div>

                  {/* Included Services */}
                  {agreement.services.length > 0 && (
                    <div>
                      <p className="text-xs font-semibold text-gray-700 mb-1">Included Services</p>
                      <ul className="space-y-1">
                        {agreement.services.map((svc, i) => (
                          <li key={i} className="flex items-start gap-2 text-xs">
                            <CheckCircle2 className="h-3.5 w-3.5 text-green-500 mt-0.5 shrink-0" />
                            <span className="text-gray-600">{svc.name}{svc.description ? ` — ${svc.description}` : ''}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}

                  {/* Visit History */}
                  {agVisits.length > 0 && (
                    <div>
                      <p className="text-xs font-semibold text-gray-700 mb-1">Visit History</p>
                      <div className="space-y-1">
                        {agVisits.slice(0, 5).map(visit => (
                          <div key={visit.id} className="flex items-center gap-2 text-xs">
                            {visit.status === 'completed' ? (
                              <CheckCircle2 className="h-3 w-3 text-green-500" />
                            ) : visit.status === 'missed' ? (
                              <AlertTriangle className="h-3 w-3 text-red-500" />
                            ) : (
                              <Clock className="h-3 w-3 text-blue-500" />
                            )}
                            <span className="text-gray-600">{formatDate(visit.scheduledDate)}</span>
                            <span className="text-gray-400 capitalize">{visit.status}</span>
                            {visit.notes && <span className="text-gray-400 truncate">— {visit.notes}</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
