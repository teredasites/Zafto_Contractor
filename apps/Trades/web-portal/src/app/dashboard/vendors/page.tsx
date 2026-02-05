'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  MoreHorizontal,
  Building,
  Mail,
  Phone,
  MapPin,
  Globe,
  DollarSign,
  Package,
  Star,
  Clock,
  FileText,
  ExternalLink,
  Edit,
  Trash2,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

interface Vendor {
  id: string;
  name: string;
  contactName?: string;
  email: string;
  phone: string;
  website?: string;
  address: {
    street: string;
    city: string;
    state: string;
    zip: string;
  };
  category: string;
  accountNumber?: string;
  paymentTerms: string;
  rating: number;
  totalSpent: number;
  orderCount: number;
  lastOrderDate?: Date;
  notes?: string;
  isPreferred: boolean;
  createdAt: Date;
}

const mockVendors: Vendor[] = [
  {
    id: 'v1',
    name: 'Electrical Supply Co.',
    contactName: 'Mike Johnson',
    email: 'orders@electricalsupply.com',
    phone: '(555) 111-2222',
    website: 'www.electricalsupply.com',
    address: { street: '100 Industrial Way', city: 'Hartford', state: 'CT', zip: '06101' },
    category: 'Electrical',
    accountNumber: 'ESC-78542',
    paymentTerms: 'Net 30',
    rating: 5,
    totalSpent: 45680,
    orderCount: 28,
    lastOrderDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    notes: 'Best prices on panels and wire. Free delivery over $500.',
    isPreferred: true,
    createdAt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'v2',
    name: 'Plumbing Wholesale',
    contactName: 'Sarah Chen',
    email: 'sales@plumbingwholesale.com',
    phone: '(555) 222-3333',
    website: 'www.plumbingwholesale.com',
    address: { street: '250 Commerce Blvd', city: 'Manchester', state: 'CT', zip: '06040' },
    category: 'Plumbing',
    accountNumber: 'PW-12345',
    paymentTerms: 'Net 15',
    rating: 4,
    totalSpent: 28350,
    orderCount: 15,
    lastOrderDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    isPreferred: true,
    createdAt: new Date(Date.now() - 200 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'v3',
    name: 'HVAC Distributors Inc.',
    contactName: 'Tom Williams',
    email: 'orders@hvacdist.com',
    phone: '(555) 333-4444',
    address: { street: '500 Warehouse Dr', city: 'East Hartford', state: 'CT', zip: '06108' },
    category: 'HVAC',
    accountNumber: 'HVAC-9876',
    paymentTerms: 'Net 30',
    rating: 4,
    totalSpent: 52100,
    orderCount: 12,
    lastOrderDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
    notes: 'Carrier authorized dealer. Good warranty support.',
    isPreferred: false,
    createdAt: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'v4',
    name: 'Home Depot Pro',
    email: 'pro@homedepot.com',
    phone: '(555) 444-5555',
    website: 'www.homedepot.com/pro',
    address: { street: '1000 Retail Way', city: 'West Hartford', state: 'CT', zip: '06107' },
    category: 'General',
    accountNumber: 'HD-PRO-5555',
    paymentTerms: 'Credit Card',
    rating: 3,
    totalSpent: 12500,
    orderCount: 35,
    lastOrderDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    notes: 'Good for quick pickups. Higher prices but convenient.',
    isPreferred: false,
    createdAt: new Date(Date.now() - 400 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'v5',
    name: 'Roofing Materials Inc.',
    contactName: 'Dave Martinez',
    email: 'sales@roofingmaterials.com',
    phone: '(555) 555-6666',
    address: { street: '750 Builder Lane', city: 'Glastonbury', state: 'CT', zip: '06033' },
    category: 'Roofing',
    paymentTerms: 'COD',
    rating: 5,
    totalSpent: 18900,
    orderCount: 8,
    lastOrderDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    isPreferred: true,
    createdAt: new Date(Date.now() - 150 * 24 * 60 * 60 * 1000),
  },
];

const categoryOptions = [
  { value: 'all', label: 'All Categories' },
  { value: 'Electrical', label: 'Electrical' },
  { value: 'Plumbing', label: 'Plumbing' },
  { value: 'HVAC', label: 'HVAC' },
  { value: 'General', label: 'General' },
  { value: 'Roofing', label: 'Roofing' },
  { value: 'Lumber', label: 'Lumber' },
];

export default function VendorsPage() {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [showNewVendorModal, setShowNewVendorModal] = useState(false);
  const [selectedVendor, setSelectedVendor] = useState<Vendor | null>(null);

  const filteredVendors = mockVendors.filter((vendor) => {
    const matchesSearch =
      vendor.name.toLowerCase().includes(search.toLowerCase()) ||
      vendor.contactName?.toLowerCase().includes(search.toLowerCase()) ||
      vendor.email.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || vendor.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  // Stats
  const totalVendors = mockVendors.length;
  const preferredCount = mockVendors.filter((v) => v.isPreferred).length;
  const totalSpent = mockVendors.reduce((sum, v) => sum + v.totalSpent, 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Vendors</h1>
          <p className="text-muted mt-1">Manage your suppliers and track spending</p>
        </div>
        <Button onClick={() => setShowNewVendorModal(true)}>
          <Plus size={16} />
          Add Vendor
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Building size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalVendors}</p>
                <p className="text-sm text-muted">Total Vendors</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Star size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{preferredCount}</p>
                <p className="text-sm text-muted">Preferred</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <DollarSign size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalSpent)}</p>
                <p className="text-sm text-muted">Total Spent (YTD)</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Package size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{mockVendors.reduce((sum, v) => sum + v.orderCount, 0)}</p>
                <p className="text-sm text-muted">Total Orders</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search vendors..."
          className="sm:w-80"
        />
        <Select
          options={categoryOptions}
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Vendors Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredVendors.map((vendor) => (
          <VendorCard
            key={vendor.id}
            vendor={vendor}
            onClick={() => setSelectedVendor(vendor)}
          />
        ))}
      </div>

      {/* New Vendor Modal */}
      {showNewVendorModal && (
        <NewVendorModal onClose={() => setShowNewVendorModal(false)} />
      )}

      {/* Vendor Detail Modal */}
      {selectedVendor && (
        <VendorDetailModal
          vendor={selectedVendor}
          onClose={() => setSelectedVendor(null)}
        />
      )}
    </div>
  );
}

function VendorCard({ vendor, onClick }: { vendor: Vendor; onClick: () => void }) {
  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onClick}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <Avatar name={vendor.name} size="md" />
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-medium text-main">{vendor.name}</h3>
                {vendor.isPreferred && (
                  <Star size={14} className="text-amber-500 fill-amber-500" />
                )}
              </div>
              <p className="text-sm text-muted">{vendor.category}</p>
            </div>
          </div>
          <button
            onClick={(e) => { e.stopPropagation(); }}
            className="p-1.5 hover:bg-surface-hover rounded-lg"
          >
            <MoreHorizontal size={16} className="text-muted" />
          </button>
        </div>

        <div className="space-y-2 mb-4">
          {vendor.contactName && (
            <p className="text-sm text-muted">{vendor.contactName}</p>
          )}
          <div className="flex items-center gap-2 text-sm text-muted">
            <Phone size={14} />
            <span>{vendor.phone}</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-muted">
            <Mail size={14} />
            <span className="truncate">{vendor.email}</span>
          </div>
        </div>

        <div className="pt-3 border-t border-main flex items-center justify-between">
          <div>
            <p className="text-lg font-semibold text-main">{formatCurrency(vendor.totalSpent)}</p>
            <p className="text-xs text-muted">{vendor.orderCount} orders</p>
          </div>
          <div className="flex items-center gap-1">
            {[1, 2, 3, 4, 5].map((star) => (
              <Star
                key={star}
                size={14}
                className={cn(
                  star <= vendor.rating
                    ? 'text-amber-500 fill-amber-500'
                    : 'text-muted'
                )}
              />
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function VendorDetailModal({ vendor, onClose }: { vendor: Vendor; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-4">
              <Avatar name={vendor.name} size="lg" />
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-xl font-semibold text-main">{vendor.name}</h2>
                  {vendor.isPreferred && (
                    <Badge variant="warning" size="sm">
                      <Star size={12} className="fill-current" />
                      Preferred
                    </Badge>
                  )}
                </div>
                <p className="text-muted">{vendor.category}</p>
              </div>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Contact Info */}
          <div className="grid grid-cols-2 gap-4">
            {vendor.contactName && (
              <div>
                <p className="text-sm text-muted mb-1">Contact</p>
                <p className="font-medium text-main">{vendor.contactName}</p>
              </div>
            )}
            <div>
              <p className="text-sm text-muted mb-1">Phone</p>
              <p className="font-medium text-main">{vendor.phone}</p>
            </div>
            <div>
              <p className="text-sm text-muted mb-1">Email</p>
              <p className="font-medium text-main">{vendor.email}</p>
            </div>
            {vendor.website && (
              <div>
                <p className="text-sm text-muted mb-1">Website</p>
                <a href={`https://${vendor.website}`} target="_blank" rel="noopener noreferrer" className="font-medium text-accent flex items-center gap-1">
                  {vendor.website}
                  <ExternalLink size={14} />
                </a>
              </div>
            )}
          </div>

          {/* Address */}
          <div>
            <p className="text-sm text-muted mb-1">Address</p>
            <p className="text-main">
              {vendor.address.street}<br />
              {vendor.address.city}, {vendor.address.state} {vendor.address.zip}
            </p>
          </div>

          {/* Account Info */}
          <div className="grid grid-cols-2 gap-4 p-4 bg-secondary rounded-lg">
            {vendor.accountNumber && (
              <div>
                <p className="text-sm text-muted mb-1">Account #</p>
                <p className="font-mono font-medium text-main">{vendor.accountNumber}</p>
              </div>
            )}
            <div>
              <p className="text-sm text-muted mb-1">Payment Terms</p>
              <p className="font-medium text-main">{vendor.paymentTerms}</p>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">{formatCurrency(vendor.totalSpent)}</p>
              <p className="text-sm text-muted">Total Spent</p>
            </div>
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">{vendor.orderCount}</p>
              <p className="text-sm text-muted">Orders</p>
            </div>
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">
                {vendor.lastOrderDate ? formatDate(vendor.lastOrderDate) : 'N/A'}
              </p>
              <p className="text-sm text-muted">Last Order</p>
            </div>
          </div>

          {/* Notes */}
          {vendor.notes && (
            <div>
              <p className="text-sm text-muted mb-1">Notes</p>
              <p className="text-main">{vendor.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button className="flex-1">
              <Package size={16} />
              Create PO
            </Button>
            <Button variant="secondary">
              <Edit size={16} />
              Edit
            </Button>
            <Button variant="ghost" className="text-red-600">
              <Trash2 size={16} />
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewVendorModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add New Vendor</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Company Name *" placeholder="Electrical Supply Co." />
          <Input label="Contact Name" placeholder="John Smith" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Email *" type="email" placeholder="orders@company.com" />
            <Input label="Phone *" type="tel" placeholder="(555) 123-4567" />
          </div>
          <Select
            label="Category"
            options={categoryOptions.filter((c) => c.value !== 'all')}
          />
          <Input label="Account Number" placeholder="Optional" />
          <Select
            label="Payment Terms"
            options={[
              { value: 'Net 30', label: 'Net 30' },
              { value: 'Net 15', label: 'Net 15' },
              { value: 'COD', label: 'COD' },
              { value: 'Credit Card', label: 'Credit Card' },
              { value: 'Due on Receipt', label: 'Due on Receipt' },
            ]}
          />
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1">
              <Plus size={16} />
              Add Vendor
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
