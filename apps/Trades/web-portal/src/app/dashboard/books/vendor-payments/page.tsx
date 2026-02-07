'use client';

import { useState, useCallback, useEffect } from 'react';
import {
  Plus, ArrowLeft, Search, DollarSign, CheckCircle,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useVendors } from '@/lib/hooks/use-vendors';
import { createVendorPaymentJournal } from '@/lib/hooks/use-zbooks-engine';
import { getSupabase } from '@/lib/supabase';

interface PaymentRecord {
  id: string;
  vendorId: string;
  vendorName: string;
  paymentDate: string;
  amount: number;
  paymentMethod: string;
  checkNumber: string | null;
  reference: string | null;
  description: string | null;
  is1099Reportable: boolean;
  createdAt: string;
}

const methodLabels: Record<string, string> = {
  check: 'Check', bank_transfer: 'Bank Transfer',
  credit_card: 'Credit Card', cash: 'Cash',
};

export default function VendorPaymentsPage() {
  const { vendors } = useVendors();
  const [payments, setPayments] = useState<PaymentRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [search, setSearch] = useState('');

  const fetchPayments = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('vendor_payments')
        .select('*, vendors(vendor_name, is_1099_eligible)')
        .order('payment_date', { ascending: false });

      if (err) throw err;
      setPayments((data || []).map((row: Record<string, unknown>) => {
        const vendor = row.vendors as Record<string, unknown> | null;
        return {
          id: row.id as string,
          vendorId: row.vendor_id as string,
          vendorName: vendor?.vendor_name as string || '',
          paymentDate: row.payment_date as string,
          amount: Number(row.amount || 0),
          paymentMethod: row.payment_method as string,
          checkNumber: row.check_number as string | null,
          reference: row.reference as string | null,
          description: row.description as string | null,
          is1099Reportable: row.is_1099_reportable as boolean,
          createdAt: row.created_at as string,
        };
      }));
    } catch (_) {
      setPayments([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPayments();
  }, [fetchPayments]);

  const createPayment = async (data: {
    vendorId: string;
    paymentDate: string;
    amount: number;
    paymentMethod: string;
    checkNumber?: string;
    reference?: string;
    description?: string;
  }) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Check if vendor is 1099-eligible
    const vendor = vendors.find((v) => v.id === data.vendorId);
    const is1099 = vendor?.is1099Eligible ?? false;

    const { data: result, error: err } = await supabase
      .from('vendor_payments')
      .insert({
        company_id: companyId,
        vendor_id: data.vendorId,
        payment_date: data.paymentDate,
        amount: data.amount,
        payment_method: data.paymentMethod,
        check_number: data.checkNumber || null,
        reference: data.reference || null,
        description: data.description || null,
        is_1099_reportable: is1099,
        created_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;

    // Auto-post journal entry: DR AP, CR Cash
    await createVendorPaymentJournal(result.id);
    await fetchPayments();
  };

  const filtered = search
    ? payments.filter((p) => {
        const q = search.toLowerCase();
        return p.vendorName.toLowerCase().includes(q) || (p.description?.toLowerCase().includes(q) ?? false);
      })
    : payments;

  const totalPaid = payments.reduce((s, p) => s + p.amount, 0);
  const total1099 = payments.filter((p) => p.is1099Reportable).reduce((s, p) => s + p.amount, 0);

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
            <h1 className="text-2xl font-semibold text-main">Vendor Payments</h1>
            <p className="text-muted mt-0.5">{payments.length} payments</p>
          </div>
        </div>
        <Button onClick={() => setModalOpen(true)}>
          <Plus size={16} />
          Record Payment
        </Button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">Total Paid</p>
          <p className="text-2xl font-semibold text-main mt-1 tabular-nums">{formatCurrency(totalPaid)}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">Payments Count</p>
          <p className="text-2xl font-semibold text-main mt-1">{payments.length}</p>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wide">1099 Reportable</p>
          <p className="text-2xl font-semibold text-amber-600 mt-1 tabular-nums">{formatCurrency(total1099)}</p>
        </CardContent></Card>
      </div>

      {/* Search */}
      <div className="relative max-w-sm">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <Input placeholder="Search payments..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-9" />
      </div>

      {/* Payment List */}
      <Card>
        <CardContent className="p-0">
          <div className="grid grid-cols-12 gap-2 px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-main">
            <div className="col-span-2">Date</div>
            <div className="col-span-3">Vendor</div>
            <div className="col-span-2">Method</div>
            <div className="col-span-2">Reference</div>
            <div className="col-span-2 text-right">Amount</div>
            <div className="col-span-1">1099</div>
          </div>
          <div className="divide-y divide-main">
            {filtered.length === 0 && (
              <div className="px-6 py-12 text-center text-sm text-muted">No payments found</div>
            )}
            {filtered.map((payment) => (
              <div key={payment.id} className="grid grid-cols-12 gap-2 px-6 py-3 items-center hover:bg-surface-hover transition-colors">
                <div className="col-span-2 text-sm text-muted tabular-nums">{payment.paymentDate}</div>
                <div className="col-span-3">
                  <p className="text-sm font-medium text-main">{payment.vendorName}</p>
                  {payment.description && <p className="text-xs text-muted truncate">{payment.description}</p>}
                </div>
                <div className="col-span-2">
                  <Badge variant="default" size="sm">{methodLabels[payment.paymentMethod] || payment.paymentMethod}</Badge>
                </div>
                <div className="col-span-2 text-sm text-muted">
                  {payment.checkNumber ? `#${payment.checkNumber}` : payment.reference || '—'}
                </div>
                <div className="col-span-2 text-right text-sm font-medium text-main tabular-nums">{formatCurrency(payment.amount)}</div>
                <div className="col-span-1">
                  {payment.is1099Reportable && <Badge variant="warning" size="sm">1099</Badge>}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Payment Modal */}
      {modalOpen && (
        <PaymentModal
          vendors={vendors}
          onSave={async (data) => {
            await createPayment(data);
            setModalOpen(false);
          }}
          onClose={() => setModalOpen(false)}
        />
      )}
    </div>
  );
}

function PaymentModal({ vendors, onSave, onClose }: {
  vendors: { id: string; vendorName: string; is1099Eligible: boolean }[];
  onSave: (data: { vendorId: string; paymentDate: string; amount: number; paymentMethod: string; checkNumber?: string; reference?: string; description?: string }) => Promise<void>;
  onClose: () => void;
}) {
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [vendorId, setVendorId] = useState('');
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);
  const [amount, setAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('check');
  const [checkNumber, setCheckNumber] = useState('');
  const [reference, setReference] = useState('');
  const [description, setDescription] = useState('');

  const selectedVendor = vendors.find((v) => v.id === vendorId);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      if (!vendorId) throw new Error('Select a vendor');
      if (!amount || Number(amount) <= 0) throw new Error('Amount must be positive');
      await onSave({
        vendorId,
        paymentDate,
        amount: Number(amount),
        paymentMethod,
        checkNumber: checkNumber || undefined,
        reference: reference || undefined,
        description: description || undefined,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Save failed');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-surface rounded-xl shadow-2xl w-full max-w-md border border-main" onClick={(e) => e.stopPropagation()}>
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">Record Payment</h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1">Vendor *</label>
            <select value={vendorId} onChange={(e) => setVendorId(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm" required>
              <option value="">Select vendor...</option>
              {vendors.filter((v) => v.vendorName).map((v) => <option key={v.id} value={v.id}>{v.vendorName}</option>)}
            </select>
            {selectedVendor?.is1099Eligible && (
              <p className="text-xs text-amber-600 mt-1">This vendor is 1099-eligible. Payment will be flagged as reportable.</p>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Date *</label>
              <Input type="date" value={paymentDate} onChange={(e) => setPaymentDate(e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Amount *</label>
              <Input type="number" step="0.01" min="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} required />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Payment Method</label>
            <select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm">
              <option value="check">Check</option>
              <option value="bank_transfer">Bank Transfer</option>
              <option value="credit_card">Credit Card</option>
              <option value="cash">Cash</option>
            </select>
          </div>
          {paymentMethod === 'check' && (
            <div>
              <label className="block text-sm font-medium text-main mb-1">Check Number</label>
              <Input value={checkNumber} onChange={(e) => setCheckNumber(e.target.value)} />
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-main mb-1">Reference / Memo</label>
            <Input value={reference} onChange={(e) => setReference(e.target.value)} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={2} className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none" />
          </div>
          {err && <p className="text-sm text-red-600">{err}</p>}
          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saving}>{saving ? 'Saving...' : 'Record Payment'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
