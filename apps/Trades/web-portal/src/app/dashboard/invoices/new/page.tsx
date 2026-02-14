'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  ArrowLeft,
  Receipt,
  User,
  Calendar,
  DollarSign,
  Search,
  Plus,
  X,
  Trash2,
  Briefcase,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { formatCurrency, cn } from '@/lib/utils';
import { useCustomers } from '@/lib/hooks/use-customers';
import { useJobs } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';

type PaymentSource = 'standard' | 'carrier' | 'deductible' | 'upgrade';

interface LineItem {
  id: string;
  description: string;
  quantity: number;
  unitPrice: number;
  paymentSource: PaymentSource;
}

export default function NewInvoicePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const jobId = searchParams.get('jobId');
  const customerId = searchParams.get('customerId');

  const [formData, setFormData] = useState({
    customerId: customerId || '',
    jobId: jobId || '',
    dueDate: '',
    taxRate: 6.35,
    notes: '',
  });

  const [lineItems, setLineItems] = useState<LineItem[]>([
    { id: '1', description: '', quantity: 1, unitPrice: 0, paymentSource: 'standard' },
  ]);

  const [customerSearch, setCustomerSearch] = useState('');
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const { customers } = useCustomers();
  const { jobs } = useJobs();
  const { createInvoice } = useInvoices();
  const [saving, setSaving] = useState(false);

  const selectedCustomer = customers.find((c) => c.id === formData.customerId);
  const selectedJob = jobs.find((j) => j.id === formData.jobId);

  // If job is selected, auto-select customer
  useEffect(() => {
    if (selectedJob && !formData.customerId) {
      setFormData((prev) => ({ ...prev, customerId: selectedJob.customerId }));
    }
  }, [selectedJob, formData.customerId]);

  const filteredCustomers = customers.filter(
    (c) =>
      c.firstName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.lastName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.email.toLowerCase().includes(customerSearch.toLowerCase())
  );

  const customerJobs = jobs.filter(
    (j) => j.customerId === formData.customerId && (j.status === 'completed' || j.status === 'in_progress')
  );

  const isInsuranceJob = selectedJob?.jobType === 'insurance_claim' || selectedJob?.jobType === 'warranty_dispatch';

  const addLineItem = () => {
    setLineItems([
      ...lineItems,
      { id: Date.now().toString(), description: '', quantity: 1, unitPrice: 0, paymentSource: isInsuranceJob ? 'carrier' : 'standard' },
    ]);
  };

  const removeLineItem = (id: string) => {
    if (lineItems.length > 1) {
      setLineItems(lineItems.filter((item) => item.id !== id));
    }
  };

  const updateLineItem = (id: string, field: keyof LineItem, value: string | number) => {
    setLineItems(
      lineItems.map((item) =>
        item.id === id ? { ...item, [field]: value } : item
      )
    );
  };

  const subtotal = lineItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  const tax = subtotal * (formData.taxRate / 100);
  const total = subtotal + tax;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const selectedCustomer = customers.find((c) => c.id === formData.customerId);
      await createInvoice({
        customerId: formData.customerId || undefined,
        jobId: formData.jobId || undefined,
        customer: selectedCustomer || undefined,
        lineItems: lineItems.map((li) => ({
          id: li.id,
          description: li.description,
          quantity: li.quantity,
          unitPrice: li.unitPrice,
          total: li.quantity * li.unitPrice,
        })),
        subtotal,
        taxRate: formData.taxRate,
        tax,
        total,
        dueDate: formData.dueDate ? new Date(formData.dueDate) : undefined,
        notes: formData.notes || undefined,
      });
      router.push('/dashboard/invoices');
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create invoice');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => router.back()}
          className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
        >
          <ArrowLeft size={20} className="text-muted" />
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-main">New Invoice</h1>
          <p className="text-muted mt-1">Create a new invoice</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Form */}
        <div className="lg:col-span-2 space-y-6">
          {/* Customer */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Customer
              </CardTitle>
            </CardHeader>
            <CardContent>
              {selectedCustomer ? (
                <div className="flex items-center justify-between p-4 bg-secondary rounded-lg">
                  <div className="flex items-center gap-3">
                    <Avatar name={`${selectedCustomer.firstName} ${selectedCustomer.lastName}`} size="lg" />
                    <div>
                      <p className="font-medium text-main">
                        {selectedCustomer.firstName} {selectedCustomer.lastName}
                      </p>
                      <p className="text-sm text-muted">{selectedCustomer.email}</p>
                    </div>
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setFormData({ ...formData, customerId: '', jobId: '' })}
                  >
                    <X size={16} />
                    Change
                  </Button>
                </div>
              ) : (
                <div className="relative">
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                      <input
                        type="text"
                        placeholder="Search customers..."
                        value={customerSearch}
                        onChange={(e) => setCustomerSearch(e.target.value)}
                        onFocus={() => setShowCustomerSearch(true)}
                        className="w-full pl-10 pr-4 py-2.5 bg-secondary border border-main rounded-lg text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                      />
                    </div>
                    <Button type="button" variant="secondary" onClick={() => router.push('/dashboard/customers/new')}>
                      <Plus size={16} />
                      New
                    </Button>
                  </div>

                  {showCustomerSearch && customerSearch && (
                    <>
                      <div className="fixed inset-0 z-40" onClick={() => setShowCustomerSearch(false)} />
                      <div className="absolute top-full left-0 right-0 mt-2 bg-surface border border-main rounded-lg shadow-lg z-50 max-h-64 overflow-y-auto">
                        {filteredCustomers.length === 0 ? (
                          <div className="p-4 text-center text-muted">No customers found</div>
                        ) : (
                          filteredCustomers.map((customer) => (
                            <button
                              key={customer.id}
                              type="button"
                              onClick={() => {
                                setFormData({ ...formData, customerId: customer.id });
                                setCustomerSearch('');
                                setShowCustomerSearch(false);
                              }}
                              className="w-full px-4 py-3 text-left hover:bg-surface-hover flex items-center gap-3"
                            >
                              <Avatar name={`${customer.firstName} ${customer.lastName}`} size="sm" />
                              <div>
                                <p className="font-medium text-main">
                                  {customer.firstName} {customer.lastName}
                                </p>
                                <p className="text-xs text-muted">{customer.email}</p>
                              </div>
                            </button>
                          ))
                        )}
                      </div>
                    </>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Related Job */}
          {selectedCustomer && customerJobs.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <Briefcase size={18} className="text-muted" />
                  Related Job (Optional)
                </CardTitle>
              </CardHeader>
              <CardContent>
                <Select
                  value={formData.jobId}
                  onChange={(e) => setFormData({ ...formData, jobId: e.target.value })}
                  options={[
                    { value: '', label: 'No related job' },
                    ...customerJobs.map((job) => ({
                      value: job.id,
                      label: `${job.title} - ${formatCurrency(job.estimatedValue)}`,
                    })),
                  ]}
                />
              </CardContent>
            </Card>
          )}

          {/* Line Items */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={18} className="text-muted" />
                Line Items
              </CardTitle>
              <Button type="button" variant="secondary" size="sm" onClick={addLineItem}>
                <Plus size={14} />
                Add Item
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Description</th>
                    <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3 w-24">Qty</th>
                    <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3 w-32">Price</th>
                    {isInsuranceJob && (
                      <th className="text-left text-xs font-medium text-muted uppercase px-4 py-3 w-40">Source</th>
                    )}
                    <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3 w-32">Total</th>
                    <th className="w-12"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {lineItems.map((item) => (
                    <tr key={item.id}>
                      <td className="px-6 py-3">
                        <input
                          type="text"
                          value={item.description}
                          onChange={(e) => updateLineItem(item.id, 'description', e.target.value)}
                          placeholder="Item description"
                          className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                        />
                      </td>
                      <td className="px-4 py-3">
                        <input
                          type="number"
                          min="1"
                          value={item.quantity}
                          onChange={(e) => updateLineItem(item.id, 'quantity', parseInt(e.target.value) || 1)}
                          className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-right focus:outline-none focus:ring-2 focus:ring-accent/50"
                        />
                      </td>
                      <td className="px-4 py-3">
                        <div className="relative">
                          <DollarSign size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                          <input
                            type="number"
                            step="0.01"
                            min="0"
                            value={item.unitPrice}
                            onChange={(e) => updateLineItem(item.id, 'unitPrice', parseFloat(e.target.value) || 0)}
                            className="w-full pl-8 pr-3 py-2 bg-secondary border border-main rounded-lg text-main text-right focus:outline-none focus:ring-2 focus:ring-accent/50"
                          />
                        </div>
                      </td>
                      {isInsuranceJob && (
                        <td className="px-4 py-3">
                          <select
                            value={item.paymentSource}
                            onChange={(e) => updateLineItem(item.id, 'paymentSource', e.target.value)}
                            className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                          >
                            <option value="carrier">Carrier</option>
                            <option value="deductible">Deductible</option>
                            <option value="upgrade">Upgrade</option>
                            <option value="standard">Standard</option>
                          </select>
                        </td>
                      )}
                      <td className="px-6 py-3 text-right font-medium text-main">
                        {formatCurrency(item.quantity * item.unitPrice)}
                      </td>
                      <td className="pr-4 py-3">
                        <button
                          type="button"
                          onClick={() => removeLineItem(item.id)}
                          disabled={lineItems.length === 1}
                          className="p-2 text-muted hover:text-red-500 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                          <Trash2 size={16} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Totals */}
              <div className="px-6 py-4 border-t border-main">
                <div className="flex justify-end">
                  <div className="w-64 space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-muted">Subtotal</span>
                      <span className="text-main">{formatCurrency(subtotal)}</span>
                    </div>
                    <div className="flex justify-between text-sm items-center">
                      <span className="text-muted">Tax</span>
                      <div className="flex items-center gap-2">
                        <input
                          type="number"
                          step="0.01"
                          min="0"
                          value={formData.taxRate}
                          onChange={(e) => setFormData({ ...formData, taxRate: parseFloat(e.target.value) || 0 })}
                          className="w-16 px-2 py-1 bg-secondary border border-main rounded text-main text-right text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                        />
                        <span className="text-muted">%</span>
                        <span className="text-main ml-2">{formatCurrency(tax)}</span>
                      </div>
                    </div>
                    <div className="flex justify-between font-semibold text-lg pt-2 border-t border-main">
                      <span>Total</span>
                      <span>{formatCurrency(total)}</span>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Notes</CardTitle>
            </CardHeader>
            <CardContent>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                placeholder="Notes to appear on invoice..."
                className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                rows={3}
              />
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Invoice Details */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Calendar size={18} className="text-muted" />
                Invoice Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Input
                label="Due Date"
                type="date"
                value={formData.dueDate}
                onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                required
              />
              <p className="text-xs text-muted">
                Invoice number will be auto-generated
              </p>
            </CardContent>
          </Card>

          {/* Summary */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted">Items</span>
                <span className="text-main">{lineItems.length}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Subtotal</span>
                <span className="text-main">{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Tax</span>
                <span className="text-main">{formatCurrency(tax)}</span>
              </div>
              <div className="flex justify-between font-semibold text-lg pt-2 border-t border-main">
                <span>Total</span>
                <span>{formatCurrency(total)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <div className="space-y-3">
            <Button type="submit" className="w-full">
              Create Invoice
            </Button>
            <Button type="button" variant="secondary" className="w-full">
              Save as Draft
            </Button>
            <Button type="button" variant="ghost" className="w-full" onClick={() => router.back()}>
              Cancel
            </Button>
          </div>
        </div>
      </form>
    </div>
  );
}
