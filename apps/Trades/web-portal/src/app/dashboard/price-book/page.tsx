'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  DollarSign,
  Clock,
  Package,
  Wrench,
  Edit,
  Trash2,
  MoreHorizontal,
  Download,
  Upload,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

type TabType = 'labor' | 'materials' | 'assemblies';

interface LaborRate {
  id: string;
  name: string;
  description?: string;
  rate: number;
  unit: 'hour' | 'day' | 'job';
  category: string;
}

interface Material {
  id: string;
  name: string;
  description?: string;
  cost: number;
  price: number;
  markup: number;
  unit: string;
  category: string;
  sku?: string;
}

interface Assembly {
  id: string;
  name: string;
  description?: string;
  items: { type: 'labor' | 'material'; id: string; quantity: number }[];
  totalCost: number;
  totalPrice: number;
  category: string;
}

// Price book data — will be wired to Supabase when price_book tables are created
const laborRates: LaborRate[] = [];
const materials: Material[] = [];
const assemblies: Assembly[] = [];

export default function PriceBookPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabType>('labor');
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');

  const tabs: { id: TabType; label: string; icon: React.ReactNode; count: number }[] = [
    { id: 'labor', label: 'Labor Rates', icon: <Clock size={16} />, count: laborRates.length },
    { id: 'materials', label: 'Materials', icon: <Package size={16} />, count: materials.length },
    { id: 'assemblies', label: 'Assemblies', icon: <Wrench size={16} />, count: assemblies.length },
  ];

  const laborCategories = [...new Set(laborRates.map((l) => l.category))];
  const materialCategories = [...new Set(materials.map((m) => m.category))];
  const assemblyCategories = [...new Set(assemblies.map((a) => a.category))];

  const currentCategories = activeTab === 'labor' ? laborCategories : activeTab === 'materials' ? materialCategories : assemblyCategories;

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('priceBook.title')}</h1>
          <p className="text-muted mt-1">Manage your labor rates, materials, and assemblies</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary">
            <Upload size={16} />
            Import
          </Button>
          <Button variant="secondary">
            <Download size={16} />
            Export
          </Button>
          <Button>
            <Plus size={16} />
            Add {activeTab === 'labor' ? 'Rate' : activeTab === 'materials' ? 'Material' : 'Assembly'}
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setCategoryFilter('all');
            }}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors',
              activeTab === tab.id
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
            <span className={cn(
              'px-1.5 py-0.5 text-xs rounded-full',
              activeTab === tab.id ? 'bg-accent text-white' : 'bg-main text-muted'
            )}>
              {tab.count}
            </span>
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={`Search ${activeTab}...`}
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Categories' },
            ...currentCategories.map((cat) => ({ value: cat, label: cat })),
          ]}
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Content */}
      {activeTab === 'labor' && (
        <LaborRatesTab rates={laborRates} search={search} categoryFilter={categoryFilter} />
      )}
      {activeTab === 'materials' && (
        <MaterialsTab materials={materials} search={search} categoryFilter={categoryFilter} />
      )}
      {activeTab === 'assemblies' && (
        <AssembliesTab assemblies={assemblies} search={search} categoryFilter={categoryFilter} />
      )}
    </div>
  );
}

function LaborRatesTab({ rates, search, categoryFilter }: { rates: LaborRate[]; search: string; categoryFilter: string }) {
  const { t } = useTranslation();
  const filteredRates = rates.filter((rate) => {
    const matchesSearch = rate.name.toLowerCase().includes(search.toLowerCase()) ||
      rate.description?.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || rate.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  return (
    <Card>
      <CardContent className="p-0">
        {filteredRates.length === 0 ? (
          <div className="py-12 text-center text-muted">
            <Clock size={40} className="mx-auto mb-2 opacity-50" />
            <p>{t('priceBook.noLaborRatesFound')}</p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.name')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.category')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.rate')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.unit')}</th>
                <th className="px-6 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filteredRates.map((rate) => (
                <tr key={rate.id} className="hover:bg-surface-hover">
                  <td className="px-6 py-4">
                    <p className="font-medium text-main">{rate.name}</p>
                    {rate.description && <p className="text-sm text-muted">{rate.description}</p>}
                  </td>
                  <td className="px-6 py-4">
                    <Badge variant="default">{rate.category}</Badge>
                  </td>
                  <td className="px-6 py-4 text-right font-semibold text-main">
                    {formatCurrency(rate.rate)}
                  </td>
                  <td className="px-6 py-4 text-right text-muted capitalize">
                    per {rate.unit}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <ActionMenu />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </CardContent>
    </Card>
  );
}

function MaterialsTab({ materials, search, categoryFilter }: { materials: Material[]; search: string; categoryFilter: string }) {
  const { t } = useTranslation();
  const filteredMaterials = materials.filter((mat) => {
    const matchesSearch = mat.name.toLowerCase().includes(search.toLowerCase()) ||
      mat.description?.toLowerCase().includes(search.toLowerCase()) ||
      mat.sku?.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || mat.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  return (
    <Card>
      <CardContent className="p-0">
        {filteredMaterials.length === 0 ? (
          <div className="py-12 text-center text-muted">
            <Package size={40} className="mx-auto mb-2 opacity-50" />
            <p>{t('priceBook.noMaterialsFound')}</p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.item')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.sku')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.category')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.cost')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.price')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.markup')}</th>
                <th className="px-6 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filteredMaterials.map((mat) => (
                <tr key={mat.id} className="hover:bg-surface-hover">
                  <td className="px-6 py-4">
                    <p className="font-medium text-main">{mat.name}</p>
                    {mat.description && <p className="text-sm text-muted">{mat.description}</p>}
                  </td>
                  <td className="px-6 py-4">
                    <span className="font-mono text-sm text-muted">{mat.sku || '-'}</span>
                  </td>
                  <td className="px-6 py-4">
                    <Badge variant="default">{mat.category}</Badge>
                  </td>
                  <td className="px-6 py-4 text-right text-muted">
                    {formatCurrency(mat.cost)}
                  </td>
                  <td className="px-6 py-4 text-right font-semibold text-main">
                    {formatCurrency(mat.price)}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <span className={cn(
                      'font-medium',
                      mat.markup >= 50 ? 'text-emerald-600' : mat.markup >= 30 ? 'text-amber-600' : 'text-red-600'
                    )}>
                      {mat.markup.toFixed(1)}%
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <ActionMenu />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </CardContent>
    </Card>
  );
}

function AssembliesTab({ assemblies, search, categoryFilter }: { assemblies: Assembly[]; search: string; categoryFilter: string }) {
  const { t } = useTranslation();
  const filteredAssemblies = assemblies.filter((asm) => {
    const matchesSearch = asm.name.toLowerCase().includes(search.toLowerCase()) ||
      asm.description?.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || asm.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  return (
    <Card>
      <CardContent className="p-0">
        {filteredAssemblies.length === 0 ? (
          <div className="py-12 text-center text-muted">
            <Wrench size={40} className="mx-auto mb-2 opacity-50" />
            <p>{t('priceBook.noAssembliesFound')}</p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('priceBook.assembly')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.category')}</th>
                <th className="text-center text-xs font-medium text-muted uppercase px-6 py-3">{t('common.items')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.cost')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.price')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.margin')}</th>
                <th className="px-6 py-3"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filteredAssemblies.map((asm) => {
                const margin = ((asm.totalPrice - asm.totalCost) / asm.totalPrice * 100);
                return (
                  <tr key={asm.id} className="hover:bg-surface-hover">
                    <td className="px-6 py-4">
                      <p className="font-medium text-main">{asm.name}</p>
                      {asm.description && <p className="text-sm text-muted">{asm.description}</p>}
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant="default">{asm.category}</Badge>
                    </td>
                    <td className="px-6 py-4 text-center text-muted">
                      {asm.items.length}
                    </td>
                    <td className="px-6 py-4 text-right text-muted">
                      {formatCurrency(asm.totalCost)}
                    </td>
                    <td className="px-6 py-4 text-right font-semibold text-main">
                      {formatCurrency(asm.totalPrice)}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <span className={cn(
                        'font-medium',
                        margin >= 40 ? 'text-emerald-600' : margin >= 25 ? 'text-amber-600' : 'text-red-600'
                      )}>
                        {margin.toFixed(1)}%
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <ActionMenu />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </CardContent>
    </Card>
  );
}

function ActionMenu() {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <button
        onClick={(e) => {
          e.stopPropagation();
          setOpen(!open);
        }}
        className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
      >
        <MoreHorizontal size={18} className="text-muted" />
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-full mt-1 w-40 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
            <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
              <Edit size={14} />
              Edit
            </button>
            <button className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
              <Trash2 size={14} />
              Delete
            </button>
          </div>
        </>
      )}
    </div>
  );
}
