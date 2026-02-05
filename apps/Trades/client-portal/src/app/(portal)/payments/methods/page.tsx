'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, CreditCard, Building2, Plus, Check, Trash2, Star } from 'lucide-react';

interface PaymentMethod { id: string; type: 'card' | 'bank'; brand?: string; last4: string; label: string; expiry?: string; isDefault: boolean; }

const mockMethods: PaymentMethod[] = [
  { id: 'pm-1', type: 'card', brand: 'Visa', last4: '4242', label: 'Visa ending in 4242', expiry: '08/28', isDefault: true },
  { id: 'pm-2', type: 'bank', last4: '9876', label: 'Chase checking ••9876', isDefault: false },
];

export default function PaymentMethodsPage() {
  const [methods] = useState(mockMethods);
  const [showAdd, setShowAdd] = useState(false);

  return (
    <div className="space-y-5">
      <div>
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <h1 className="text-xl font-bold text-gray-900">Payment Methods</h1>
        <p className="text-sm text-gray-500 mt-0.5">{methods.length} saved methods</p>
      </div>

      <div className="space-y-3">
        {methods.map(m => (
          <div key={m.id} className={`bg-white rounded-xl border-2 p-4 ${m.isDefault ? 'border-orange-200' : 'border-gray-100'}`}>
            <div className="flex items-center gap-3">
              <div className={`p-2.5 rounded-xl ${m.isDefault ? 'bg-orange-50' : 'bg-gray-50'}`}>
                {m.type === 'card' ? <CreditCard size={18} className={m.isDefault ? 'text-orange-600' : 'text-gray-500'} /> : <Building2 size={18} className={m.isDefault ? 'text-orange-600' : 'text-gray-500'} />}
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-medium text-gray-900">{m.label}</p>
                  {m.isDefault && <span className="text-[10px] px-1.5 py-0.5 bg-orange-100 text-orange-600 rounded font-medium flex items-center gap-0.5"><Star size={8} /> Default</span>}
                </div>
                {m.expiry && <p className="text-xs text-gray-400 mt-0.5">Expires {m.expiry}</p>}
              </div>
              <div className="flex items-center gap-2">
                {!m.isDefault && <button className="text-xs text-gray-400 hover:text-orange-500 font-medium">Set Default</button>}
                <button className="p-1.5 text-gray-300 hover:text-red-500 transition-colors"><Trash2 size={14} /></button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {showAdd ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-4">
          <h3 className="font-bold text-sm text-gray-900">Add Payment Method</h3>
          <div className="space-y-3">
            <div><label className="block text-xs font-medium text-gray-700 mb-1">Card Number</label><input placeholder="1234 5678 9012 3456" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" /></div>
            <div className="grid grid-cols-2 gap-3">
              <div><label className="block text-xs font-medium text-gray-700 mb-1">Expiry</label><input placeholder="MM/YY" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" /></div>
              <div><label className="block text-xs font-medium text-gray-700 mb-1">CVC</label><input placeholder="123" className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" /></div>
            </div>
          </div>
          <div className="flex gap-3">
            <button onClick={() => setShowAdd(false)} className="flex-1 py-2.5 border border-gray-200 text-gray-600 font-medium rounded-xl text-sm hover:bg-gray-50">Cancel</button>
            <button onClick={() => setShowAdd(false)} className="flex-1 py-2.5 bg-orange-500 text-white font-bold rounded-xl text-sm hover:bg-orange-600">Save Card</button>
          </div>
        </div>
      ) : (
        <button onClick={() => setShowAdd(true)} className="w-full py-3 border-2 border-dashed border-gray-200 rounded-xl text-sm font-medium text-gray-500 hover:border-orange-300 hover:text-orange-500 flex items-center justify-center gap-2 transition-all">
          <Plus size={16} /> Add Payment Method
        </button>
      )}
    </div>
  );
}
