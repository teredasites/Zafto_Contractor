'use client';

import { useState } from 'react';
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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { mockCustomers, mockTeam } from '@/lib/mock-data';

export default function NewJobPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const bidId = searchParams.get('bidId');
  const customerId = searchParams.get('customerId');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    customerId: customerId || '',
    priority: 'normal',
    estimatedValue: '',
    scheduledDate: '',
    scheduledTime: '',
    useCustomerAddress: true,
    address: {
      street: '',
      city: '',
      state: '',
      zip: '',
    },
  });

  const [customerSearch, setCustomerSearch] = useState('');
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const [assignedMembers, setAssignedMembers] = useState<string[]>([]);

  const selectedCustomer = mockCustomers.find((c) => c.id === formData.customerId);

  const filteredCustomers = mockCustomers.filter(
    (c) =>
      c.firstName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.lastName.toLowerCase().includes(customerSearch.toLowerCase()) ||
      c.email.toLowerCase().includes(customerSearch.toLowerCase())
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Save to Firestore
    console.log('Creating job:', { ...formData, assignedMembers });
    router.push('/dashboard/jobs');
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
                <Input
                  label="Estimated Value"
                  type="number"
                  placeholder="0.00"
                  value={formData.estimatedValue}
                  onChange={(e) => setFormData({ ...formData, estimatedValue: e.target.value })}
                  icon={<DollarSign size={16} />}
                />
              </div>
            </CardContent>
          </Card>

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
                {mockTeam.filter((m) => m.role === 'field_tech' || m.role === 'admin').map((member) => (
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
            <Button type="submit" className="w-full">
              Create Job
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
