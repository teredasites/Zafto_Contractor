'use client';
import { useState } from 'react';
import { useParams, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, Check, CreditCard, Download, Shield, AlertCircle, Loader2 } from 'lucide-react';
import { useInvoice } from '@/lib/hooks/use-invoices';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';
import { getSupabase } from '@/lib/supabase';

export default function InvoiceDetailPage() {
  const { id } = useParams<{ id: string }>();
  const searchParams = useSearchParams();
  const paymentStatus = searchParams.get('status');
  const { invoice, loading } = useInvoice(id);
  const [paid, setPaid] = useState(paymentStatus === 'success');
  const [paying, setPaying] = useState(false);
  const [payError, setPayError] = useState<string | null>(null);

  // Loading skeleton
  if (loading) {
    return (
      <div className="space-y-5 animate-pulse">
        <div>
          <div className="h-4 bg-gray-200 rounded w-32 mb-3" />
          <div className="flex items-start justify-between">
            <div className="space-y-2">
              <div className="h-6 bg-gray-200 rounded w-48" />
              <div className="h-4 bg-gray-100 rounded w-64" />
            </div>
            <div className="h-6 bg-gray-200 rounded-full w-20" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
          <div className="p-4 border-b border-gray-100">
            <div className="h-4 bg-gray-200 rounded w-24" />
          </div>
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="px-4 py-3 flex justify-between">
              <div className="space-y-1">
                <div className="h-4 bg-gray-200 rounded w-48" />
                <div className="h-3 bg-gray-100 rounded w-24" />
              </div>
              <div className="h-4 bg-gray-200 rounded w-16" />
            </div>
          ))}
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-3">
          <div className="h-4 bg-gray-200 rounded w-40" />
          <div className="h-14 bg-gray-100 rounded-xl" />
          <div className="h-14 bg-gray-100 rounded-xl" />
          <div className="h-12 bg-gray-200 rounded-xl" />
        </div>
      </div>
    );
  }

  // Invoice not found
  if (!invoice) {
    return (
      <div className="space-y-5">
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <AlertCircle size={32} className="text-gray-300 mx-auto mb-3" />
          <h3 className="font-semibold text-sm text-gray-900">Invoice not found</h3>
          <p className="text-xs text-gray-500 mt-1">This invoice may have been removed or the link is incorrect.</p>
        </div>
      </div>
    );
  }

  const subtotal = invoice.lineItems.reduce((sum, item) => sum + item.total, 0);
  const showPaySection = invoice.status === 'due' || invoice.status === 'overdue' || invoice.status === 'partial';

  return (
    <div className="space-y-5">
      <div>
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">Invoice {invoice.number}</h1>
            <p className="text-sm text-gray-500 mt-0.5">{invoice.project}</p>
          </div>
          {paid ? (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-green-50 text-green-700"><Check size={12} /> Paid</span>
          ) : (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-amber-50 text-amber-700"><AlertCircle size={12} /> Due {formatDate(invoice.dueDate)}</span>
          )}
        </div>
      </div>

      {paid && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
          <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3"><Check size={24} className="text-green-600" /></div>
          <h2 className="text-lg font-bold text-green-800">Payment Successful!</h2>
          <p className="text-sm text-green-600 mt-1">{formatCurrency(invoice.amount)} paid · {new Date().toLocaleDateString()}</p>
          <button className="mt-3 text-xs text-green-700 font-medium flex items-center gap-1.5 mx-auto hover:text-green-800"><Download size={14} /> Download Receipt</button>
        </div>
      )}

      {/* Line Items */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-100"><h3 className="font-semibold text-sm text-gray-900">Line Items</h3></div>
        {invoice.lineItems.length > 0 ? (
          <div className="divide-y divide-gray-50">
            {invoice.lineItems.map((item, i) => (
              <div key={i} className="px-4 py-3 flex justify-between">
                <div><p className="text-sm text-gray-900">{item.description}</p><p className="text-xs text-gray-400">Qty {item.quantity} x {formatCurrency(item.unitPrice)}</p></div>
                <span className="text-sm font-medium text-gray-900 whitespace-nowrap">{formatCurrency(item.total)}</span>
              </div>
            ))}
          </div>
        ) : (
          <div className="px-4 py-6 text-center text-sm text-gray-400">No line items</div>
        )}
        <div className="border-t border-gray-200 p-4 space-y-1.5">
          {invoice.lineItems.length > 0 && subtotal !== invoice.amount && (
            <div className="flex justify-between text-sm"><span className="text-gray-500">Subtotal</span><span>{formatCurrency(subtotal)}</span></div>
          )}
          <div className="flex justify-between font-bold text-sm border-t border-gray-100 pt-2 mt-2"><span>Amount Due</span><span className="text-lg">{formatCurrency(invoice.amount)}</span></div>
        </div>
      </div>

      {/* Pay Now — Stripe Checkout */}
      {!paid && showPaySection && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-4">
          <h3 className="font-bold text-sm text-gray-900">Pay Invoice</h3>
          <div className="p-3 bg-gray-50 rounded-xl">
            <div className="flex items-center gap-3">
              <CreditCard size={18} className="text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Credit Card, Debit Card, or Bank Transfer</p>
                <p className="text-[10px] text-gray-400">You&apos;ll be redirected to Stripe&apos;s secure checkout</p>
              </div>
            </div>
          </div>
          {payError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-xl">
              <p className="text-xs text-red-600">{payError}</p>
            </div>
          )}
          <button
            onClick={async () => {
              setPaying(true);
              setPayError(null);
              try {
                const supabase = getSupabase();
                const { data: { user } } = await supabase.auth.getUser();
                const { data, error } = await supabase.functions.invoke('stripe-payments', {
                  body: {
                    action: 'create_checkout_session',
                    invoiceId: invoice.id,
                    amount: Math.round(invoice.amount * 100),
                    customerEmail: user?.email,
                    successUrl: `${window.location.origin}/payments/${invoice.id}?status=success`,
                    cancelUrl: `${window.location.origin}/payments/${invoice.id}?status=cancelled`,
                  },
                });
                if (error) throw new Error(error.message || 'Payment failed');
                if (data?.checkoutUrl) {
                  window.location.href = data.checkoutUrl;
                }
              } catch (err) {
                setPayError(err instanceof Error ? err.message : 'Payment could not be initiated. Please try again.');
              } finally {
                setPaying(false);
              }
            }}
            disabled={paying}
            className="w-full py-3.5 text-white font-bold rounded-xl transition-all text-sm flex items-center justify-center gap-2"
            style={{ backgroundColor: paying ? '#9ca3af' : 'var(--accent)' }}
            onMouseEnter={e => { if (!paying) e.currentTarget.style.backgroundColor = 'var(--accent-hover)'; }}
            onMouseLeave={e => { if (!paying) e.currentTarget.style.backgroundColor = 'var(--accent)'; }}
          >
            {paying ? <><Loader2 size={16} className="animate-spin" /> Processing...</> : <>Pay {formatCurrency(invoice.amount)} Now</>}
          </button>
          <p className="text-center text-[10px] text-gray-400 flex items-center justify-center gap-1">
            <Shield size={10} /> Payments secured by Stripe
          </p>
        </div>
      )}
    </div>
  );
}
