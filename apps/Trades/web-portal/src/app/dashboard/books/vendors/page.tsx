'use client';

import { useState } from 'react';
import {
  Plus, Search, ArrowLeft, Pencil, Trash2, AlertTriangle,
  User, Mail, Phone, MapPin, FileText, Building,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useVendors,
  VENDOR_TYPE_LABELS,
  VENDOR_TYPES,
  PAYMENT_TERMS,
  PAYMENT_TERMS_LABELS,
} from '@/lib/hooks/use-vendors';
import type { VendorData } from '@/lib/hooks/use-vendors';
import { useTranslation } from '@/lib/translations';

export default function VendorsPage() {
  const { t } = useTranslation();
  const { vendors, loading, error, createVendor, updateVendor, deleteVendor } = useVendors();
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingVendor, setEditingVendor] = useState<VendorData | null>(null);
  const [detailVendor, setDetailVendor] = useState<VendorData | null>(null);

  const filtered = vendors.filter((v) => {
    if (!v.isActive) return false;
    if (filterType !== 'all' && v.vendorType !== filterType) return false;
    if (search) {
      const q = search.toLowerCase();
      return v.vendorName.toLowerCase().includes(q) ||
        (v.contactName?.toLowerCase().includes(q) ?? false) ||
        (v.email?.toLowerCase().includes(q) ?? false);
    }
    return true;
  });

  const totalYTD = vendors.reduce((s, v) => s + (v.ytdPayments || 0), 0);
  const vendors1099 = vendors.filter((v) => v.is1099Eligible && (v.ytdPayments || 0) >= 600);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/books" className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </Link>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('booksVendors.title')}</h1>
            <p className="text-muted mt-0.5">{vendors.filter((v) => v.isActive).length} active vendors</p>
          </div>
        </div>
        <Button onClick={() => { setEditingVendor(null); setModalOpen(true); }}>
          <Plus size={16} />
          Add Vendor
        </Button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">{t('booksVendors.activeVendors')}</p>
            <p className="text-2xl font-semibold text-main mt-1">{vendors.filter((v) => v.isActive).length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">{t('common.ytdPayments')}</p>
            <p className="text-2xl font-semibold text-main mt-1">{formatCurrency(totalYTD)}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">1099 Vendors</p>
            <div className="flex items-center gap-2 mt-1">
              <p className="text-2xl font-semibold text-main">{vendors1099.length}</p>
              {vendors1099.length > 0 && (
                <Badge variant="warning" size="sm">
                  <AlertTriangle size={10} />
                  Reportable
                </Badge>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <Input placeholder={t('vendors.searchVendors')} value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
        </div>
        <div className="flex items-center gap-1.5">
          {['all', ...VENDOR_TYPES].map((type) => (
            <button
              key={type}
              onClick={() => setFilterType(type)}
              className={cn(
                'px-3 py-1.5 text-xs font-medium rounded-md transition-colors',
                filterType === type ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main'
              )}
            >
              {type === 'all' ? 'All' : VENDOR_TYPE_LABELS[type]}
            </button>
          ))}
        </div>
      </div>

      {error && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">{error}</div>
      )}

      {/* Vendor List */}
      <Card>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {filtered.length === 0 && (
              <div className="px-6 py-12 text-center text-sm text-muted">{t('booksVendors.noVendorsFound')}</div>
            )}
            {filtered.map((vendor) => (
              <div
                key={vendor.id}
                className="px-6 py-4 hover:bg-surface-hover transition-colors cursor-pointer flex items-center gap-4"
                onClick={() => setDetailVendor(vendor)}
              >
                <div className="p-2 bg-secondary rounded-lg">
                  <Building size={18} className="text-muted" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-main">{vendor.vendorName}</span>
                    <Badge variant="default" size="sm">{VENDOR_TYPE_LABELS[vendor.vendorType]}</Badge>
                    {vendor.is1099Eligible && (
                      <Badge variant="warning" size="sm">1099</Badge>
                    )}
                  </div>
                  <div className="flex items-center gap-3 mt-1 text-sm text-muted">
                    {vendor.contactName && <span>{vendor.contactName}</span>}
                    {vendor.email && <span>{vendor.email}</span>}
                    {vendor.phone && <span>{vendor.phone}</span>}
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-main tabular-nums">{formatCurrency(vendor.ytdPayments || 0)}</p>
                  <p className="text-xs text-muted">{t('booksVendors.ytd')}</p>
                </div>
                <div className="flex items-center gap-1">
                  <button
                    onClick={(e) => { e.stopPropagation(); setEditingVendor(vendor); setModalOpen(true); }}
                    className="p-1.5 text-muted hover:text-main rounded transition-colors"
                  >
                    <Pencil size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Detail Panel */}
      {detailVendor && (
        <VendorDetailPanel
          vendor={detailVendor}
          onClose={() => setDetailVendor(null)}
          onEdit={() => { setEditingVendor(detailVendor); setModalOpen(true); setDetailVendor(null); }}
          onDelete={async () => { await deleteVendor(detailVendor.id); setDetailVendor(null); }}
        />
      )}

      {/* Add/Edit Modal */}
      {modalOpen && (
        <VendorModal
          vendor={editingVendor}
          onSave={async (data) => {
            if (editingVendor) {
              await updateVendor(editingVendor.id, data);
            } else {
              await createVendor(data as Parameters<typeof createVendor>[0]);
            }
            setModalOpen(false);
            setEditingVendor(null);
          }}
          onClose={() => { setModalOpen(false); setEditingVendor(null); }}
        />
      )}
    </div>
  );
}

function VendorDetailPanel({ vendor, onClose, onEdit, onDelete }: {
  vendor: VendorData;
  onClose: () => void;
  onEdit: () => void;
  onDelete: () => Promise<void>;
}) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="px-6 py-4 border-b border-main flex items-center justify-between">
          <h2 className="text-lg font-semibold text-main">{vendor.vendorName}</h2>
          <div className="flex items-center gap-2">
            <Button variant="secondary" size="sm" onClick={onEdit}><Pencil size={14} /> Edit</Button>
            <Button variant="secondary" size="sm" onClick={onDelete} className="text-red-600 hover:text-red-700"><Trash2 size={14} /></Button>
          </div>
        </div>
        <div className="p-6 space-y-4">
          <div className="flex items-center gap-2">
            <Badge variant="default">{VENDOR_TYPE_LABELS[vendor.vendorType]}</Badge>
            <Badge variant="default">{PAYMENT_TERMS_LABELS[vendor.paymentTerms]}</Badge>
            {vendor.is1099Eligible && <Badge variant="warning">1099 Eligible</Badge>}
          </div>

          {vendor.contactName && <DetailRow icon={<User size={14} />} label="Contact" value={vendor.contactName} />}
          {vendor.email && <DetailRow icon={<Mail size={14} />} label="Email" value={vendor.email} />}
          {vendor.phone && <DetailRow icon={<Phone size={14} />} label="Phone" value={vendor.phone} />}
          {(vendor.address || vendor.city) && (
            <DetailRow icon={<MapPin size={14} />} label="Address" value={[vendor.address, vendor.city, vendor.state, vendor.zip].filter(Boolean).join(', ')} />
          )}
          {vendor.taxId && <DetailRow icon={<FileText size={14} />} label="Tax ID" value={vendor.taxId} />}
          {vendor.notes && <DetailRow icon={<FileText size={14} />} label="Notes" value={vendor.notes} />}

          <div className="pt-3 border-t border-main">
            <p className="text-xs text-muted uppercase tracking-wide mb-2">YTD Payments</p>
            <p className="text-2xl font-semibold text-main">{formatCurrency(vendor.ytdPayments || 0)}</p>
            {vendor.is1099Eligible && (vendor.ytdPayments || 0) >= 600 && (
              <p className="text-sm text-amber-600 mt-1">1099-NEC required (payments exceed $600)</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function DetailRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-start gap-3">
      <div className="text-muted mt-0.5">{icon}</div>
      <div>
        <p className="text-xs text-muted">{label}</p>
        <p className="text-sm text-main">{value}</p>
      </div>
    </div>
  );
}

function VendorModal({ vendor, onSave, onClose }: {
  vendor: VendorData | null;
  onSave: (data: Record<string, unknown>) => Promise<void>;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const isEdit = !!vendor;
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [vendorName, setVendorName] = useState(vendor?.vendorName || '');
  const [contactName, setContactName] = useState(vendor?.contactName || '');
  const [email, setEmail] = useState(vendor?.email || '');
  const [phone, setPhone] = useState(vendor?.phone || '');
  const [address, setAddress] = useState(vendor?.address || '');
  const [city, setCity] = useState(vendor?.city || '');
  const [state, setState] = useState(vendor?.state || '');
  const [zip, setZip] = useState(vendor?.zip || '');
  const [vendorType, setVendorType] = useState(vendor?.vendorType || 'supplier');
  const [paymentTerms, setPaymentTerms] = useState(vendor?.paymentTerms || 'net_30');
  const [is1099Eligible, setIs1099Eligible] = useState(vendor?.is1099Eligible || false);
  const [taxId, setTaxId] = useState(vendor?.taxId || '');
  const [notes, setNotes] = useState(vendor?.notes || '');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      if (!vendorName.trim()) throw new Error('Vendor name is required');
      await onSave({
        vendorName: vendorName.trim(),
        contactName: contactName || null,
        email: email || null,
        phone: phone || null,
        address: address || null,
        city: city || null,
        state: state || null,
        zip: zip || null,
        vendorType,
        paymentTerms,
        is1099Eligible,
        taxId: taxId || null,
        notes: notes || null,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Save failed');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main max-h-[85vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">{isEdit ? 'Edit Vendor' : 'Add Vendor'}</h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1">Vendor Name *</label>
            <Input value={vendorName} onChange={(e) => setVendorName(e.target.value)} required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.type')}</label>
              <select value={vendorType} onChange={(e) => setVendorType(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                {VENDOR_TYPES.map((t) => <option key={t} value={t}>{VENDOR_TYPE_LABELS[t]}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('settings.paymentTerms')}</label>
              <select value={paymentTerms} onChange={(e) => setPaymentTerms(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
                {PAYMENT_TERMS.map((t) => <option key={t} value={t}>{PAYMENT_TERMS_LABELS[t]}</option>)}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('booksVendors.contactName')}</label>
              <Input value={contactName} onChange={(e) => setContactName(e.target.value)} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.phone')}</label>
              <Input type="tel" placeholder="(555) 123-4567" value={phone} onChange={(e) => {
                const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                setPhone(formatted);
              }} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">{t('common.email')}</label>
            <Input value={email} onChange={(e) => setEmail(e.target.value)} type="email" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">{t('common.address')}</label>
            <Input value={address} onChange={(e) => setAddress(e.target.value)} placeholder={t('common.street')} />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <Input value={city} onChange={(e) => setCity(e.target.value)} placeholder={t('common.city')} />
            <Input value={state} onChange={(e) => setState(e.target.value)} placeholder={t('common.state')} />
            <Input value={zip} onChange={(e) => setZip(e.target.value)} placeholder={t('common.zip')} />
          </div>
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm text-main cursor-pointer">
              <input type="checkbox" checked={is1099Eligible} onChange={(e) => setIs1099Eligible(e.target.checked)} className="rounded" />
              1099 Eligible
            </label>
            {is1099Eligible && (
              <div className="flex-1">
                <Input value={taxId} onChange={(e) => setTaxId(e.target.value)} placeholder="Tax ID / EIN" />
              </div>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">{t('common.notes')}</label>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={2} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none" />
          </div>
          {err && <p className="text-sm text-red-600">{err}</p>}
          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>{t('common.cancel')}</Button>
            <Button type="submit" disabled={saving}>{saving ? 'Saving...' : isEdit ? 'Save Changes' : 'Add Vendor'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
