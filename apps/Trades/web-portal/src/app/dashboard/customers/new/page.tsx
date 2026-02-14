'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  User,
  Mail,
  Phone,
  MapPin,
  Tag,
  FileText,
  Plus,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Select } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { isValidEmail, isValidPhone, formatPhone } from '@/lib/validation';
import { useCustomers } from '@/lib/hooks/use-customers';

export default function NewCustomerPage() {
  const router = useRouter();
  const { createCustomer } = useCustomers();
  const [saving, setSaving] = useState(false);

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    alternatePhone: '',
    address: {
      street: '',
      city: '',
      state: '',
      zip: '',
    },
    customerType: 'residential' as 'residential' | 'commercial',
    accessInstructions: '',
    preferredContactMethod: 'phone' as 'phone' | 'email' | 'text',
    emailOptIn: true,
    smsOptIn: false,
    source: '',
    notes: '',
  });

  const [tags, setTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});

  const sourceOptions = [
    { value: '', label: 'Select source...' },
    { value: 'referral', label: 'Referral' },
    { value: 'google', label: 'Google' },
    { value: 'website', label: 'Website' },
    { value: 'yelp', label: 'Yelp' },
    { value: 'facebook', label: 'Facebook' },
    { value: 'instagram', label: 'Instagram' },
    { value: 'nextdoor', label: 'Nextdoor' },
    { value: 'other', label: 'Other' },
  ];

  const suggestedTags = ['residential', 'commercial', 'vip', 'property-manager', 'repeat', 'priority'];

  const handleAddTag = () => {
    if (newTag.trim() && !tags.includes(newTag.trim().toLowerCase())) {
      setTags([...tags, newTag.trim().toLowerCase()]);
      setNewTag('');
    }
  };

  const handleRemoveTag = (tag: string) => {
    setTags(tags.filter((t) => t !== tag));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const newErrors: Record<string, string> = {};

    if (!formData.firstName.trim()) newErrors.firstName = 'First name is required';
    if (!formData.lastName.trim()) newErrors.lastName = 'Last name is required';
    if (!formData.phone.trim()) newErrors.phone = 'Phone is required';
    if (formData.phone && !isValidPhone(formData.phone)) newErrors.phone = 'Invalid phone number';
    if (formData.email && !isValidEmail(formData.email)) newErrors.email = 'Invalid email address';

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }
    setErrors({});

    try {
      setSaving(true);
      await createCustomer({
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim(),
        email: formData.email?.trim() || undefined,
        phone: formatPhone(formData.phone),
        alternatePhone: formData.alternatePhone?.trim() || undefined,
        address: formData.address,
        customerType: formData.customerType,
        accessInstructions: formData.accessInstructions?.trim() || undefined,
        emailOptIn: formData.emailOptIn,
        smsOptIn: formData.smsOptIn,
        tags,
        notes: formData.notes || undefined,
        source: formData.source || undefined,
      });
      router.push('/dashboard/customers');
    } catch (err) {
      setErrors({ submit: err instanceof Error ? err.message : 'Failed to create customer' });
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
          <h1 className="text-2xl font-semibold text-main">Add Customer</h1>
          <p className="text-muted mt-1">Create a new customer record</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Form */}
        <div className="lg:col-span-2 space-y-6">
          {/* Basic Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Contact Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {errors.submit && (
                <div className="px-3.5 py-3 rounded-lg text-sm bg-red-500/10 text-red-500">
                  {errors.submit}
                </div>
              )}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Input
                    label="First Name"
                    placeholder="John"
                    value={formData.firstName}
                    onChange={(e) => { setFormData({ ...formData, firstName: e.target.value }); setErrors((prev) => { const { firstName, ...rest } = prev; return rest; }); }}
                    required
                  />
                  {errors.firstName && <p className="text-xs text-red-500 mt-1">{errors.firstName}</p>}
                </div>
                <div>
                  <Input
                    label="Last Name"
                    placeholder="Smith"
                    value={formData.lastName}
                    onChange={(e) => { setFormData({ ...formData, lastName: e.target.value }); setErrors((prev) => { const { lastName, ...rest } = prev; return rest; }); }}
                    required
                  />
                  {errors.lastName && <p className="text-xs text-red-500 mt-1">{errors.lastName}</p>}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Input
                    label="Email"
                    type="email"
                    placeholder="john@email.com"
                    value={formData.email}
                    onChange={(e) => { setFormData({ ...formData, email: e.target.value }); setErrors((prev) => { const { email, ...rest } = prev; return rest; }); }}
                    icon={<Mail size={16} />}
                  />
                  {errors.email && <p className="text-xs text-red-500 mt-1">{errors.email}</p>}
                </div>
                <div>
                  <Input
                    label="Phone"
                    type="tel"
                    placeholder="(860) 555-0123"
                    value={formData.phone}
                    onChange={(e) => { setFormData({ ...formData, phone: e.target.value }); setErrors((prev) => { const { phone, ...rest } = prev; return rest; }); }}
                    icon={<Phone size={16} />}
                    required
                  />
                  {errors.phone && <p className="text-xs text-red-500 mt-1">{errors.phone}</p>}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Customer Type */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Customer Type</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex gap-3">
                {(['residential', 'commercial'] as const).map((type) => (
                  <button
                    key={type}
                    type="button"
                    onClick={() => setFormData({ ...formData, customerType: type })}
                    className={cn(
                      'flex-1 py-3 px-4 rounded-lg border text-sm font-medium transition-colors',
                      formData.customerType === type
                        ? 'border-accent bg-accent/10 text-accent'
                        : 'border-main bg-secondary text-muted hover:text-main'
                    )}
                  >
                    {type === 'residential' ? 'Residential' : 'Commercial'}
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Address */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <MapPin size={18} className="text-muted" />
                Address
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
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
            </CardContent>
          </Card>

          {/* Access & Communication */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Access & Communication</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Input
                label="Access Instructions"
                placeholder="Gate code, key location, parking..."
                value={formData.accessInstructions}
                onChange={(e) => setFormData({ ...formData, accessInstructions: e.target.value })}
              />
              <Input
                label="Alternate Phone"
                type="tel"
                placeholder="(555) 987-6543"
                value={formData.alternatePhone}
                onChange={(e) => setFormData({ ...formData, alternatePhone: e.target.value })}
                icon={<Phone size={16} />}
              />
              <div>
                <label className="text-xs text-muted font-medium mb-2 block">Preferred Contact Method</label>
                <div className="flex gap-2">
                  {(['phone', 'email', 'text'] as const).map((method) => (
                    <button
                      key={method}
                      type="button"
                      onClick={() => setFormData({ ...formData, preferredContactMethod: method })}
                      className={cn(
                        'flex-1 py-2 px-3 rounded-lg border text-xs font-medium transition-colors',
                        formData.preferredContactMethod === method
                          ? 'border-accent bg-accent/10 text-accent'
                          : 'border-main bg-secondary text-muted hover:text-main'
                      )}
                    >
                      {method === 'text' ? 'Text/SMS' : method.charAt(0).toUpperCase() + method.slice(1)}
                    </button>
                  ))}
                </div>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-main">
                <span className="text-sm text-main">Email marketing opt-in</span>
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, emailOptIn: !formData.emailOptIn })}
                  className={cn('w-10 h-5 rounded-full transition-colors relative', formData.emailOptIn ? 'bg-accent' : 'bg-gray-600')}
                >
                  <div className={cn('w-4 h-4 bg-white rounded-full absolute top-0.5 transition-transform', formData.emailOptIn ? 'translate-x-5' : 'translate-x-0.5')} />
                </button>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-main">SMS opt-in</span>
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, smsOptIn: !formData.smsOptIn })}
                  className={cn('w-10 h-5 rounded-full transition-colors relative', formData.smsOptIn ? 'bg-accent' : 'bg-gray-600')}
                >
                  <div className={cn('w-4 h-4 bg-white rounded-full absolute top-0.5 transition-transform', formData.smsOptIn ? 'translate-x-5' : 'translate-x-0.5')} />
                </button>
              </div>
            </CardContent>
          </Card>

          {/* Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <FileText size={18} className="text-muted" />
                Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                placeholder="Any notes about this customer..."
                className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                rows={4}
              />
            </CardContent>
          </Card>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Source */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Lead Source</CardTitle>
            </CardHeader>
            <CardContent>
              <Select
                value={formData.source}
                onChange={(e) => setFormData({ ...formData, source: e.target.value })}
                options={sourceOptions}
              />
            </CardContent>
          </Card>

          {/* Tags */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Tag size={18} className="text-muted" />
                Tags
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Current Tags */}
              <div className="flex flex-wrap gap-2">
                {tags.map((tag) => (
                  <Badge key={tag} variant="default" className="flex items-center gap-1">
                    {tag}
                    <button
                      type="button"
                      onClick={() => handleRemoveTag(tag)}
                      className="hover:text-red-500 transition-colors"
                    >
                      <X size={12} />
                    </button>
                  </Badge>
                ))}
                {tags.length === 0 && (
                  <p className="text-sm text-muted">No tags added</p>
                )}
              </div>

              {/* Add Tag */}
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newTag}
                  onChange={(e) => setNewTag(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddTag())}
                  placeholder="Add tag..."
                  className="flex-1 px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
                <Button type="button" variant="secondary" size="sm" onClick={handleAddTag}>
                  <Plus size={14} />
                </Button>
              </div>

              {/* Suggested Tags */}
              <div>
                <p className="text-xs text-muted mb-2">Suggested:</p>
                <div className="flex flex-wrap gap-1">
                  {suggestedTags
                    .filter((tag) => !tags.includes(tag))
                    .map((tag) => (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => setTags([...tags, tag])}
                        className="px-2 py-1 text-xs bg-secondary rounded hover:bg-surface-hover text-muted hover:text-main transition-colors"
                      >
                        + {tag}
                      </button>
                    ))}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <div className="space-y-3">
            <Button type="submit" className="w-full" disabled={saving}>
              {saving ? 'Saving...' : 'Add Customer'}
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
