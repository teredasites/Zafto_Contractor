'use client';

import { useState } from 'react';
import {
  Cpu,
  AlertTriangle,
  Bell,
  Calendar,
  CheckCircle,
  ChevronRight,
  ExternalLink,
  Filter,
  MapPin,
  Search,
  Shield,
  ShieldAlert,
  Wrench,
  Clock,
  User,
  Package,
  ArrowRight,
  RefreshCcw,
  XCircle,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';

type EquipmentStatus = 'healthy' | 'recall_active' | 'maintenance_due' | 'warranty_expiring' | 'end_of_life';

interface InstalledEquipment {
  id: string;
  manufacturer: string;
  model: string;
  serialNumber: string;
  category: string;
  installDate: Date;
  customer: string;
  customerAddress: string;
  status: EquipmentStatus;
  warrantyExpiry: Date;
  alerts: EquipmentAlert[];
  lastServiceDate: Date | null;
  nextServiceDue: Date | null;
  expectedLifespan: number;
  ageYears: number;
}

interface EquipmentAlert {
  type: 'recall' | 'maintenance' | 'warranty' | 'failure_risk' | 'end_of_life';
  title: string;
  description: string;
  severity: 'critical' | 'warning' | 'info';
  actionLabel: string;
  date: Date;
}

const statusConfig: Record<EquipmentStatus, { label: string; color: string; bgColor: string }> = {
  healthy: { label: 'Healthy', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  recall_active: { label: 'Recall Active', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  maintenance_due: { label: 'Maintenance Due', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  warranty_expiring: { label: 'Warranty Expiring', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  end_of_life: { label: 'End of Life', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
};

const mockEquipment: InstalledEquipment[] = [
  {
    id: 'eq1', manufacturer: 'Carrier', model: '24ACC636A003', serialNumber: 'CAR-2023-44891', category: 'HVAC - Central AC',
    installDate: new Date('2023-03-15'), customer: 'Robert Johnson', customerAddress: '123 Oak Ave, Bristol CT',
    status: 'recall_active', warrantyExpiry: new Date('2028-03-15'), lastServiceDate: new Date('2024-09-10'), nextServiceDue: new Date('2025-03-10'),
    expectedLifespan: 15, ageYears: 2,
    alerts: [
      { type: 'recall', title: 'Compressor Recall - Carrier Bulletin CB-2025-003', description: 'Carrier issued recall on 24ACC6 series compressors manufactured Q1 2023. Potential refrigerant leak at high ambient temperatures.', severity: 'critical', actionLabel: 'Contact Customer', date: new Date('2025-01-22') },
    ],
  },
  {
    id: 'eq2', manufacturer: 'Rheem', model: 'PROG50-38N RH67', serialNumber: 'RHM-2022-77234', category: 'Water Heater - Gas 50gal',
    installDate: new Date('2022-06-20'), customer: 'Elena Martinez', customerAddress: '456 Elm St, New Britain CT',
    status: 'maintenance_due', warrantyExpiry: new Date('2028-06-20'), lastServiceDate: new Date('2023-12-05'), nextServiceDue: new Date('2025-01-05'),
    expectedLifespan: 12, ageYears: 3,
    alerts: [
      { type: 'maintenance', title: 'Anode rod service interval', description: 'This unit is 3 years old. Anode rod inspection recommended every 2-3 years to prevent tank corrosion.', severity: 'warning', actionLabel: 'Schedule Service', date: new Date('2025-01-05') },
    ],
  },
  {
    id: 'eq3', manufacturer: 'Eaton', model: 'BR2040B200', serialNumber: 'EAT-2021-55102', category: 'Electrical Panel - 200A',
    installDate: new Date('2021-11-08'), customer: 'David Thompson', customerAddress: '789 Industrial Pkwy, Farmington CT',
    status: 'healthy', warrantyExpiry: new Date('2031-11-08'), lastServiceDate: null, nextServiceDue: null,
    expectedLifespan: 30, ageYears: 4, alerts: [],
  },
  {
    id: 'eq4', manufacturer: 'Trane', model: 'XR15-036', serialNumber: 'TRN-2019-33456', category: 'HVAC - Heat Pump',
    installDate: new Date('2019-10-22'), customer: 'Sarah Wilson', customerAddress: '555 Birch Ln, Windsor CT',
    status: 'warranty_expiring', warrantyExpiry: new Date('2025-10-22'), lastServiceDate: new Date('2024-04-15'), nextServiceDue: new Date('2025-04-15'),
    expectedLifespan: 15, ageYears: 6,
    alerts: [
      { type: 'warranty', title: 'Warranty expires in 8 months', description: 'Trane parts warranty expires October 2025. Consider offering extended service agreement before expiry.', severity: 'warning', actionLabel: 'Offer Service Agreement', date: new Date('2025-10-22') },
    ],
  },
  {
    id: 'eq5', manufacturer: 'AO Smith', model: 'GPVL-50', serialNumber: 'AOS-2014-12890', category: 'Water Heater - Gas 50gal',
    installDate: new Date('2014-08-12'), customer: 'Maria Garcia', customerAddress: '321 Pine St, East Hartford CT',
    status: 'end_of_life', warrantyExpiry: new Date('2020-08-12'), lastServiceDate: new Date('2023-02-28'), nextServiceDue: null,
    expectedLifespan: 12, ageYears: 11,
    alerts: [
      { type: 'end_of_life', title: 'Unit exceeding expected lifespan', description: 'This water heater is 11 years old with a 12-year expected lifespan. Proactively offer replacement before failure. Average emergency replacement costs customer 40% more.', severity: 'info', actionLabel: 'Offer Replacement', date: new Date() },
      { type: 'failure_risk', title: 'High failure probability', description: 'Based on manufacturer data, units of this age and model have a 34% annual failure rate. Replacement recommended.', severity: 'warning', actionLabel: 'Create Bid', date: new Date() },
    ],
  },
  {
    id: 'eq6', manufacturer: 'Generac', model: 'Guardian 22kW', serialNumber: 'GEN-2023-88901', category: 'Generator - Standby',
    installDate: new Date('2023-07-10'), customer: 'James Patterson', customerAddress: '900 Maple Dr, Bloomfield CT',
    status: 'maintenance_due', warrantyExpiry: new Date('2028-07-10'), lastServiceDate: new Date('2024-01-10'), nextServiceDue: new Date('2025-01-10'),
    expectedLifespan: 20, ageYears: 2,
    alerts: [
      { type: 'maintenance', title: 'Annual maintenance overdue', description: 'Generac recommends annual maintenance including oil change, filter replacement, and battery check. Last service was 13 months ago.', severity: 'warning', actionLabel: 'Schedule Service', date: new Date('2025-01-10') },
    ],
  },
];

const stats = {
  totalInstalled: 847,
  activeRecalls: 12,
  maintenanceDue: 38,
  warrantyExpiring: 24,
  revenueOpportunity: 48600,
};

export default function EquipmentMemoryPage() {
  const [selectedEquipment, setSelectedEquipment] = useState<InstalledEquipment | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | EquipmentStatus>('all');

  const filtered = mockEquipment.filter(eq => {
    const matchesSearch = !search || eq.manufacturer.toLowerCase().includes(search.toLowerCase()) || eq.model.toLowerCase().includes(search.toLowerCase()) || eq.customer.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || eq.status === statusFilter;
    return matchesSearch && matchesStatus;
  });
  const sorted = [...filtered].sort((a, b) => {
    const order: Record<EquipmentStatus, number> = { recall_active: 0, maintenance_due: 1, warranty_expiring: 2, end_of_life: 3, healthy: 4 };
    return order[a.status] - order[b.status];
  });

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
              <Cpu className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Equipment Memory</h1>
              <p className="text-sm text-muted-foreground">Recall tracking, lifecycle intelligence, and service revenue generation</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-5 gap-3">
          {[
            { label: 'Total Installed', value: stats.totalInstalled.toString(), icon: Package, urgent: false },
            { label: 'Active Recalls', value: stats.activeRecalls.toString(), icon: ShieldAlert, urgent: true },
            { label: 'Maintenance Due', value: stats.maintenanceDue.toString(), icon: Wrench, urgent: false },
            { label: 'Warranty Expiring', value: stats.warrantyExpiring.toString(), icon: Shield, urgent: false },
            { label: 'Revenue Opportunity', value: `$${(stats.revenueOpportunity / 1000).toFixed(1)}K`, icon: Clock, urgent: false },
          ].map(s => {
            const Icon = s.icon;
            return (
              <Card key={s.label} className={s.urgent ? 'border-red-200 dark:border-red-800' : ''}>
                <CardContent className="p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-xs text-muted-foreground">{s.label}</p>
                      <p className={cn('text-2xl font-semibold mt-0.5', s.urgent ? 'text-red-500' : '')}>{s.value}</p>
                    </div>
                    <Icon className={cn('w-4 h-4', s.urgent ? 'text-red-500' : 'text-muted-foreground')} />
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Search + Filter */}
        <div className="flex items-center gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input placeholder="Search by manufacturer, model, or customer..." value={search} onChange={e => setSearch(e.target.value)} className="pl-9" />
          </div>
          <div className="flex items-center gap-1">
            {(['all', 'recall_active', 'maintenance_due', 'warranty_expiring', 'end_of_life', 'healthy'] as const).map(f => (
              <Button key={f} variant={statusFilter === f ? 'default' : 'outline'} size="sm" onClick={() => setStatusFilter(f)}>
                {f === 'all' ? 'All' : statusConfig[f as EquipmentStatus].label}
              </Button>
            ))}
          </div>
        </div>

        {/* Equipment list + detail */}
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <div className="lg:col-span-3 space-y-3">
            {sorted.map(eq => {
              const status = statusConfig[eq.status];
              return (
                <Card key={eq.id} className={cn('cursor-pointer transition-all hover:shadow-md', selectedEquipment?.id === eq.id && 'ring-2 ring-primary', eq.status === 'recall_active' && 'border-red-200 dark:border-red-800')} onClick={() => setSelectedEquipment(eq)}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <p className="text-sm font-medium">{eq.manufacturer} {eq.model}</p>
                        <p className="text-xs text-muted-foreground">{eq.category} &middot; SN: {eq.serialNumber}</p>
                      </div>
                      <Badge className={cn('text-xs', status.bgColor, status.color)}>{status.label}</Badge>
                    </div>
                    <div className="flex items-center gap-4 text-xs text-muted-foreground mb-2">
                      <span className="flex items-center gap-1"><User className="w-3 h-3" /> {eq.customer}</span>
                      <span className="flex items-center gap-1"><MapPin className="w-3 h-3" /> {eq.customerAddress.split(',')[0]}</span>
                      <span className="flex items-center gap-1"><Calendar className="w-3 h-3" /> Installed {formatDate(eq.installDate)}</span>
                    </div>
                    {eq.alerts.length > 0 && (
                      <div className="space-y-1 mt-2">
                        {eq.alerts.map((alert, i) => (
                          <div key={i} className={cn('flex items-center justify-between p-2 rounded-md text-xs', alert.severity === 'critical' ? 'bg-red-50 dark:bg-red-950/20 text-red-700 dark:text-red-300' : alert.severity === 'warning' ? 'bg-amber-50 dark:bg-amber-950/20 text-amber-700 dark:text-amber-300' : 'bg-blue-50 dark:bg-blue-950/20 text-blue-700 dark:text-blue-300')}>
                            <div className="flex items-center gap-1.5">
                              <AlertTriangle className="w-3 h-3 shrink-0" />
                              <span className="font-medium">{alert.title}</span>
                            </div>
                            <Button variant="ghost" size="sm" className="h-6 text-xs">{alert.actionLabel} <ArrowRight className="w-3 h-3 ml-1" /></Button>
                          </div>
                        ))}
                      </div>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {/* Detail */}
          <div className="lg:col-span-2">
            {selectedEquipment ? (
              <Card className="sticky top-6">
                <CardHeader className="pb-3">
                  <CardTitle className="text-base">{selectedEquipment.manufacturer} {selectedEquipment.model}</CardTitle>
                  <p className="text-xs text-muted-foreground">{selectedEquipment.category}</p>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-3">
                    {[
                      { label: 'Serial Number', value: selectedEquipment.serialNumber },
                      { label: 'Install Date', value: formatDate(selectedEquipment.installDate) },
                      { label: 'Age', value: `${selectedEquipment.ageYears} years` },
                      { label: 'Expected Lifespan', value: `${selectedEquipment.expectedLifespan} years` },
                      { label: 'Warranty Expires', value: formatDate(selectedEquipment.warrantyExpiry) },
                      { label: 'Last Service', value: selectedEquipment.lastServiceDate ? formatDate(selectedEquipment.lastServiceDate) : 'None' },
                    ].map(item => (
                      <div key={item.label} className="text-xs">
                        <p className="text-muted-foreground">{item.label}</p>
                        <p className="font-medium mt-0.5">{item.value}</p>
                      </div>
                    ))}
                  </div>

                  {/* Lifespan bar */}
                  <div className="p-3 rounded-lg bg-muted/40">
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-muted-foreground">Lifecycle Position</span>
                      <span className="font-medium">{Math.round((selectedEquipment.ageYears / selectedEquipment.expectedLifespan) * 100)}%</span>
                    </div>
                    <div className="h-2 rounded-full bg-muted overflow-hidden">
                      <div className={cn('h-full rounded-full', selectedEquipment.ageYears / selectedEquipment.expectedLifespan > 0.8 ? 'bg-red-500' : selectedEquipment.ageYears / selectedEquipment.expectedLifespan > 0.5 ? 'bg-amber-500' : 'bg-emerald-500')} style={{ width: `${Math.min((selectedEquipment.ageYears / selectedEquipment.expectedLifespan) * 100, 100)}%` }} />
                    </div>
                  </div>

                  {/* Customer info */}
                  <div className="p-3 rounded-lg border border-border/60">
                    <p className="text-xs text-muted-foreground mb-1">Customer</p>
                    <p className="text-sm font-medium">{selectedEquipment.customer}</p>
                    <p className="text-xs text-muted-foreground">{selectedEquipment.customerAddress}</p>
                  </div>

                  {/* Actions */}
                  <div className="space-y-2">
                    <Button className="w-full" size="sm"><Wrench className="w-3.5 h-3.5 mr-1.5" /> Schedule Service</Button>
                    <Button variant="outline" className="w-full" size="sm"><Bell className="w-3.5 h-3.5 mr-1.5" /> Contact Customer</Button>
                  </div>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-12 text-center">
                  <Cpu className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">Select equipment to view details</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
