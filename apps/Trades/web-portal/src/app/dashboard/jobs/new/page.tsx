'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  ArrowLeft,
  Briefcase,
  User,
  MapPin,
  Calendar,
  DollarSign,
  Users,
  Search,
  Plus,
  X,
  Shield,
  FileCheck,
  Clock,
  FileText,
  Wrench,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { useCustomers } from '@/lib/hooks/use-customers';
import { useJobs, useTeam } from '@/lib/hooks/use-jobs';
import type { JobType } from '@/types';
import { useDraftRecovery } from '@/lib/hooks/use-draft-recovery';

export default function NewJobPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const bidId = searchParams.get('bidId');
  const customerId = searchParams.get('customerId');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    customerId: customerId || '',
    jobType: 'standard' as JobType,
    priority: 'normal',
    tradeType: 'electrical',
    estimatedValue: '',
    estimatedHours: '',
    poNumber: '',
    scopeOfWork: '',
    internalNotes: '',
    scheduledDate: '',
    scheduledTime: '',
    useCustomerAddress: true,
    address: {
      street: '',
      city: '',
      state: '',
      zip: '',
    },
    // Insurance metadata
    insuranceCompany: '',
    claimNumber: '',
    policyNumber: '',
    dateOfLoss: '',
    adjusterName: '',
    adjusterPhone: '',
    adjusterEmail: '',
    deductible: '',
    coverageLimit: '',
    // Warranty metadata
    warrantyCompany: '',
    dispatchNumber: '',
    authorizationLimit: '',
    serviceFee: '',
    warrantyType: 'home_warranty',
  });

  const [customerSearch, setCustomerSearch] = useState('');
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const [assignedMembers, setAssignedMembers] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const { customers } = useCustomers();
  const { team } = useTeam();
  const { createJob } = useJobs();

  // DEPTH27: Draft recovery — auto-save job form
  const draftRecovery = useDraftRecovery({
    feature: 'form',
    key: 'new-job',
    screenRoute: '/dashboard/jobs/new',
  });

  useEffect(() => {
    if (draftRecovery.hasDraft && !draftRecovery.checking) {
      const restored = draftRecovery.restoreDraft() as Record<string, unknown> | null;
      if (restored) {
        if (restored.formData) setFormData(restored.formData as typeof formData);
        if (restored.assignedMembers) setAssignedMembers(restored.assignedMembers as string[]);
      }
      draftRecovery.markRecovered();
    }
  }, [draftRecovery.hasDraft, draftRecovery.checking]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    draftRecovery.saveDraft({ formData, assignedMembers });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [formData, assignedMembers]);

  const selectedCustomer = customers.find((c) => c.id === formData.customerId);

  const filteredCustomers = customers.filter(
    (c) =>
      c.firstName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.lastName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.email.toLowerCase().includes(customerSearch.toLowerCase())
  );

  const buildTypeMetadata = () => {
    if (formData.jobType === 'insurance_claim') {
      return {
        claimNumber: formData.claimNumber,
        policyNumber: formData.policyNumber || undefined,
        insuranceCompany: formData.insuranceCompany,
        adjusterName: formData.adjusterName || undefined,
        adjusterPhone: formData.adjusterPhone || undefined,
        adjusterEmail: formData.adjusterEmail || undefined,
        dateOfLoss: formData.dateOfLoss,
        deductible: formData.deductible ? parseFloat(formData.deductible) : undefined,
        coverageLimit: formData.coverageLimit ? parseFloat(formData.coverageLimit) : undefined,
        approvalStatus: 'pending' as const,
      };
    }
    if (formData.jobType === 'warranty_dispatch') {
      return {
        warrantyCompany: formData.warrantyCompany,
        dispatchNumber: formData.dispatchNumber,
        authorizationLimit: formData.authorizationLimit ? parseFloat(formData.authorizationLimit) : undefined,
        serviceFee: formData.serviceFee ? parseFloat(formData.serviceFee) : undefined,
        warrantyType: formData.warrantyType as 'home_warranty' | 'manufacturer' | 'extended',
      };
    }
    return {};
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      const scheduledStart = formData.scheduledDate
        ? new Date(`${formData.scheduledDate}T${formData.scheduledTime || '09:00'}`)
        : undefined;

      await createJob({
        title: formData.title,
        description: formData.description || undefined,
        customerId: formData.customerId || undefined,
        jobType: formData.jobType,
        typeMetadata: buildTypeMetadata(),
        status: 'lead',
        priority: formData.priority as 'low' | 'normal' | 'high' | 'urgent',
        tradeType: formData.tradeType || undefined,
        address: formData.useCustomerAddress && selectedCustomer
          ? selectedCustomer.address
          : formData.address,
        estimatedValue: formData.estimatedValue ? parseFloat(formData.estimatedValue) : 0,
        estimatedDuration: formData.estimatedHours ? Math.round(parseFloat(formData.estimatedHours) * 60) : undefined,
        internalNotes: formData.internalNotes || undefined,
        scheduledStart,
        assignedTo: assignedMembers,
        customer: selectedCustomer,
      });
      router.push('/dashboard/jobs');
    } catch (err) {
      console.error('Failed to create job:', err);
    } finally {
      setSaving(false);
    }
  };

  const toggleMember = (memberId: string) => {
    setAssignedMembers((prev) =>
      prev.includes(memberId)
        ? prev.filter((id) => id !== memberId)
        : [...prev, memberId]
    );
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
          <h1 className="text-2xl font-semibold text-main">New Job</h1>
          <p className="text-muted mt-1">Create a new job</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Form */}
        <div className="lg:col-span-2 space-y-6">
          {/* Basic Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Briefcase size={18} className="text-muted" />
                Job Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Input
                label="Job Title"
                placeholder="e.g., Panel Upgrade, Outlet Installation"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                required
              />
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Description</label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Describe the work to be done..."
                  className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                  rows={4}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Select
                  label="Priority"
                  value={formData.priority}
                  onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
                  options={[
                    { value: 'low', label: 'Low' },
                    { value: 'normal', label: 'Normal' },
                    { value: 'high', label: 'High' },
                    { value: 'urgent', label: 'Urgent' },
                  ]}
                />
                <Select
                  label="Trade Type"
                  value={formData.tradeType}
                  onChange={(e) => setFormData({ ...formData, tradeType: e.target.value })}
                  options={[
                    { value: 'electrical', label: 'Electrical' },
                    { value: 'plumbing', label: 'Plumbing' },
                    { value: 'hvac', label: 'HVAC' },
                    { value: 'solar', label: 'Solar' },
                    { value: 'roofing', label: 'Roofing' },
                    { value: 'painting', label: 'Painting' },
                    { value: 'carpentry', label: 'Carpentry' },
                    { value: 'flooring', label: 'Flooring' },
                    { value: 'landscaping', label: 'Landscaping' },
                    { value: 'general', label: 'General' },
                    { value: 'other', label: 'Other' },
                  ]}
                />
              </div>
              <div className="grid grid-cols-3 gap-4">
                <Input
                  label="Estimated Value"
                  type="number"
                  placeholder="0.00"
                  value={formData.estimatedValue}
                  onChange={(e) => setFormData({ ...formData, estimatedValue: e.target.value })}
                  icon={<DollarSign size={16} />}
                />
                <Input
                  label="Estimated Hours"
                  type="number"
                  placeholder="0"
                  value={formData.estimatedHours}
                  onChange={(e) => setFormData({ ...formData, estimatedHours: e.target.value })}
                  icon={<Clock size={16} />}
                />
                <Input
                  label="PO Number"
                  placeholder="PO-00000"
                  value={formData.poNumber}
                  onChange={(e) => setFormData({ ...formData, poNumber: e.target.value })}
                />
              </div>

              {/* Job Type Selector */}
              <div>
                <label className="block text-sm font-medium text-main mb-2">Job Type</label>
                <div className="grid grid-cols-3 gap-3">
                  {([
                    { value: 'standard', label: 'Standard', icon: Briefcase, color: 'blue' },
                    { value: 'insurance_claim', label: 'Insurance Claim', icon: Shield, color: 'amber' },
                    { value: 'warranty_dispatch', label: 'Warranty Dispatch', icon: FileCheck, color: 'purple' },
                  ] as const).map(({ value, label, icon: Icon, color }) => (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setFormData({ ...formData, jobType: value })}
                      className={cn(
                        'flex flex-col items-center gap-2 p-4 rounded-lg border-2 transition-colors text-center',
                        formData.jobType === value
                          ? `border-${color}-500 bg-${color}-50 dark:bg-${color}-900/20`
                          : 'border-main hover:bg-surface-hover'
                      )}
                    >
                      <Icon size={20} className={formData.jobType === value ? `text-${color}-600 dark:text-${color}-400` : 'text-muted'} />
                      <span className={cn('text-sm font-medium', formData.jobType === value ? 'text-main' : 'text-muted')}>{label}</span>
                    </button>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Insurance Claim Fields */}
          {formData.jobType === 'insurance_claim' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <Shield size={18} className="text-amber-600 dark:text-amber-400" />
                  Insurance Details
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Insurance Company"
                    placeholder="e.g., State Farm"
                    value={formData.insuranceCompany}
                    onChange={(e) => setFormData({ ...formData, insuranceCompany: e.target.value })}
                    required
                  />
                  <Input
                    label="Claim Number"
                    placeholder="CLM-XXXXXXX"
                    value={formData.claimNumber}
                    onChange={(e) => setFormData({ ...formData, claimNumber: e.target.value })}
                    required
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Policy Number"
                    placeholder="POL-XXXXXXX"
                    value={formData.policyNumber}
                    onChange={(e) => setFormData({ ...formData, policyNumber: e.target.value })}
                  />
                  <Input
                    label="Date of Loss"
                    type="date"
                    value={formData.dateOfLoss}
                    onChange={(e) => setFormData({ ...formData, dateOfLoss: e.target.value })}
                    required
                  />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <Input
                    label="Adjuster Name"
                    placeholder="John Smith"
                    value={formData.adjusterName}
                    onChange={(e) => setFormData({ ...formData, adjusterName: e.target.value })}
                  />
                  <Input
                    label="Adjuster Phone"
                    placeholder="(555) 123-4567"
                    value={formData.adjusterPhone}
                    onChange={(e) => setFormData({ ...formData, adjusterPhone: e.target.value })}
                  />
                  <Input
                    label="Adjuster Email"
                    type="email"
                    placeholder="adjuster@insurance.com"
                    value={formData.adjusterEmail}
                    onChange={(e) => setFormData({ ...formData, adjusterEmail: e.target.value })}
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Deductible"
                    type="number"
                    placeholder="0.00"
                    value={formData.deductible}
                    onChange={(e) => setFormData({ ...formData, deductible: e.target.value })}
                    icon={<DollarSign size={16} />}
                  />
                  <Input
                    label="Coverage Limit"
                    type="number"
                    placeholder="0.00"
                    value={formData.coverageLimit}
                    onChange={(e) => setFormData({ ...formData, coverageLimit: e.target.value })}
                    icon={<DollarSign size={16} />}
                  />
                </div>
              </CardContent>
            </Card>
          )}

          {/* Warranty Dispatch Fields */}
          {formData.jobType === 'warranty_dispatch' && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <FileCheck size={18} className="text-purple-600 dark:text-purple-400" />
                  Warranty Details
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Warranty Company"
                    placeholder="e.g., American Home Shield"
                    value={formData.warrantyCompany}
                    onChange={(e) => setFormData({ ...formData, warrantyCompany: e.target.value })}
                    required
                  />
                  <Input
                    label="Dispatch Number"
                    placeholder="DSP-XXXXXXX"
                    value={formData.dispatchNumber}
                    onChange={(e) => setFormData({ ...formData, dispatchNumber: e.target.value })}
                    required
                  />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <Select
                    label="Warranty Type"
                    value={formData.warrantyType}
                    onChange={(e) => setFormData({ ...formData, warrantyType: e.target.value })}
                    options={[
                      { value: 'home_warranty', label: 'Home Warranty' },
                      { value: 'manufacturer', label: 'Manufacturer' },
                      { value: 'extended', label: 'Extended Warranty' },
                    ]}
                  />
                  <Input
                    label="Authorization Limit"
                    type="number"
                    placeholder="0.00"
                    value={formData.authorizationLimit}
                    onChange={(e) => setFormData({ ...formData, authorizationLimit: e.target.value })}
                    icon={<DollarSign size={16} />}
                  />
                  <Input
                    label="Service Fee"
                    type="number"
                    placeholder="75.00"
                    value={formData.serviceFee}
                    onChange={(e) => setFormData({ ...formData, serviceFee: e.target.value })}
                    icon={<DollarSign size={16} />}
                  />
                </div>
              </CardContent>
            </Card>
          )}

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
                    onClick={() => setFormData({ ...formData, customerId: '' })}
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

          {/* Scope & Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <FileText size={18} className="text-muted" />
                Scope & Notes
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Scope of Work</label>
                <textarea
                  value={formData.scopeOfWork}
                  onChange={(e) => setFormData({ ...formData, scopeOfWork: e.target.value })}
                  placeholder="Detailed scope: materials needed, labor breakdown, specific tasks..."
                  className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                  rows={4}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">
                  Internal Notes
                  <span className="text-xs text-muted ml-2">(team only — not visible to customer)</span>
                </label>
                <textarea
                  value={formData.internalNotes}
                  onChange={(e) => setFormData({ ...formData, internalNotes: e.target.value })}
                  placeholder="Access codes, special tools needed, safety notes..."
                  className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>

          {/* Location */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <MapPin size={18} className="text-muted" />
                Job Location
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {selectedCustomer && (
                <label className="flex items-center gap-3 p-3 bg-secondary rounded-lg cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.useCustomerAddress}
                    onChange={(e) => setFormData({ ...formData, useCustomerAddress: e.target.checked })}
                    className="w-4 h-4 text-accent rounded"
                  />
                  <span className="text-sm text-main">Use customer address</span>
                </label>
              )}

              {(!formData.useCustomerAddress || !selectedCustomer) && (
                <div className="space-y-4">
                  <Input
                    label="Street Address"
                    placeholder="123 Main Street"
                    value={formData.address.street}
                    onChange={(e) => setFormData({ ...formData, address: { ...formData.address, street: e.target.value } })}
                  />
                  <div className="grid grid-cols-3 gap-4">
                    <Input
                      label="City"
                      placeholder="Hartford"
                      value={formData.address.city}
                      onChange={(e) => setFormData({ ...formData, address: { ...formData.address, city: e.target.value } })}
                    />
                    <Input
                      label="State"
                      placeholder="CT"
                      value={formData.address.state}
                      onChange={(e) => setFormData({ ...formData, address: { ...formData.address, state: e.target.value } })}
                    />
                    <Input
                      label="ZIP"
                      placeholder="06103"
                      value={formData.address.zip}
                      onChange={(e) => setFormData({ ...formData, address: { ...formData.address, zip: e.target.value } })}
                    />
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Schedule */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Calendar size={18} className="text-muted" />
                Schedule
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Input
                label="Date"
                type="date"
                value={formData.scheduledDate}
                onChange={(e) => setFormData({ ...formData, scheduledDate: e.target.value })}
              />
              <Input
                label="Time"
                type="time"
                value={formData.scheduledTime}
                onChange={(e) => setFormData({ ...formData, scheduledTime: e.target.value })}
              />
            </CardContent>
          </Card>

          {/* Team Assignment */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Users size={18} className="text-muted" />
                Assign Team
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {team.filter((m) => m.role === 'field_tech' || m.role === 'admin').map((member) => (
                  <button
                    key={member.id}
                    type="button"
                    onClick={() => toggleMember(member.id)}
                    className={cn(
                      'w-full flex items-center gap-3 p-3 rounded-lg border transition-colors',
                      assignedMembers.includes(member.id)
                        ? 'border-accent bg-accent-light'
                        : 'border-main hover:bg-surface-hover'
                    )}
                  >
                    <Avatar name={member.name} size="sm" />
                    <div className="flex-1 text-left">
                      <p className="font-medium text-main text-sm">{member.name}</p>
                      <p className="text-xs text-muted capitalize">{member.role.replace('_', ' ')}</p>
                    </div>
                    {assignedMembers.includes(member.id) && (
                      <Badge variant="success" size="sm">Assigned</Badge>
                    )}
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <div className="space-y-3">
            <Button type="submit" className="w-full" disabled={saving}>
              {saving ? 'Creating...' : 'Create Job'}
            </Button>
            <Button type="button" variant="secondary" className="w-full" onClick={() => router.back()}>
              Cancel
            </Button>
          </div>
        </div>
      </form>
    </div>
  );
}
