'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useDraftRecovery } from '@/lib/hooks/use-draft-recovery';
import {
  ArrowLeft,
  Building2,
  DollarSign,
  CreditCard,
  Shield,
  FileText,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Select } from '@/components/ui/input';
import { useProperties } from '@/lib/hooks/use-properties';
import { propertyTypeLabels } from '@/lib/hooks/pm-mappers';
import type { PropertyData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

export default function NewPropertyPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { createProperty } = useProperties();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [form, setForm] = useState({
    addressLine1: '',
    addressLine2: '',
    city: '',
    state: '',
    zip: '',
    propertyType: 'single_family' as PropertyData['propertyType'],
    status: 'active' as PropertyData['status'],
    yearBuilt: '',
    squareFootage: '',
    lotSize: '',
    purchaseDate: '',
    purchasePrice: '',
    currentValue: '',
    mortgageLender: '',
    mortgageRate: '',
    mortgagePayment: '',
    mortgageEscrow: '',
    mortgagePrincipalBalance: '',
    insuranceCarrier: '',
    insurancePolicyNumber: '',
    insurancePremium: '',
    insuranceExpiry: '',
    propertyTaxAnnual: '',
    notes: '',
  });

  // Draft recovery — auto-save property form
  const draftRecovery = useDraftRecovery({
    feature: 'form',
    key: 'new-property',
    screenRoute: '/dashboard/properties/new',
  });

  useEffect(() => {
    if (draftRecovery.hasDraft && !draftRecovery.checking) {
      const restored = draftRecovery.restoreDraft() as Record<string, unknown> | null;
      if (restored?.form) setForm(restored.form as typeof form);
      draftRecovery.markRecovered();
    }
  }, [draftRecovery.hasDraft, draftRecovery.checking]);

  useEffect(() => {
    draftRecovery.saveDraft({ form });
  }, [form]);

  const handleChange = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!form.addressLine1 || !form.city || !form.state || !form.zip) {
      setError('Address, city, state, and ZIP are required.');
      return;
    }

    try {
      setSaving(true);
      await createProperty({
        addressLine1: form.addressLine1,
        addressLine2: form.addressLine2 || null,
        city: form.city,
        state: form.state,
        zip: form.zip,
        propertyType: form.propertyType,
        status: form.status,
        yearBuilt: form.yearBuilt ? Number(form.yearBuilt) : null,
        squareFootage: form.squareFootage ? Number(form.squareFootage) : null,
        lotSize: form.lotSize || null,
        purchaseDate: form.purchaseDate || null,
        purchasePrice: form.purchasePrice ? Number(form.purchasePrice) : null,
        currentValue: form.currentValue ? Number(form.currentValue) : null,
        mortgageLender: form.mortgageLender || null,
        mortgageRate: form.mortgageRate ? Number(form.mortgageRate) : null,
        mortgagePayment: form.mortgagePayment ? Number(form.mortgagePayment) : null,
        mortgageEscrow: form.mortgageEscrow ? Number(form.mortgageEscrow) : null,
        mortgagePrincipalBalance: form.mortgagePrincipalBalance ? Number(form.mortgagePrincipalBalance) : null,
        insuranceCarrier: form.insuranceCarrier || null,
        insurancePolicyNumber: form.insurancePolicyNumber || null,
        insurancePremium: form.insurancePremium ? Number(form.insurancePremium) : null,
        insuranceExpiry: form.insuranceExpiry || null,
        propertyTaxAnnual: form.propertyTaxAnnual ? Number(form.propertyTaxAnnual) : null,
        notes: form.notes || null,
      });
      router.push('/dashboard/properties');
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to create property';
      setError(msg);
    } finally {
      setSaving(false);
    }
  };

  const inputClass =
    'w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent';

  return (
    <div className="space-y-6 pb-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => router.back()}
          className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
        >
          <ArrowLeft size={20} className="text-muted" />
        </button>
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('propertiesNew.title')}</h1>
          <p className="text-[13px] text-muted mt-1">Add a new property to your portfolio</p>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg px-4 py-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Property Info */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Building2 size={18} className="text-muted" />
              Property Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Address Line 1 *</label>
              <input
                type="text"
                value={form.addressLine1}
                onChange={(e) => handleChange('addressLine1', e.target.value)}
                placeholder="123 Main Street"
                className={inputClass}
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Address Line 2</label>
              <input
                type="text"
                value={form.addressLine2}
                onChange={(e) => handleChange('addressLine2', e.target.value)}
                placeholder="Suite, Apt, Unit..."
                className={inputClass}
              />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">City *</label>
                <input
                  type="text"
                  value={form.city}
                  onChange={(e) => handleChange('city', e.target.value)}
                  placeholder="Hartford"
                  className={inputClass}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">State *</label>
                <input
                  type="text"
                  value={form.state}
                  onChange={(e) => handleChange('state', e.target.value)}
                  placeholder="CT"
                  className={inputClass}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">ZIP *</label>
                <input
                  type="text"
                  value={form.zip}
                  onChange={(e) => handleChange('zip', e.target.value)}
                  placeholder="06103"
                  className={inputClass}
                  required
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <Select
                label="Property Type"
                value={form.propertyType}
                onChange={(e) => handleChange('propertyType', e.target.value)}
                options={Object.entries(propertyTypeLabels).map(([value, label]) => ({ value, label }))}
              />
              <Select
                label="Status"
                value={form.status}
                onChange={(e) => handleChange('status', e.target.value)}
                options={[
                  { value: 'active', label: 'Active' },
                  { value: 'inactive', label: 'Inactive' },
                  { value: 'rehab', label: 'Rehab' },
                ]}
              />
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Year Built</label>
                <input
                  type="number"
                  value={form.yearBuilt}
                  onChange={(e) => handleChange('yearBuilt', e.target.value)}
                  placeholder="2000"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.squareFootage')}</label>
                <input
                  type="number"
                  value={form.squareFootage}
                  onChange={(e) => handleChange('squareFootage', e.target.value)}
                  placeholder="2400"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Lot Size</label>
                <input
                  type="text"
                  value={form.lotSize}
                  onChange={(e) => handleChange('lotSize', e.target.value)}
                  placeholder="0.25 acres"
                  className={inputClass}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Financial */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <DollarSign size={18} className="text-muted" />
              Financial
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Purchase Date</label>
                <input
                  type="date"
                  value={form.purchaseDate}
                  onChange={(e) => handleChange('purchaseDate', e.target.value)}
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Purchase Price</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.purchasePrice}
                  onChange={(e) => handleChange('purchasePrice', e.target.value)}
                  placeholder="250000"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Current Value</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.currentValue}
                  onChange={(e) => handleChange('currentValue', e.target.value)}
                  placeholder="300000"
                  className={inputClass}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Mortgage */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <CreditCard size={18} className="text-muted" />
              Mortgage
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Lender</label>
                <input
                  type="text"
                  value={form.mortgageLender}
                  onChange={(e) => handleChange('mortgageLender', e.target.value)}
                  placeholder="Bank of America"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Interest Rate (%)</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.mortgageRate}
                  onChange={(e) => handleChange('mortgageRate', e.target.value)}
                  placeholder="6.5"
                  className={inputClass}
                />
              </div>
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Monthly Payment</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.mortgagePayment}
                  onChange={(e) => handleChange('mortgagePayment', e.target.value)}
                  placeholder="1500"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Escrow</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.mortgageEscrow}
                  onChange={(e) => handleChange('mortgageEscrow', e.target.value)}
                  placeholder="350"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Principal Balance</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.mortgagePrincipalBalance}
                  onChange={(e) => handleChange('mortgagePrincipalBalance', e.target.value)}
                  placeholder="200000"
                  className={inputClass}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Insurance */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Shield size={18} className="text-muted" />
              Insurance
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.carrier')}</label>
                <input
                  type="text"
                  value={form.insuranceCarrier}
                  onChange={(e) => handleChange('insuranceCarrier', e.target.value)}
                  placeholder="State Farm"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Policy Number</label>
                <input
                  type="text"
                  value={form.insurancePolicyNumber}
                  onChange={(e) => handleChange('insurancePolicyNumber', e.target.value)}
                  placeholder="POL-123456"
                  className={inputClass}
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Annual Premium</label>
                <input
                  type="number"
                  step="0.01"
                  value={form.insurancePremium}
                  onChange={(e) => handleChange('insurancePremium', e.target.value)}
                  placeholder="2400"
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Expiry Date</label>
                <input
                  type="date"
                  value={form.insuranceExpiry}
                  onChange={(e) => handleChange('insuranceExpiry', e.target.value)}
                  className={inputClass}
                />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Tax */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Property Tax</CardTitle>
          </CardHeader>
          <CardContent>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Annual Property Tax</label>
              <input
                type="number"
                step="0.01"
                value={form.propertyTaxAnnual}
                onChange={(e) => handleChange('propertyTaxAnnual', e.target.value)}
                placeholder="3600"
                className={inputClass}
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
              value={form.notes}
              onChange={(e) => handleChange('notes', e.target.value)}
              placeholder="Any notes about this property..."
              className="w-full px-3 py-2 bg-surface border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent resize-none"
              rows={4}
            />
          </CardContent>
        </Card>

        {/* Actions */}
        <div className="flex items-center gap-3">
          <Button type="submit" disabled={saving} loading={saving}>
            {saving ? 'Creating Property...' : 'Create Property'}
          </Button>
          <Button type="button" variant="secondary" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
