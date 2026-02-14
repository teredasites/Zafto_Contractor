'use client';
import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, CheckCircle2, Download, CreditCard, Building2, Loader2 } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface Payment {
  id: string;
  date: string;
  amount: number;
  method: string;
  invoiceNumber: string;
  project: string;
  type: 'card' | 'bank' | 'other';
}

function formatCurrency(cents: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(cents / 100);
}

export default function PaymentHistoryPage() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPayments = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const customerId = user.user_metadata?.customer_id;
      if (!customerId) return;

      // Fetch from payments table (immutable audit trail of successful payments)
      const { data } = await supabase
        .from('payments')
        .select('id, amount, currency, payment_type, reference_id, created_at')
        .eq('customer_id', customerId)
        .eq('status', 'succeeded')
        .order('created_at', { ascending: false });

      if (!data || data.length === 0) {
        // Fallback: fetch from invoices that are marked paid
        const { data: invoices } = await supabase
          .from('invoices')
          .select('id, total, invoice_number, customer_name, payment_method, paid_at, job_id, jobs(title)')
          .eq('customer_id', customerId)
          .eq('status', 'paid')
          .order('paid_at', { ascending: false });

        const mapped: Payment[] = (invoices || []).map((inv: Record<string, unknown>) => ({
          id: inv.id as string,
          date: inv.paid_at as string || inv.created_at as string || '',
          amount: Number(inv.total || 0) * 100,
          method: (inv.payment_method as string) || 'card',
          invoiceNumber: (inv.invoice_number as string) || '',
          project: ((inv.jobs as Record<string, unknown>)?.title as string) || 'Payment',
          type: ((inv.payment_method as string) || '').includes('ach') || ((inv.payment_method as string) || '').includes('bank') ? 'bank' : 'card',
        }));
        setPayments(mapped);
      } else {
        // Fetch related invoice details for each payment
        const referenceIds = data.map((p: Record<string, unknown>) => p.reference_id).filter(Boolean);
        const { data: invoices } = await supabase
          .from('invoices')
          .select('id, invoice_number, payment_method, job_id, jobs(title)')
          .in('id', referenceIds);

        const invoiceMap = new Map((invoices || []).map((inv: Record<string, unknown>) => [inv.id, inv]));

        const mapped: Payment[] = data.map((p: Record<string, unknown>) => {
          const inv = invoiceMap.get(p.reference_id as string) as Record<string, unknown> | undefined;
          const method = (inv?.payment_method as string) || 'stripe';
          return {
            id: p.id as string,
            date: p.created_at as string,
            amount: Number(p.amount || 0),
            method,
            invoiceNumber: (inv?.invoice_number as string) || '',
            project: ((inv?.jobs as Record<string, unknown>)?.title as string) || 'Payment',
            type: method.includes('ach') || method.includes('bank') ? 'bank' : method.includes('check') || method.includes('cash') ? 'other' : 'card',
          };
        });
        setPayments(mapped);
      }
    } catch {
      // Graceful degradation — show empty state
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchPayments(); }, [fetchPayments]);

  const totalPaid = payments.reduce((sum, p) => sum + p.amount, 0);

  if (loading) {
    return (
      <div className="space-y-5">
        <div>
          <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
            <ArrowLeft size={16} /> Back to Payments
          </Link>
          <h1 className="text-xl font-bold text-gray-900">Payment History</h1>
        </div>
        <div className="flex justify-center py-12">
          <Loader2 size={24} className="animate-spin text-gray-300" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <div className="flex items-start justify-between">
          <h1 className="text-xl font-bold text-gray-900">Payment History</h1>
          <button className="flex items-center gap-1.5 text-xs text-orange-500 font-medium hover:text-orange-600">
            <Download size={14} /> Download Statement
          </button>
        </div>
        <p className="text-sm text-gray-500 mt-0.5">{payments.length} payments · Total: {formatCurrency(totalPaid)}</p>
      </div>

      {payments.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 p-8 text-center">
          <CheckCircle2 size={32} className="text-gray-200 mx-auto mb-3" />
          <p className="text-sm text-gray-500">No payment history yet</p>
        </div>
      ) : (
        <div className="space-y-2">
          {payments.map(p => (
            <div key={p.id} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 p-4">
              <div className="p-2 bg-green-50 rounded-lg">
                <CheckCircle2 size={16} className="text-green-600" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900">{p.project}</p>
                <p className="text-xs text-gray-500 mt-0.5 flex items-center gap-1.5">
                  {p.type === 'card' ? <CreditCard size={10} /> : <Building2 size={10} />}
                  {p.method} {p.invoiceNumber && `· Invoice ${p.invoiceNumber}`}
                </p>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold text-gray-900">{formatCurrency(p.amount)}</p>
                <p className="text-[10px] text-gray-400">{new Date(p.date).toLocaleDateString()}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
