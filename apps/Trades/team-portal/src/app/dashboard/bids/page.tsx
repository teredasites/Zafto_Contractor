'use client';

import Link from 'next/link';
import { FileSignature, Plus, User } from 'lucide-react';
import { useBids } from '@/lib/hooks/use-bids';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatCurrency, formatDate } from '@/lib/utils';

export default function BidsPage() {
  const { bids, loading } = useBids();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-32 rounded-lg" />
        <div className="space-y-2">
          {[1, 2, 3].map((i) => (
            <div key={i} className="skeleton h-24 w-full rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-main">My Bids</h1>
          <p className="text-sm text-muted mt-1">
            {bids.length} bid{bids.length !== 1 ? 's' : ''} created
          </p>
        </div>
        <Link href="/dashboard/bids/new">
          <Button size="sm" className="flex-shrink-0">
            <Plus size={16} />
            New Bid
          </Button>
        </Link>
      </div>

      {/* Bids List */}
      {bids.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <FileSignature size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No bids yet</p>
            <p className="text-sm text-muted mt-1">
              Create your first bid to get started with estimates and proposals.
            </p>
            <Link href="/dashboard/bids/new" className="inline-block mt-4">
              <Button>
                <Plus size={16} />
                Create Bid
              </Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {bids.map((bid) => (
            <Card key={bid.id}>
              <CardContent className="py-3.5">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-xs font-mono text-muted">{bid.bidNumber}</span>
                      <StatusBadge status={bid.status} />
                    </div>
                    <p className="text-sm font-medium text-main mt-1">{bid.title}</p>
                    <span className="text-xs text-muted flex items-center gap-1 mt-0.5">
                      <User size={12} />
                      {bid.customerName}
                    </span>
                    <p className="text-xs text-muted mt-1">{formatDate(bid.createdAt)}</p>
                  </div>
                  <p className="text-sm font-semibold text-main whitespace-nowrap flex-shrink-0">
                    {formatCurrency(bid.totalAmount)}
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
