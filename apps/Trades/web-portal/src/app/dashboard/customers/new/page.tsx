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

export default function NewCustomerPage() {
  const router = useRouter();

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    address: {
      street: '',
      city: '',
      state: '',
      zip: '',
    },
    source: '',
    notes: '',
  });

  const [tags, setTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Save to Firestore
    console.log('Creating customer:', { ...formData, tags });
    router.push('/dashboard/customers');
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
              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="First Name"
                  placeholder="John"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  required
                />
                <Input
                  label="Last Name"
                  placeholder="Smith"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="Email"
                  type="email"
                  placeholder="john@email.com"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  icon={<Mail size={16} />}
                />
                <Input
                  label="Phone"
                  type="tel"
                  placeholder="(860) 555-0123"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  icon={<Phone size={16} />}
                  required
                />
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
            <Button type="submit" className="w-full">
              Add Customer
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
