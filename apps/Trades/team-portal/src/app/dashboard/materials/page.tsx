'use client';

import { useState } from 'react';
import { Package, Plus, X, DollarSign } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { useMaterials } from '@/lib/hooks/use-materials';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn, formatCurrency } from '@/lib/utils';

const CATEGORIES = [
  { value: 'material', label: 'Material' },
  { value: 'equipment', label: 'Equipment' },
  { value: 'tool', label: 'Tool' },
  { value: 'consumable', label: 'Consumable' },
  { value: 'rental', label: 'Rental' },
];

const UNITS = [
  'each', 'ft', 'roll', 'box', 'bag', 'gallon', 'lb', 'set', 'pair', 'bundle',
];

const CATEGORY_VARIANT: Record<string, 'default' | 'success' | 'warning' | 'error' | 'info'> = {
  material: 'default',
  equipment: 'info',
  tool: 'success',
  consumable: 'warning',
  rental: 'error',
};

export default function MaterialsPage() {
  const { jobs, loading: jobsLoading } = useMyJobs();
  const [filterJobId, setFilterJobId] = useState<string | undefined>(undefined);
  const { materials, loading: matsLoading, addMaterial, totalCost } = useMaterials(filterJobId);

  const [showForm, setShowForm] = useState(false);
  const [formJobId, setFormJobId] = useState('');
  const [name, setName] = useState('');
  const [category, setCategory] = useState('material');
  const [quantity, setQuantity] = useState('1');
  const [unit, setUnit] = useState('each');
  const [unitCost, setUnitCost] = useState('');
  const [vendor, setVendor] = useState('');
  const [isBillable, setIsBillable] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const resetForm = () => {
    setFormJobId('');
    setName('');
    setCategory('material');
    setQuantity('1');
    setUnit('each');
    setUnitCost('');
    setVendor('');
    setIsBillable(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formJobId || !name) return;
    setSubmitting(true);
    await addMaterial({
      jobId: formJobId,
      name,
      category,
      quantity: parseFloat(quantity) || 1,
      unit,
      unitCost: parseFloat(unitCost) || 0,
      vendor,
      isBillable,
    });
    resetForm();
    setShowForm(false);
    setSubmitting(false);
  };

  const loading = jobsLoading || matsLoading;

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-32 rounded-lg" />
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
          <h1 className="text-xl font-bold text-main">Materials</h1>
          <p className="text-sm text-muted mt-1">
            Track materials, equipment, and supplies used on jobs
          </p>
        </div>
        <Button
          size="sm"
          onClick={() => setShowForm(!showForm)}
          className="flex-shrink-0"
        >
          {showForm ? <X size={16} /> : <Plus size={16} />}
          {showForm ? 'Cancel' : 'Add Material'}
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

      {/* Total Cost */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-emerald-100 dark:bg-emerald-900/30 flex items-center justify-center flex-shrink-0">
              <DollarSign size={20} className="text-accent" />
            </div>
            <div>
              <p className="text-xs text-muted">Total Materials Cost</p>
              <p className="text-xl font-bold text-main">{formatCurrency(totalCost)}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Add Material Form */}
      {showForm && (
        <Card>
          <CardHeader>
            <CardTitle>Add Material</CardTitle>
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
                label="Name"
                placeholder="Wire, conduit, breaker..."
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-main">Category</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className={cn(
                      'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                      'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                      'text-[15px]'
                    )}
                  >
                    {CATEGORIES.map((c) => (
                      <option key={c.value} value={c.value}>{c.label}</option>
                    ))}
                  </select>
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-main">Unit</label>
                  <select
                    value={unit}
                    onChange={(e) => setUnit(e.target.value)}
                    className={cn(
                      'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                      'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                      'text-[15px]'
                    )}
                  >
                    {UNITS.map((u) => (
                      <option key={u} value={u}>{u}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <Input
                  label="Quantity"
                  type="number"
                  min="0"
                  step="0.01"
                  value={quantity}
                  onChange={(e) => setQuantity(e.target.value)}
                />
                <Input
                  label="Unit Cost ($)"
                  type="number"
                  min="0"
                  step="0.01"
                  placeholder="0.00"
                  value={unitCost}
                  onChange={(e) => setUnitCost(e.target.value)}
                />
              </div>

              <Input
                label="Vendor"
                placeholder="Home Depot, Supply House..."
                value={vendor}
                onChange={(e) => setVendor(e.target.value)}
              />

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="billable"
                  checked={isBillable}
                  onChange={(e) => setIsBillable(e.target.checked)}
                  className="w-4 h-4 rounded border-main text-accent focus:ring-accent"
                />
                <label htmlFor="billable" className="text-sm font-medium text-main">
                  Billable to customer
                </label>
              </div>

              <Button
                type="submit"
                loading={submitting}
                disabled={!formJobId || !name}
                className="w-full sm:w-auto min-h-[44px]"
              >
                <Plus size={16} />
                Add Material
              </Button>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Materials List */}
      {materials.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Package size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">No materials recorded</p>
            <p className="text-sm text-muted mt-1">
              Add materials used on the job for tracking and billing.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {materials.map((mat) => (
            <Card key={mat.id}>
              <CardContent className="py-3.5">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-sm font-medium text-main">{mat.name}</p>
                      <Badge variant={CATEGORY_VARIANT[mat.category] || 'default'}>
                        {mat.category}
                      </Badge>
                      {!mat.isBillable && (
                        <Badge variant="warning">Non-billable</Badge>
                      )}
                    </div>
                    {mat.vendor && (
                      <p className="text-xs text-muted mt-0.5">{mat.vendor}</p>
                    )}
                    <p className="text-xs text-secondary mt-1">
                      {mat.quantity} {mat.unit} x {formatCurrency(mat.unitCost)}
                    </p>
                  </div>
                  <p className="text-sm font-semibold text-main whitespace-nowrap">
                    {formatCurrency(mat.totalCost)}
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
