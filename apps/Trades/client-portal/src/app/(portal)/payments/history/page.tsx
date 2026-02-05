'use client';
import Link from 'next/link';
import { ArrowLeft, CheckCircle2, Download, CreditCard, Building2 } from 'lucide-react';

const payments = [
  { id: 'p1', date: 'Jan 25, 2026', amount: '$1,500.00', method: 'Visa ••4242', invoice: '#1042', project: '200A Panel Upgrade', type: 'card' },
  { id: 'p2', date: 'Jan 14, 2026', amount: '$2,100.00', method: 'Chase ••9876', invoice: '#1035', project: 'Water Heater Install', type: 'bank' },
  { id: 'p3', date: 'Dec 18, 2025', amount: '$6,200.00', method: 'Visa ••4242', invoice: '#1030', project: 'Roof Repair', type: 'card' },
  { id: 'p4', date: 'Nov 15, 2025', amount: '$189.00', method: 'Visa ••4242', invoice: '#1025', project: 'HVAC Tune-Up', type: 'card' },
  { id: 'p5', date: 'Oct 5, 2025', amount: '$3,400.00', method: 'Chase ••9876', invoice: '#1018', project: 'Electrical Inspection', type: 'bank' },
  { id: 'p6', date: 'Sep 12, 2025', amount: '$950.00', method: 'Visa ••4242', invoice: '#1012', project: 'Outlet Installation', type: 'card' },
];

export default function PaymentHistoryPage() {
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
        <p className="text-sm text-gray-500 mt-0.5">{payments.length} payments · Total: $14,339.00</p>
      </div>

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
                {p.method} · Invoice {p.invoice}
              </p>
            </div>
            <div className="text-right">
              <p className="text-sm font-bold text-gray-900">{p.amount}</p>
              <p className="text-[10px] text-gray-400">{p.date}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
