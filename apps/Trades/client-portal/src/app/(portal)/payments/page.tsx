'use client';
import { useState } from 'react';
import Link from 'next/link';
import { CreditCard, Clock, CheckCircle2, AlertCircle, ChevronRight, Receipt, History } from 'lucide-react';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';

type InvoiceStatus = 'due' | 'overdue' | 'paid' | 'partial';

const statusConfig: Record<InvoiceStatus, { label: string; color: string; bg: string }> = {
  due: { label: 'Due', color: 'text-amber-700', bg: 'bg-amber-50' },
  overdue: { label: 'Overdue', color: 'text-red-700', bg: 'bg-red-50' },
  paid: { label: 'Paid', color: 'text-green-700', bg: 'bg-green-50' },
  partial: { label: 'Partial', color: 'text-blue-700', bg: 'bg-blue-50' },
};

export default function PaymentsPage() {
  const [filter, setFilter] = useState<'all' | 'outstanding' | 'paid'>('all');
  const { invoices, loading, outstanding, totalOwed } = useInvoices();
  const filtered = filter === 'all' ? invoices : filter === 'outstanding' ? outstanding : invoices.filter(i => i.status === 'paid');

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
          <p className="text-gray-500 text-sm mt-0.5">{outstanding.length} outstanding invoices</p>
        </div>
        <div className="flex gap-2">
          <Link href="/payments/history" className="p-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"><History size={16} className="text-gray-500" /></Link>
          <Link href="/payments/methods" className="p-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"><CreditCard size={16} className="text-gray-500" /></Link>
        </div>
      </div>

      {/* Balance Card */}
      {outstanding.length > 0 && (
        <div className="rounded-xl p-5 text-white" style={{ background: 'linear-gradient(135deg, var(--accent), var(--accent-hover))' }}>
          <p className="text-white/70 text-xs">Total Outstanding</p>
          <p className="text-3xl font-black mt-1">{formatCurrency(totalOwed)}</p>
          <p className="text-white/70 text-xs mt-1">{outstanding.length} invoices</p>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-2">
        {(['all', 'outstanding', 'paid'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-full text-xs font-medium capitalize transition-all ${filter === f ? 'text-white' : 'bg-white text-gray-600 border border-gray-200'}`}
            style={filter === f ? { backgroundColor: 'var(--accent)' } : undefined}>
            {f}
          </button>
        ))}
      </div>

      {/* Loading Skeleton */}
      {loading && (
        <div className="space-y-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 animate-pulse">
              <div className="w-10 h-10 bg-gray-200 rounded-xl" />
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-gray-200 rounded w-32" />
                <div className="h-3 bg-gray-100 rounded w-48" />
              </div>
              <div className="h-4 bg-gray-200 rounded w-20" />
            </div>
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && invoices.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Receipt size={32} className="text-gray-300 mx-auto mb-3" />
          <h3 className="font-semibold text-sm text-gray-900">No invoices yet</h3>
          <p className="text-xs text-gray-500 mt-1">Invoices from your contractor will appear here.</p>
        </div>
      )}

      {/* No Results for Filter */}
      {!loading && invoices.length > 0 && filtered.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 text-center">
          <p className="text-sm text-gray-500">No {filter} invoices found.</p>
        </div>
      )}

      {/* Invoice List */}
      {!loading && (
        <div className="space-y-2">
          {filtered.map(inv => {
            const config = statusConfig[inv.status];
            const showPay = inv.status === 'due' || inv.status === 'overdue' || inv.status === 'partial';
            return (
              <Link key={inv.id} href={`/payments/${inv.id}`}
                className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
                <div className={`p-2.5 rounded-xl ${config.bg}`}>
                  {inv.status === 'paid' ? <CheckCircle2 size={18} className={config.color} /> : inv.status === 'overdue' ? <AlertCircle size={18} className={config.color} /> : <Receipt size={18} className={config.color} />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-sm text-gray-900">{inv.number}</h3>
                    <span className={`text-[10px] font-medium px-2 py-0.5 rounded-full ${config.bg} ${config.color}`}>{config.label}</span>
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5">{inv.project} · {inv.status === 'paid' ? `Paid ${formatDate(inv.paidDate)}` : `Due ${formatDate(inv.dueDate)}`}</p>
                </div>
                <div className="text-right flex items-center gap-2">
                  <span className="font-bold text-sm text-gray-900">{formatCurrency(inv.amount)}</span>
                  {showPay ? (
                    <span className="text-[10px] px-2.5 py-1 text-white rounded-lg font-bold" style={{ backgroundColor: 'var(--accent)' }}>PAY</span>
                  ) : (
                    <ChevronRight size={14} className="text-gray-300" />
                  )}
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
