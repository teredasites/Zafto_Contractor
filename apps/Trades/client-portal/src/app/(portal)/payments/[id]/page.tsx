'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Check, CreditCard, Download, Shield, AlertCircle } from 'lucide-react';

const invoice = {
  id: 'inv-1', number: '#1042', project: '200A Panel Upgrade', contractor: "Mike's Electric",
  status: 'due' as const, dueDate: 'Feb 10, 2026', created: 'Jan 30, 2026',
  lineItems: [
    { description: '200A Eaton Main Breaker Panel', qty: 1, rate: '$890.00', total: '$890.00' },
    { description: '200A Meter Base', qty: 1, rate: '$340.00', total: '$340.00' },
    { description: 'Circuit Breakers (20A)', qty: 12, rate: '$18.00', total: '$216.00' },
    { description: 'Circuit Breakers (30A)', qty: 4, rate: '$24.00', total: '$96.00' },
    { description: 'Copper Wire (various gauges)', qty: 1, rate: '$285.00', total: '$285.00' },
    { description: 'Labor — Electrician (8 hrs)', qty: 8, rate: '$85.00', total: '$680.00' },
    { description: 'Labor — Apprentice (8 hrs)', qty: 8, rate: '$45.00', total: '$360.00' },
    { description: 'Permit & Inspection Fee', qty: 1, rate: '$175.00', total: '$175.00' },
  ],
  subtotal: '$3,042.00', tax: '$158.00', discount: '-$800.00 (deposit applied)', total: '$2,400.00',
  savedCards: [
    { id: 'card-1', brand: 'Visa', last4: '4242', expiry: '08/27', isDefault: true },
    { id: 'card-2', brand: 'Mastercard', last4: '8888', expiry: '12/26', isDefault: false },
  ],
};

export default function InvoiceDetailPage() {
  const [paid, setPaid] = useState(false);
  const [selectedCard, setSelectedCard] = useState('card-1');

  return (
    <div className="space-y-5">
      <div>
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">Invoice {invoice.number}</h1>
            <p className="text-sm text-gray-500 mt-0.5">{invoice.contractor} · {invoice.project}</p>
          </div>
          {paid ? (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-green-50 text-green-700"><Check size={12} /> Paid</span>
          ) : (
            <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-amber-50 text-amber-700"><AlertCircle size={12} /> Due {invoice.dueDate}</span>
          )}
        </div>
      </div>

      {paid && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
          <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-3"><Check size={24} className="text-green-600" /></div>
          <h2 className="text-lg font-bold text-green-800">Payment Successful!</h2>
          <p className="text-sm text-green-600 mt-1">{invoice.total} paid · {new Date().toLocaleDateString()}</p>
          <button className="mt-3 text-xs text-green-700 font-medium flex items-center gap-1.5 mx-auto hover:text-green-800"><Download size={14} /> Download Receipt</button>
        </div>
      )}

      {/* Line Items */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-4 border-b border-gray-100"><h3 className="font-semibold text-sm text-gray-900">Line Items</h3></div>
        <div className="divide-y divide-gray-50">
          {invoice.lineItems.map((item, i) => (
            <div key={i} className="px-4 py-3 flex justify-between">
              <div><p className="text-sm text-gray-900">{item.description}</p><p className="text-xs text-gray-400">Qty {item.qty} × {item.rate}</p></div>
              <span className="text-sm font-medium text-gray-900 whitespace-nowrap">{item.total}</span>
            </div>
          ))}
        </div>
        <div className="border-t border-gray-200 p-4 space-y-1.5">
          <div className="flex justify-between text-sm"><span className="text-gray-500">Subtotal</span><span>{invoice.subtotal}</span></div>
          <div className="flex justify-between text-sm"><span className="text-gray-500">Tax</span><span>{invoice.tax}</span></div>
          <div className="flex justify-between text-sm"><span className="text-gray-500">Deposit</span><span className="text-green-600">{invoice.discount}</span></div>
          <div className="flex justify-between font-bold text-sm border-t border-gray-100 pt-2 mt-2"><span>Amount Due</span><span className="text-lg">{invoice.total}</span></div>
        </div>
      </div>

      {/* Pay Now */}
      {!paid && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-4">
          <h3 className="font-bold text-sm text-gray-900">Select Payment Method</h3>
          <div className="space-y-2">
            {invoice.savedCards.map(card => (
              <label key={card.id} onClick={() => setSelectedCard(card.id)}
                className={`flex items-center gap-3 p-3 rounded-xl border-2 cursor-pointer transition-all ${selectedCard === card.id ? 'border-orange-500 bg-orange-50' : 'border-gray-100 hover:border-gray-200'}`}>
                <CreditCard size={18} className={selectedCard === card.id ? 'text-orange-600' : 'text-gray-400'} />
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">{card.brand} ••{card.last4}</p>
                  <p className="text-[10px] text-gray-400">Expires {card.expiry}{card.isDefault ? ' · Default' : ''}</p>
                </div>
                <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${selectedCard === card.id ? 'border-orange-500 bg-orange-500' : 'border-gray-300'}`}>
                  {selectedCard === card.id && <div className="w-1.5 h-1.5 bg-white rounded-full" />}
                </div>
              </label>
            ))}
          </div>
          <button onClick={() => setPaid(true)}
            className="w-full py-3.5 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl transition-all text-sm">
            Pay {invoice.total} Now
          </button>
          <p className="text-center text-[10px] text-gray-400 flex items-center justify-center gap-1">
            <Shield size={10} /> Payments secured by Stripe
          </p>
        </div>
      )}
    </div>
  );
}
