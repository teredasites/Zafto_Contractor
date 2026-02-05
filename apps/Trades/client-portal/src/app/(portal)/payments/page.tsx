'use client';
import { useState } from 'react';
import Link from 'next/link';
import { CreditCard, Clock, CheckCircle2, AlertCircle, ChevronRight, Receipt, History } from 'lucide-react';

type InvoiceStatus = 'due' | 'overdue' | 'paid' | 'partial';
interface Invoice { id: string; number: string; project: string; amount: string; status: InvoiceStatus; dueDate: string; paidDate?: string; }

const statusConfig: Record<InvoiceStatus, { label: string; color: string; bg: string }> = {
  due: { label: 'Due', color: 'text-amber-700', bg: 'bg-amber-50' },
  overdue: { label: 'Overdue', color: 'text-red-700', bg: 'bg-red-50' },
  paid: { label: 'Paid', color: 'text-green-700', bg: 'bg-green-50' },
  partial: { label: 'Partial', color: 'text-blue-700', bg: 'bg-blue-50' },
};

const mockInvoices: Invoice[] = [
  { id: 'inv-1', number: '#1042', project: '200A Panel Upgrade', amount: '$2,400.00', status: 'due', dueDate: 'Feb 10, 2026' },
  { id: 'inv-2', number: '#1038', project: 'Bathroom Remodel', amount: '$6,200.00', status: 'overdue', dueDate: 'Jan 28, 2026' },
  { id: 'inv-3', number: '#1035', project: 'Water Heater Install', amount: '$2,100.00', status: 'paid', dueDate: 'Jan 15, 2026', paidDate: 'Jan 14, 2026' },
  { id: 'inv-4', number: '#1030', project: 'Roof Repair', amount: '$6,200.00', status: 'paid', dueDate: 'Dec 20, 2025', paidDate: 'Dec 18, 2025' },
  { id: 'inv-5', number: '#1025', project: 'HVAC Tune-Up', amount: '$189.00', status: 'paid', dueDate: 'Nov 15, 2025', paidDate: 'Nov 15, 2025' },
];

export default function PaymentsPage() {
  const [filter, setFilter] = useState<'all' | 'outstanding' | 'paid'>('all');
  const outstanding = mockInvoices.filter(i => i.status === 'due' || i.status === 'overdue' || i.status === 'partial');
  const filtered = filter === 'all' ? mockInvoices : filter === 'outstanding' ? outstanding : mockInvoices.filter(i => i.status === 'paid');
  const totalOwed = '$8,600.00';

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
        <div className="bg-gradient-to-r from-orange-500 to-orange-600 rounded-xl p-5 text-white">
          <p className="text-orange-200 text-xs">Total Outstanding</p>
          <p className="text-3xl font-black mt-1">{totalOwed}</p>
          <p className="text-orange-200 text-xs mt-1">{outstanding.length} invoices</p>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-2">
        {(['all', 'outstanding', 'paid'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-full text-xs font-medium capitalize transition-all ${filter === f ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
            {f}
          </button>
        ))}
      </div>

      {/* Invoice List */}
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
                <p className="text-xs text-gray-500 mt-0.5">{inv.project} · {inv.status === 'paid' ? `Paid ${inv.paidDate}` : `Due ${inv.dueDate}`}</p>
              </div>
              <div className="text-right flex items-center gap-2">
                <span className="font-bold text-sm text-gray-900">{inv.amount}</span>
                {showPay ? (
                  <span className="text-[10px] px-2.5 py-1 bg-orange-500 text-white rounded-lg font-bold">PAY</span>
                ) : (
                  <ChevronRight size={14} className="text-gray-300" />
                )}
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
