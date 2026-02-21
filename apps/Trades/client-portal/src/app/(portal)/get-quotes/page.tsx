'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useDraftRecovery } from '@/lib/hooks/use-draft-recovery';
import {
  Search, Star, Clock, DollarSign, CheckCircle2, Loader2, ChevronDown,
  Send, ArrowLeft, AlertTriangle, Users, FileText, XCircle,
} from 'lucide-react';
import {
  useQuotes,
  type TradeCategory,
  type ServiceType,
  type UrgencyLevel,
  type MarketplaceLead,
  type MarketplaceBid,
} from '@/lib/hooks/use-quotes';

const statusConfig: Record<string, { label: string; color: string; bg: string }> = {
  open:      { label: 'Open',      color: 'text-blue-700',   bg: 'bg-blue-50' },
  matched:   { label: 'Matched',   color: 'text-purple-700', bg: 'bg-purple-50' },
  quoted:    { label: 'Quoted',    color: 'text-amber-700',  bg: 'bg-amber-50' },
  accepted:  { label: 'Accepted',  color: 'text-green-700',  bg: 'bg-green-50' },
  completed: { label: 'Completed', color: 'text-green-700',  bg: 'bg-green-50' },
  cancelled: { label: 'Cancelled', color: 'text-gray-700',   bg: 'bg-gray-100' },
};

const urgencyConfig: Record<UrgencyLevel, { label: string; color: string }> = {
  normal:    { label: 'Normal',    color: 'text-gray-600' },
  soon:      { label: 'Soon',      color: 'text-blue-600' },
  urgent:    { label: 'Urgent',    color: 'text-amber-600' },
  emergency: { label: 'Emergency', color: 'text-red-600' },
};

function BidCard({ bid, onAccept, leadStatus }: { bid: MarketplaceBid; onAccept: () => void; leadStatus: string }) {
  return (
    <div className="bg-gray-50 rounded-xl p-3.5 border border-gray-100">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-orange-100 rounded-full flex items-center justify-center">
            <span className="text-xs font-bold text-orange-600">
              {bid.contractorName.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
            </span>
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-900">{bid.contractorName}</p>
            {bid.contractorRating && (
              <div className="flex items-center gap-0.5">
                <Star size={10} className="text-amber-400 fill-amber-400" />
                <span className="text-[10px] text-gray-500">{bid.contractorRating.toFixed(1)}</span>
              </div>
            )}
          </div>
        </div>
        <div className="text-right">
          <p className="text-lg font-bold text-gray-900">${bid.bidAmount.toLocaleString()}</p>
          {bid.estimatedTimeline && (
            <p className="text-[10px] text-gray-500 flex items-center gap-0.5 justify-end">
              <Clock size={8} /> {bid.estimatedTimeline}
            </p>
          )}
        </div>
      </div>
      {bid.description && (
        <p className="text-xs text-gray-600 mb-2">{bid.description}</p>
      )}
      {bid.status === 'accepted' ? (
        <div className="flex items-center gap-1 text-green-600 text-xs font-medium">
          <CheckCircle2 size={12} /> Accepted
        </div>
      ) : leadStatus === 'open' || leadStatus === 'quoted' ? (
        <button
          onClick={onAccept}
          className="w-full py-2 bg-orange-500 text-white rounded-lg text-xs font-bold hover:bg-orange-600 transition-colors"
        >
          Accept Bid
        </button>
      ) : null}
    </div>
  );
}

function LeadCard({ lead, onAcceptBid }: { lead: MarketplaceLead; onAcceptBid: (bidId: string) => void }) {
  const [expanded, setExpanded] = useState(false);
  const status = statusConfig[lead.status] || statusConfig.open;
  const urgency = urgencyConfig[lead.urgency] || urgencyConfig.normal;

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full p-4 text-left"
      >
        <div className="flex items-center gap-3">
          <div className="p-2.5 bg-orange-50 rounded-xl">
            <FileText size={18} className="text-orange-600" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <h3 className="font-semibold text-sm text-gray-900 capitalize">
                {lead.tradeCategory.replace(/_/g, ' ')} — {lead.serviceType}
              </h3>
              <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${status.bg} ${status.color}`}>
                {status.label}
              </span>
            </div>
            <p className="text-xs text-gray-500 truncate">{lead.description}</p>
            <div className="flex items-center gap-3 mt-1">
              <span className="text-[10px] text-gray-400">
                {new Date(lead.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
              </span>
              <span className={`text-[10px] font-medium ${urgency.color}`}>
                {urgency.label}
              </span>
              {lead.bids.length > 0 && (
                <span className="text-[10px] text-gray-400 flex items-center gap-0.5">
                  <Users size={8} /> {lead.bids.length} bid{lead.bids.length !== 1 ? 's' : ''}
                </span>
              )}
            </div>
          </div>
          <ChevronDown size={16} className={`text-gray-300 transition-transform ${expanded ? 'rotate-180' : ''}`} />
        </div>
      </button>

      {expanded && (
        <div className="px-4 pb-4 border-t border-gray-50 pt-3">
          <div className="text-xs text-gray-500 mb-3">
            <p><span className="font-medium text-gray-700">Address:</span> {lead.propertyAddress}</p>
            <p className="mt-1">{lead.description}</p>
          </div>

          {lead.bids.length === 0 ? (
            <div className="text-center py-4">
              <Clock size={20} className="mx-auto text-gray-300 mb-1" />
              <p className="text-xs text-gray-400">Waiting for contractor bids...</p>
            </div>
          ) : (
            <div className="space-y-2">
              <p className="text-xs font-medium text-gray-700">{lead.bids.length} Bid{lead.bids.length !== 1 ? 's' : ''} Received</p>
              {lead.bids.map(bid => (
                <BidCard
                  key={bid.id}
                  bid={bid}
                  leadStatus={lead.status}
                  onAccept={() => onAcceptBid(bid.id)}
                />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function GetQuotesPage() {
  const {
    leads, loading, submitting,
    submitQuoteRequest, acceptBid,
    TRADE_OPTIONS, SERVICE_TYPE_OPTIONS, URGENCY_OPTIONS,
  } = useQuotes();

  const [showForm, setShowForm] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  // Form state
  const [trade, setTrade] = useState<TradeCategory | ''>('');
  const [serviceType, setServiceType] = useState<ServiceType>('repair');
  const [urgency, setUrgency] = useState<UrgencyLevel>('normal');
  const [description, setDescription] = useState('');
  const [address, setAddress] = useState('');

  // Draft recovery — auto-save quote request form
  const draftRecovery = useDraftRecovery({
    feature: 'form',
    key: 'new-quote-request',
    screenRoute: '/get-quotes',
  });

  useEffect(() => {
    if (draftRecovery.hasDraft && !draftRecovery.checking) {
      const restored = draftRecovery.restoreDraft() as Record<string, string> | null;
      if (restored) {
        if (restored.trade) setTrade(restored.trade as TradeCategory);
        if (restored.serviceType) setServiceType(restored.serviceType as ServiceType);
        if (restored.urgency) setUrgency(restored.urgency as UrgencyLevel);
        if (restored.description) setDescription(restored.description);
        if (restored.address) setAddress(restored.address);
        setShowForm(true);
      }
      draftRecovery.markRecovered();
    }
  }, [draftRecovery.hasDraft, draftRecovery.checking]);

  useEffect(() => {
    if (showForm) {
      draftRecovery.saveDraft({ trade, serviceType, urgency, description, address });
    }
  }, [trade, serviceType, urgency, description, address, showForm]);

  const resetForm = () => {
    setTrade('');
    setServiceType('repair');
    setUrgency('normal');
    setDescription('');
    setAddress('');
  };

  const handleSubmit = async () => {
    if (!trade || !description || !address) return;
    try {
      await submitQuoteRequest({
        tradeCategory: trade,
        serviceType,
        urgency,
        description,
        propertyAddress: address,
      });
      resetForm();
      setShowForm(false);
      setSubmitted(true);
      setTimeout(() => setSubmitted(false), 4000);
    } catch {
      // Error handled
    }
  };

  const handleAcceptBid = async (bidId: string, leadId: string) => {
    try {
      await acceptBid(bidId, leadId);
    } catch {
      // Error handled
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Get Quotes</h1>
          <p className="text-sm text-gray-500 mt-0.5">Request quotes from local pros</p>
        </div>
        <button
          onClick={() => { setShowForm(!showForm); setSubmitted(false); }}
          className="flex items-center gap-1.5 px-3 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition-colors"
        >
          <Send size={16} /> Request Quote
        </button>
      </div>

      {/* Success Banner */}
      {submitted && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4 flex items-center gap-3">
          <CheckCircle2 size={20} className="text-green-600 shrink-0" />
          <div>
            <p className="text-sm font-medium text-green-800">Quote request submitted!</p>
            <p className="text-xs text-green-600">Contractors in your area will respond with bids. We will notify you as they come in.</p>
          </div>
        </div>
      )}

      {/* Request Form */}
      {showForm && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-sm text-gray-900">Request a Quote</h3>
            <button onClick={() => setShowForm(false)} className="p-1 text-gray-400 hover:text-gray-600">
              <XCircle size={16} />
            </button>
          </div>

          <div className="space-y-3">
            {/* Trade Category */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Trade Category *</label>
              <div className="relative">
                <select
                  value={trade}
                  onChange={e => setTrade(e.target.value as TradeCategory)}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm bg-white appearance-none"
                >
                  <option value="">Select a trade...</option>
                  {TRADE_OPTIONS.map(t => (
                    <option key={t.value} value={t.value}>{t.label}</option>
                  ))}
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>

            {/* Service Type */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Service Type</label>
              <div className="grid grid-cols-4 gap-2">
                {SERVICE_TYPE_OPTIONS.map(s => (
                  <button
                    key={s.value}
                    onClick={() => setServiceType(s.value)}
                    className={`py-2 rounded-xl border-2 text-center transition-all text-xs font-medium ${
                      serviceType === s.value
                        ? 'border-orange-500 bg-orange-50 text-orange-700'
                        : 'border-gray-100 text-gray-600 hover:border-gray-200'
                    }`}
                  >
                    {s.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Urgency */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Urgency</label>
              <div className="grid grid-cols-4 gap-2">
                {URGENCY_OPTIONS.map(u => (
                  <button
                    key={u.value}
                    onClick={() => setUrgency(u.value)}
                    className={`py-2 px-1 rounded-xl border-2 text-center transition-all ${
                      urgency === u.value
                        ? u.value === 'emergency'
                          ? 'border-red-500 bg-red-50'
                          : 'border-orange-500 bg-orange-50'
                        : 'border-gray-100 hover:border-gray-200'
                    }`}
                  >
                    <p className={`text-xs font-medium ${urgency === u.value && u.value === 'emergency' ? 'text-red-700' : urgency === u.value ? 'text-orange-700' : 'text-gray-600'}`}>
                      {u.label}
                    </p>
                    <p className="text-[10px] text-gray-400 mt-0.5">{u.desc}</p>
                  </button>
                ))}
              </div>
            </div>

            {urgency === 'emergency' && (
              <div className="bg-red-50 border border-red-200 rounded-xl p-3 flex items-center gap-2">
                <AlertTriangle size={16} className="text-red-600 shrink-0" />
                <p className="text-xs text-red-700">Emergency requests are prioritized and sent to all available contractors in your area immediately.</p>
              </div>
            )}

            {/* Description */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Describe What You Need *</label>
              <textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Tell contractors what you need done — the more detail, the more accurate the bids..."
                rows={3}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm resize-none"
              />
            </div>

            {/* Address */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Property Address *</label>
              <input
                value={address}
                onChange={e => setAddress(e.target.value)}
                placeholder="123 Main St, City, State ZIP"
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm"
              />
            </div>

            {/* Submit */}
            <button
              onClick={handleSubmit}
              disabled={!trade || !description || !address || submitting}
              className="w-full py-3 bg-orange-500 text-white rounded-xl text-sm font-bold hover:bg-orange-600 transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {submitting ? <><Loader2 size={16} className="animate-spin" /> Submitting...</> : 'Submit Quote Request'}
            </button>
          </div>
        </div>
      )}

      {/* Past Requests */}
      {leads.length === 0 && !showForm ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <DollarSign size={40} className="mx-auto text-gray-300 mb-3" />
          <h2 className="font-bold text-gray-900 mb-1">No Quote Requests Yet</h2>
          <p className="text-sm text-gray-500 mb-4">Request quotes from local contractors and compare bids side by side.</p>
          <button
            onClick={() => setShowForm(true)}
            className="px-4 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition-colors"
          >
            Request Your First Quote
          </button>
        </div>
      ) : (
        <div className="space-y-2">
          {leads.map(lead => (
            <LeadCard
              key={lead.id}
              lead={lead}
              onAcceptBid={(bidId) => handleAcceptBid(bidId, lead.id)}
            />
          ))}
        </div>
      )}

      {/* Marketplace Info */}
      <div className="bg-gray-50 rounded-xl p-4">
        <h3 className="font-bold text-xs text-gray-500 uppercase tracking-wider mb-2">How It Works</h3>
        <div className="space-y-2">
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 bg-orange-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <span className="text-[10px] font-bold text-orange-600">1</span>
            </div>
            <p className="text-xs text-gray-600">Describe what you need and submit your request</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 bg-orange-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <span className="text-[10px] font-bold text-orange-600">2</span>
            </div>
            <p className="text-xs text-gray-600">Local contractors review your request and submit bids</p>
          </div>
          <div className="flex items-start gap-2">
            <div className="w-5 h-5 bg-orange-100 rounded-full flex items-center justify-center shrink-0 mt-0.5">
              <span className="text-[10px] font-bold text-orange-600">3</span>
            </div>
            <p className="text-xs text-gray-600">Compare bids, read reviews, and accept the best offer</p>
          </div>
        </div>
      </div>
    </div>
  );
}
