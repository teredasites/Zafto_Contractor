'use client';
import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ArrowLeft, CreditCard, Building2, Plus, Trash2, Star, Shield, Loader2 } from 'lucide-react';
import { getSupabase } from '@/lib/supabase';

interface PaymentMethod { id: string; type: 'card' | 'bank'; brand?: string; last4: string; label: string; expiry?: string; isDefault: boolean; }

export default function PaymentMethodsPage() {
  const [methods, setMethods] = useState<PaymentMethod[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchMethods = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const customerId = user.user_metadata?.customer_id;
      if (!customerId) return;

      // Fetch payment methods used in past payments
      const { data: payments } = await supabase
        .from('invoices')
        .select('payment_method, payment_reference')
        .eq('customer_id', customerId)
        .eq('status', 'paid')
        .not('payment_method', 'is', null)
        .order('paid_at', { ascending: false });

      // Deduplicate by payment method
      const seen = new Set<string>();
      const unique: PaymentMethod[] = [];
      (payments || []).forEach((p: Record<string, unknown>, i: number) => {
        const method = p.payment_method as string;
        if (!method || seen.has(method)) return;
        seen.add(method);
        const isCard = method.includes('card') || method.includes('visa') || method.includes('mastercard') || method.includes('amex') || method === 'stripe';
        const isBank = method.includes('ach') || method.includes('bank');
        unique.push({
          id: `pm-${i}`,
          type: isBank ? 'bank' : 'card',
          brand: isCard ? 'Card' : isBank ? 'Bank' : method,
          last4: (p.payment_reference as string)?.slice(-4) || '****',
          label: method.charAt(0).toUpperCase() + method.slice(1).replace(/_/g, ' '),
          isDefault: i === 0,
        });
      });

      setMethods(unique);
    } catch {
      // Graceful degradation
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchMethods(); }, [fetchMethods]);

  return (
    <div className="space-y-5">
      <div>
        <Link href="/payments" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Payments
        </Link>
        <h1 className="text-xl font-bold text-gray-900">Payment Methods</h1>
        <p className="text-sm text-gray-500 mt-0.5">
          {loading ? 'Loading...' : `${methods.length} saved method${methods.length !== 1 ? 's' : ''}`}
        </p>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <Loader2 size={24} className="animate-spin text-gray-300" />
        </div>
      ) : methods.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 p-8 text-center">
          <CreditCard size={32} className="text-gray-200 mx-auto mb-3" />
          <p className="text-sm font-medium text-gray-900">No payment methods on file</p>
          <p className="text-xs text-gray-500 mt-1">Payment methods are saved automatically when you make a payment</p>
        </div>
      ) : (
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
                  {m.last4 && <p className="text-xs text-gray-400 mt-0.5">Ending in {m.last4}</p>}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Info about Stripe-managed payment methods */}
      <div className="flex items-start gap-2 p-3 bg-gray-50 rounded-xl">
        <Shield size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
        <p className="text-[11px] text-gray-500">
          Payment methods are securely managed by Stripe. When you pay an invoice, you can use a new card or bank account directly in the checkout flow.
        </p>
      </div>
    </div>
  );
}
