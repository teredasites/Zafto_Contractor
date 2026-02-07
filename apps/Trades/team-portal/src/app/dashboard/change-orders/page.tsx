'use client';

import { useState } from 'react';
import { FileText, Plus, X, Trash2, Send } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { StatusBadge } from '@/components/ui/badge';
import { cn, formatCurrency, formatDate } from '@/lib/utils';
import type { ChangeOrderItem } from '@/lib/hooks/mappers';

export default function ChangeOrdersPage() {
  const { jobs, loading: jobsLoading } = useMyJobs();
  const [filterJobId, setFilterJobId] = useState<string | undefined>(undefined);
  const { orders, loading: ordersLoading, createOrder, submitForApproval } = useChangeOrders(filterJobId);

  const [showForm, setShowForm] = useState(false);
  const [formJobId, setFormJobId] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [reason, setReason] = useState('');
  const [lineItems, setLineItems] = useState<ChangeOrderItem[]>([
    { description: '', quantity: 1, unitPrice: 0 },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [submittingApproval, setSubmittingApproval] = useState<string | null>(null);

  const resetForm = () => {
    setFormJobId('');
    setTitle('');
    setDescription('');
    setReason('');
    setLineItems([{ description: '', quantity: 1, unitPrice: 0 }]);
  };

  const addLineItem = () => {
    setLineItems([...lineItems, { description: '', quantity: 1, unitPrice: 0 }]);
  };

  const removeLineItem = (index: number) => {
    if (lineItems.length <= 1) return;
    setLineItems(lineItems.filter((_, i) => i !== index));
  };

  const updateLineItem = (index: number, field: keyof ChangeOrderItem, value: string | number) => {
    const updated = [...lineItems];
    if (field === 'description') {
      updated[index] = { ...updated[index], description: value as string };
    } else if (field === 'quantity') {
      updated[index] = { ...updated[index], quantity: parseFloat(value as string) || 0 };
    } else {
      updated[index] = { ...updated[index], unitPrice: parseFloat(value as string) || 0 };
    }
    setLineItems(updated);
  };

  const lineItemsTotal = lineItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formJobId || !title) return;
    setSubmitting(true);
    await createOrder({
      jobId: formJobId,
      title,
      description,
      reason,
      items: lineItems.filter((i) => i.description.trim()),
    });
    resetForm();
    setShowForm(false);
    setSubmitting(false);
  };

  const handleSubmitForApproval = async (orderId: string) => {
    setSubmittingApproval(orderId);
    await submitForApproval(orderId);
    setSubmittingApproval(null);
  };

  const loading = jobsLoading || ordersLoading;

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-40 rounded-lg" />
        <div className="skeleton h-12 w-full rounded-lg" />
        <div className="skeleton h-48 w-full rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-main">Change Orders</h1>
          <p className="text-sm text-muted mt-1">
            Create and manage change orders for scope modifications
          </p>
        </div>
        <Button
          size="sm"
          onClick={() => setShowForm(!showForm)}
          className="flex-shrink-0"
        >
          {showForm ? <X size={16} /> : <Plus size={16} />}
          {showForm ? 'Cancel' : 'Create'}
        </Button>
      </div>

      {/* Job Filter */}
      <div className="space-y-1.5">
        <label className="text-sm font-medium text-main">Filter by Job</label>
        <select
          value={filterJobId || ''}
          onChange={(e) => setFilterJobId(e.target.value || undefined)}
          className={cn(
            'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
            'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]'
          )}
        >
          <option value="">All Jobs</option>
          {jobs.map((job) => (
            <option key={job.id} value={job.id}>
              {job.title} - {job.customerName}
            </option>
          ))}
        </select>
      </div>

      {/* Create Change Order Form */}
      {showForm && (
        <Card>
          <CardHeader>
            <CardTitle>Create Change Order</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main">Job</label>
                <select
                  value={formJobId}
                  onChange={(e) => setFormJobId(e.target.value)}
                  required
                  className={cn(
                    'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                    'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                    'text-[15px]'
                  )}
                >
                  <option value="">Select a job...</option>
                  {jobs.map((job) => (
                    <option key={job.id} value={job.id}>
                      {job.title} - {job.customerName}
                    </option>
                  ))}
                </select>
              </div>

              <Input
                label="Title"
                placeholder="Additional wiring for garage..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main">Description</label>
                <textarea
                  rows={2}
                  placeholder="Describe the scope change in detail..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className={cn(
                    'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                    'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                    'text-[15px] resize-none'
                  )}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main">Reason</label>
                <textarea
                  rows={2}
                  placeholder="Why is this change needed..."
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  className={cn(
                    'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                    'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                    'text-[15px] resize-none'
                  )}
                />
              </div>

              {/* Line Items */}
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-medium text-main">Line Items</label>
                  <button
                    type="button"
                    onClick={addLineItem}
                    className="text-xs text-accent hover:text-accent-hover transition-colors font-medium"
                  >
                    + Add Line
                  </button>
                </div>

                {lineItems.map((item, index) => (
                  <div key={index} className="flex items-start gap-2">
                    <div className="flex-1 grid grid-cols-1 sm:grid-cols-3 gap-2">
                      <input
                        placeholder="Description"
                        value={item.description}
                        onChange={(e) => updateLineItem(index, 'description', e.target.value)}
                        className={cn(
                          'w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main',
                          'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                          'text-sm sm:col-span-1'
                        )}
                      />
                      <input
                        type="number"
                        placeholder="Qty"
                        min="0"
                        step="0.01"
                        value={item.quantity || ''}
                        onChange={(e) => updateLineItem(index, 'quantity', e.target.value)}
                        className={cn(
                          'w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main',
                          'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                          'text-sm'
                        )}
                      />
                      <input
                        type="number"
                        placeholder="Unit Price"
                        min="0"
                        step="0.01"
                        value={item.unitPrice || ''}
                        onChange={(e) => updateLineItem(index, 'unitPrice', e.target.value)}
                        className={cn(
                          'w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main',
                          'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                          'text-sm'
                        )}
                      />
                    </div>
                    {lineItems.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeLineItem(index)}
                        className="p-2 text-muted hover:text-red-500 transition-colors flex-shrink-0"
                      >
                        <Trash2 size={16} />
                      </button>
                    )}
                  </div>
                ))}

                {lineItemsTotal > 0 && (
                  <div className="flex justify-end">
                    <p className="text-sm font-semibold text-main">
                      Total: {formatCurrency(lineItemsTotal)}
                    </p>
                  </div>
                )}
              </div>

              <Button
                type="submit"
                loading={submitting}
                disabled={!formJobId || !title}
                className="w-full sm:w-auto min-h-[44px]"
              >
                <Plus size={16} />
                Create Draft
              </Button>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Orders List */}
      {orders.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <FileText size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No change orders</p>
            <p className="text-sm text-muted mt-1">
              Create a change order when the scope of work needs to be modified.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {orders.map((order) => (
            <Card key={order.id}>
              <CardContent className="py-3.5">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-xs font-mono text-muted">{order.orderNumber}</span>
                      <StatusBadge status={order.status} />
                    </div>
                    <p className="text-sm font-medium text-main mt-1">{order.title}</p>
                    {order.jobTitle && (
                      <p className="text-xs text-muted mt-0.5">{order.jobTitle}</p>
                    )}
                    <p className="text-xs text-muted mt-1">{formatDate(order.createdAt)}</p>
                  </div>
                  <div className="flex flex-col items-end gap-2 flex-shrink-0">
                    <p className="text-sm font-semibold text-main">
                      {formatCurrency(order.amount)}
                    </p>
                    {order.status === 'draft' && (
                      <Button
                        size="sm"
                        variant="secondary"
                        onClick={() => handleSubmitForApproval(order.id)}
                        loading={submittingApproval === order.id}
                      >
                        <Send size={14} />
                        Submit
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
