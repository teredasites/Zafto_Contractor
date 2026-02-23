'use client';

import React, { useState } from 'react';
import {
  HardHat, Plus, Search, Filter, Star, AlertTriangle, Shield, FileText,
  Phone, Mail, ChevronDown, ChevronRight, X, Download, Briefcase,
  CheckCircle2, XCircle, Clock, DollarSign, Loader2,
} from 'lucide-react';
import { useSubcontractors, TRADE_TYPE_OPTIONS } from '@/lib/hooks/use-subcontractors';
import type { Subcontractor, ComplianceAlert } from '@/lib/hooks/use-subcontractors';
import { useTranslation } from '@/lib/translations';

type ViewMode = 'directory' | 'compliance' | '1099';

export default function SubcontractorsPage() {
  const { t } = useTranslation();
  const {
    subs, loading, error, complianceAlerts,
    createSub, updateSub, deleteSub, export1099Data,
  } = useSubcontractors();

  const [view, setView] = useState<ViewMode>('directory');
  const [search, setSearch] = useState('');
  const [tradeFilter, setTradeFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [editId, setEditId] = useState<string | null>(null);

  // Add form state
  const [formName, setFormName] = useState('');
  const [formCompany, setFormCompany] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formPhone, setFormPhone] = useState('');
  const [formTrades, setFormTrades] = useState<string[]>([]);
  const [formLicenseNum, setFormLicenseNum] = useState('');
  const [formLicenseState, setFormLicenseState] = useState('');
  const [formLicenseExpiry, setFormLicenseExpiry] = useState('');
  const [formInsCarrier, setFormInsCarrier] = useState('');
  const [formInsPolicy, setFormInsPolicy] = useState('');
  const [formInsExpiry, setFormInsExpiry] = useState('');
  const [formW9, setFormW9] = useState(false);
  const [formNotes, setFormNotes] = useState('');
  const [saving, setSaving] = useState(false);

  // Filtered subs
  const filtered = subs.filter((s) => {
    if (search && !s.name.toLowerCase().includes(search.toLowerCase()) && !s.companyName?.toLowerCase().includes(search.toLowerCase())) return false;
    if (tradeFilter && !s.tradeTypes.includes(tradeFilter)) return false;
    if (statusFilter && s.status !== statusFilter) return false;
    return true;
  });

  // Stats
  const activeSubs = subs.filter((s) => s.status === 'active').length;
  const totalPaid = subs.reduce((sum, s) => sum + s.totalPaid, 0);
  const alertCount = complianceAlerts.length;

  const resetForm = () => {
    setFormName(''); setFormCompany(''); setFormEmail(''); setFormPhone('');
    setFormTrades([]); setFormLicenseNum(''); setFormLicenseState('');
    setFormLicenseExpiry(''); setFormInsCarrier(''); setFormInsPolicy('');
    setFormInsExpiry(''); setFormW9(false); setFormNotes('');
  };

  const handleAdd = async () => {
    if (!formName.trim()) return;
    setSaving(true);
    try {
      await createSub({
        name: formName.trim(),
        companyName: formCompany || undefined,
        email: formEmail || undefined,
        phone: formPhone || undefined,
        tradeTypes: formTrades,
        licenseNumber: formLicenseNum || undefined,
        licenseState: formLicenseState || undefined,
        licenseExpiry: formLicenseExpiry || undefined,
        insuranceCarrier: formInsCarrier || undefined,
        insurancePolicyNumber: formInsPolicy || undefined,
        insuranceExpiry: formInsExpiry || undefined,
        w9OnFile: formW9,
        notes: formNotes || undefined,
      });
      resetForm();
      setShowAdd(false);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed to create');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Remove this subcontractor?')) return;
    try {
      await deleteSub(id);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Failed');
    }
  };

  const handleStatusToggle = async (sub: Subcontractor) => {
    const next = sub.status === 'active' ? 'inactive' : 'active';
    await updateSub(sub.id, { status: next });
  };

  const handleRating = async (id: string, rating: number) => {
    await updateSub(id, { rating });
  };

  const handle1099Export = async () => {
    const year = new Date().getFullYear();
    try {
      const csv = await export1099Data(year);
      const blob = new Blob([csv], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `1099-data-${year}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : 'Export failed');
    }
  };

  const toggleTrade = (trade: string) => {
    setFormTrades((prev) => prev.includes(trade) ? prev.filter((t) => t !== trade) : [...prev, trade]);
  };

  const formatTradeLabel = (t: string) => t.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-blue-400 animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 text-red-400 text-sm">{error}</div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <HardHat size={24} className="text-orange-400" />
            {t('subcontractors.title')}
          </h1>
          <p className="text-zinc-400 text-sm mt-1">Manage your subcontractor network</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={handle1099Export} className="bg-zinc-800 hover:bg-zinc-700 text-zinc-300 px-3 py-2 rounded-lg text-sm flex items-center gap-2">
            <Download size={14} /> 1099 Export
          </button>
          <button onClick={() => setShowAdd(true)} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2">
            <Plus size={14} /> Add Sub
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4">
          <div className="text-2xl font-bold text-white">{subs.length}</div>
          <div className="text-xs text-zinc-500">Total Subs</div>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4">
          <div className="text-2xl font-bold text-green-400">{activeSubs}</div>
          <div className="text-xs text-zinc-500">{t('common.active')}</div>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4">
          <div className="text-2xl font-bold text-white">${totalPaid.toLocaleString()}</div>
          <div className="text-xs text-zinc-500">{t('common.totalPaid')}</div>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-4">
          <div className={`text-2xl font-bold ${alertCount > 0 ? 'text-amber-400' : 'text-green-400'}`}>{alertCount}</div>
          <div className="text-xs text-zinc-500">Compliance Alerts</div>
        </div>
      </div>

      {/* View Tabs + Filters */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1 bg-zinc-900 rounded-lg p-1">
          {([
            { key: 'directory', label: 'Directory' },
            { key: 'compliance', label: `Compliance (${alertCount})` },
            { key: '1099', label: '1099 Report' },
          ] as const).map((tab) => (
            <button
              key={tab.key}
              onClick={() => setView(tab.key)}
              className={`px-3 py-1.5 rounded-md text-sm ${view === tab.key ? 'bg-blue-600 text-white' : 'text-zinc-400 hover:text-white'}`}
            >
              {tab.label}
            </button>
          ))}
        </div>
        {view === 'directory' && (
          <div className="flex items-center gap-2">
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-zinc-500" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search subs..."
                className="bg-zinc-900 border border-zinc-800 rounded-lg pl-9 pr-3 py-2 text-sm text-white w-56"
              />
            </div>
            <select
              value={tradeFilter}
              onChange={(e) => setTradeFilter(e.target.value)}
              className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-sm text-white"
            >
              <option value="">All Trades</option>
              {TRADE_TYPE_OPTIONS.map((t) => (
                <option key={t} value={t}>{formatTradeLabel(t)}</option>
              ))}
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-zinc-900 border border-zinc-800 rounded-lg px-3 py-2 text-sm text-white"
            >
              <option value="">{t('common.allStatus')}</option>
              <option value="active">{t('common.active')}</option>
              <option value="inactive">{t('common.inactive')}</option>
              <option value="suspended">Suspended</option>
            </select>
          </div>
        )}
      </div>

      {/* Directory View */}
      {view === 'directory' && (
        <div className="space-y-2">
          {filtered.length === 0 ? (
            <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-12 text-center">
              <HardHat size={40} className="text-zinc-700 mx-auto mb-3" />
              <p className="text-zinc-500">No subcontractors found</p>
              <button onClick={() => setShowAdd(true)} className="text-blue-400 text-sm mt-2 hover:text-blue-300">Add your first sub</button>
            </div>
          ) : filtered.map((sub) => (
            <div key={sub.id} className="bg-zinc-900 border border-zinc-800 rounded-lg overflow-hidden">
              <div
                className="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-zinc-800/50"
                onClick={() => setExpandedId(expandedId === sub.id ? null : sub.id)}
              >
                <div className="flex items-center gap-3">
                  {expandedId === sub.id ? <ChevronDown size={16} className="text-zinc-500" /> : <ChevronRight size={16} className="text-zinc-500" />}
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-white font-medium">{sub.name}</span>
                      {sub.companyName && <span className="text-zinc-500 text-sm">({sub.companyName})</span>}
                      <span className={`text-xs px-2 py-0.5 rounded-full ${
                        sub.status === 'active' ? 'bg-green-500/10 text-green-400' :
                        sub.status === 'suspended' ? 'bg-red-500/10 text-red-400' :
                        'bg-zinc-700 text-zinc-400'
                      }`}>{sub.status}</span>
                    </div>
                    <div className="flex items-center gap-3 mt-0.5">
                      {sub.tradeTypes.map((t) => (
                        <span key={t} className="text-xs text-zinc-500">{formatTradeLabel(t)}</span>
                      ))}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-4 text-sm">
                  {sub.rating && (
                    <div className="flex items-center gap-1 text-amber-400">
                      <Star size={14} fill="currentColor" /> {sub.rating}
                    </div>
                  )}
                  <span className="text-zinc-400">{sub.totalJobsAssigned} jobs</span>
                  <span className="text-green-400">${sub.totalPaid.toLocaleString()}</span>
                </div>
              </div>

              {expandedId === sub.id && (
                <div className="border-t border-zinc-800 px-4 py-4 space-y-4">
                  {/* Contact */}
                  <div className="grid grid-cols-3 gap-4 text-sm">
                    <div className="flex items-center gap-2 text-zinc-400">
                      <Mail size={14} /> {sub.email || 'No email'}
                    </div>
                    <div className="flex items-center gap-2 text-zinc-400">
                      <Phone size={14} /> {sub.phone || 'No phone'}
                    </div>
                    <div className="flex items-center gap-2 text-zinc-400">
                      <Briefcase size={14} /> {sub.totalJobsAssigned} jobs assigned
                    </div>
                  </div>

                  {/* Compliance */}
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-zinc-800 rounded-lg p-3">
                      <div className="text-xs text-zinc-500 mb-1">{t('common.license')}</div>
                      {sub.licenseNumber ? (
                        <div className="text-sm text-white">
                          {sub.licenseNumber} ({sub.licenseState})
                          {sub.licenseExpiry && (
                            <div className="text-xs text-zinc-500 mt-0.5">Exp: {sub.licenseExpiry}</div>
                          )}
                        </div>
                      ) : (
                        <div className="text-sm text-zinc-600">{t('common.notProvided')}</div>
                      )}
                    </div>
                    <div className="bg-zinc-800 rounded-lg p-3">
                      <div className="text-xs text-zinc-500 mb-1">{t('common.insurance')}</div>
                      {sub.insuranceCarrier ? (
                        <div className="text-sm text-white">
                          {sub.insuranceCarrier}
                          {sub.insuranceExpiry && (
                            <div className="text-xs text-zinc-500 mt-0.5">Exp: {sub.insuranceExpiry}</div>
                          )}
                        </div>
                      ) : (
                        <div className="text-sm text-zinc-600">{t('common.notProvided')}</div>
                      )}
                    </div>
                    <div className="bg-zinc-800 rounded-lg p-3">
                      <div className="text-xs text-zinc-500 mb-1">W-9</div>
                      <div className={`text-sm flex items-center gap-1 ${sub.w9OnFile ? 'text-green-400' : 'text-red-400'}`}>
                        {sub.w9OnFile ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                        {sub.w9OnFile ? 'On File' : 'Missing'}
                      </div>
                    </div>
                  </div>

                  {/* Rating */}
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-zinc-500">Rating:</span>
                    {[1, 2, 3, 4, 5].map((r) => (
                      <button
                        key={r}
                        onClick={() => handleRating(sub.id, r)}
                        className="transition-colors"
                      >
                        <Star
                          size={16}
                          className={r <= (sub.rating || 0) ? 'text-amber-400' : 'text-zinc-700'}
                          fill={r <= (sub.rating || 0) ? 'currentColor' : 'none'}
                        />
                      </button>
                    ))}
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 pt-2 border-t border-zinc-800">
                    <button
                      onClick={() => handleStatusToggle(sub)}
                      className="text-xs text-zinc-400 hover:text-white px-3 py-1.5 rounded-lg bg-zinc-800"
                    >
                      {sub.status === 'active' ? 'Deactivate' : 'Activate'}
                    </button>
                    <button onClick={() => handleDelete(sub.id)} className="text-xs text-red-400 hover:text-red-300 px-3 py-1.5 rounded-lg bg-zinc-800">
                      Remove
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Compliance View */}
      {view === 'compliance' && (
        <div className="space-y-2">
          {complianceAlerts.length === 0 ? (
            <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-12 text-center">
              <Shield size={40} className="text-green-400 mx-auto mb-3" />
              <p className="text-green-400 font-medium">All Clear</p>
              <p className="text-zinc-500 text-sm mt-1">No compliance issues found</p>
            </div>
          ) : (
            complianceAlerts.map((alert, i) => (
              <div key={`${alert.subcontractorId}-${alert.type}-${i}`} className="bg-zinc-900 border border-zinc-800 rounded-lg px-4 py-3 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <AlertTriangle size={16} className={
                    alert.type === 'missing_w9' ? 'text-red-400' :
                    (alert.daysRemaining || 0) <= 7 ? 'text-red-400' : 'text-amber-400'
                  } />
                  <div>
                    <span className="text-white font-medium">{alert.name}</span>
                    <span className="text-zinc-500 text-sm ml-2">
                      {alert.type === 'insurance_expiring' && `Insurance expires ${alert.expiryDate} (${alert.daysRemaining} days)`}
                      {alert.type === 'license_expiring' && `License expires ${alert.expiryDate} (${alert.daysRemaining} days)`}
                      {alert.type === 'missing_w9' && 'W-9 not on file'}
                    </span>
                  </div>
                </div>
                <span className={`text-xs px-2 py-1 rounded-full ${
                  alert.type === 'missing_w9' ? 'bg-red-500/10 text-red-400' :
                  (alert.daysRemaining || 0) <= 7 ? 'bg-red-500/10 text-red-400' :
                  'bg-amber-500/10 text-amber-400'
                }`}>
                  {alert.type === 'missing_w9' ? 'Missing' : `${alert.daysRemaining}d`}
                </span>
              </div>
            ))
          )}
        </div>
      )}

      {/* 1099 View */}
      {view === '1099' && (
        <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-white font-medium flex items-center gap-2">
                <FileText size={18} className="text-blue-400" />
                1099-NEC Data — {new Date().getFullYear()}
              </h3>
              <p className="text-zinc-500 text-xs mt-1">Subcontractors paid $600+ this calendar year</p>
            </div>
            <button onClick={handle1099Export} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm flex items-center gap-2">
              <Download size={14} /> Export CSV
            </button>
          </div>

          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-zinc-700">
                <th className="text-left py-2 text-zinc-500">{t('common.name')}</th>
                <th className="text-left py-2 text-zinc-500">{t('common.company')}</th>
                <th className="text-right py-2 text-zinc-500">{t('common.totalPaid')}</th>
                <th className="text-center py-2 text-zinc-500">1099 Required</th>
              </tr>
            </thead>
            <tbody>
              {subs.filter((s) => s.totalPaid >= 600).length === 0 ? (
                <tr>
                  <td colSpan={4} className="text-center text-zinc-600 py-8">No subcontractors paid $600+ yet</td>
                </tr>
              ) : (
                subs.filter((s) => s.totalPaid >= 600).map((sub) => (
                  <tr key={sub.id} className="border-b border-zinc-800">
                    <td className="py-2 text-white">{sub.name}</td>
                    <td className="py-2 text-zinc-400">{sub.companyName || '-'}</td>
                    <td className="py-2 text-right text-green-400">${sub.totalPaid.toLocaleString()}</td>
                    <td className="py-2 text-center">
                      <CheckCircle2 size={16} className="text-amber-400 mx-auto" />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Add Sub Modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50" onClick={() => setShowAdd(false)}>
          <div className="bg-zinc-900 border border-zinc-800 rounded-xl w-full max-w-lg max-h-[85vh] overflow-y-auto p-6 space-y-4" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-white font-semibold text-lg">Add Subcontractor</h3>
              <button onClick={() => setShowAdd(false)} className="text-zinc-500 hover:text-white"><X size={18} /></button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="text-xs text-zinc-500 mb-1 block">{t('common.nameRequired')}</label>
                <input value={formName} onChange={(e) => setFormName(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
              </div>
              <div>
                <label className="text-xs text-zinc-500 mb-1 block">Company Name</label>
                <input value={formCompany} onChange={(e) => setFormCompany(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">{t('common.email')}</label>
                  <input value={formEmail} onChange={(e) => setFormEmail(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">{t('common.phone')}</label>
                  <input value={formPhone} onChange={(e) => setFormPhone(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
              </div>

              <div>
                <label className="text-xs text-zinc-500 mb-1 block">Trades</label>
                <div className="flex flex-wrap gap-1.5">
                  {TRADE_TYPE_OPTIONS.map((t) => (
                    <button
                      key={t}
                      onClick={() => toggleTrade(t)}
                      className={`text-xs px-2 py-1 rounded-full border ${
                        formTrades.includes(t) ? 'border-blue-500 bg-blue-500/10 text-blue-400' : 'border-zinc-700 text-zinc-500'
                      }`}
                    >
                      {formatTradeLabel(t)}
                    </button>
                  ))}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">License #</label>
                  <input value={formLicenseNum} onChange={(e) => setFormLicenseNum(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">{t('common.licenseState')}</label>
                  <input value={formLicenseState} onChange={(e) => setFormLicenseState(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">License Expiry</label>
                  <input type="date" value={formLicenseExpiry} onChange={(e) => setFormLicenseExpiry(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Insurance Carrier</label>
                  <input value={formInsCarrier} onChange={(e) => setFormInsCarrier(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">{t('common.policyNumber')}</label>
                  <input value={formInsPolicy} onChange={(e) => setFormInsPolicy(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
                <div>
                  <label className="text-xs text-zinc-500 mb-1 block">Insurance Expiry</label>
                  <input type="date" value={formInsExpiry} onChange={(e) => setFormInsExpiry(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
                </div>
              </div>

              <label className="flex items-center gap-2 text-sm text-zinc-400 cursor-pointer">
                <input type="checkbox" checked={formW9} onChange={(e) => setFormW9(e.target.checked)} className="rounded" />
                W-9 on file
              </label>

              <div>
                <label className="text-xs text-zinc-500 mb-1 block">{t('common.notes')}</label>
                <textarea value={formNotes} onChange={(e) => setFormNotes(e.target.value)} rows={2} className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-white" />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-zinc-800">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 text-sm text-zinc-400 hover:text-white">{t('common.cancel')}</button>
              <button onClick={handleAdd} disabled={saving || !formName.trim()} className="bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white px-6 py-2 rounded-lg text-sm font-medium">
                {saving ? 'Saving...' : 'Add Subcontractor'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
