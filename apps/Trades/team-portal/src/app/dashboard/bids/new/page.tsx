'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useDraftRecovery } from '@/lib/hooks/use-draft-recovery';
import Link from 'next/link';
import { ArrowLeft, FileSignature, Save } from 'lucide-react';
import { useBids } from '@/lib/hooks/use-bids';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';

export default function NewBidPage() {
  const router = useRouter();
  const { createBid } = useBids();

  const [customerName, setCustomerName] = useState('');
  const [title, setTitle] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Draft recovery — auto-save bid form
  const draftRecovery = useDraftRecovery({
    feature: 'bid',
    key: 'new-team-bid',
    screenRoute: '/dashboard/bids/new',
  });

  useEffect(() => {
    if (draftRecovery.hasDraft && !draftRecovery.checking) {
      const restored = draftRecovery.restoreDraft() as Record<string, string> | null;
      if (restored) {
        if (restored.customerName) setCustomerName(restored.customerName);
        if (restored.title) setTitle(restored.title);
        if (restored.totalAmount) setTotalAmount(restored.totalAmount);
        if (restored.description) setDescription(restored.description);
      }
      draftRecovery.markRecovered();
    }
  }, [draftRecovery.hasDraft, draftRecovery.checking]);

  useEffect(() => {
    draftRecovery.saveDraft({ customerName, title, totalAmount, description });
  }, [customerName, title, totalAmount, description]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerName || !title || !totalAmount) return;
    setSubmitting(true);
    await createBid({
      customerName,
      title,
      totalAmount: parseFloat(totalAmount) || 0,
      description,
    });
    router.push('/dashboard/bids');
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <Link
          href="/dashboard/bids"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>My Bids</span>
        </Link>
        <h1 className="text-xl font-bold text-main">Create Bid</h1>
        <p className="text-sm text-muted mt-1">
          Create a new bid or estimate for a potential customer
        </p>
      </div>

      {/* Form */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileSignature size={18} className="text-accent" />
            Bid Details
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Customer Name"
              placeholder="John Smith"
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              required
            />

            <Input
              label="Title"
              placeholder="Panel upgrade, rewire, service call..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />

            <Input
              label="Total Amount ($)"
              type="number"
              min="0"
              step="0.01"
              placeholder="0.00"
              value={totalAmount}
              onChange={(e) => setTotalAmount(e.target.value)}
              required
            />

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-main">Description</label>
              <textarea
                rows={4}
                placeholder="Scope of work, materials included, terms..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className={cn(
                  'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                  'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                  'text-[15px] resize-none'
                )}
              />
            </div>

            <div className="flex gap-3 pt-2">
              <Button
                type="submit"
                loading={submitting}
                disabled={!customerName || !title || !totalAmount}
                className="min-h-[44px]"
              >
                <Save size={16} />
                Create Bid
              </Button>
              <Link href="/dashboard/bids">
                <Button type="button" variant="secondary" className="min-h-[44px]">
                  Cancel
                </Button>
              </Link>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
