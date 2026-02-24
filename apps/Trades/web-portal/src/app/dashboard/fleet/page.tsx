'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  Truck,
  Wrench,
  Fuel,
  MapPin,
  ChevronDown,
  ChevronRight,
  Clock,
  DollarSign,
  AlertTriangle,
  Activity,
  ClipboardCheck,
  Calendar,
  Gauge,
  Shield,
  FileText,
  TrendingUp,
  TrendingDown,
  CircleAlert,
  CheckCircle2,
  XCircle,
  Eye,
  Car,
  User,
  Hash,
  BarChart3,
  CircleDot,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { formatDate, formatRelativeTime, cn } from '@/lib/utils';
import {
  useFleet,
  type Vehicle,
  type VehicleMaintenance,
  type FuelLog,
  type VehicleStatus,
  type MaintenanceStatus,
} from '@/lib/hooks/use-fleet';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

// ────────────────────────────────────────────────────────
// Tab types
// ────────────────────────────────────────────────────────

type FleetTab = 'vehicles' | 'maintenance' | 'fuel' | 'inspections';

// ────────────────────────────────────────────────────────
// Status config
// ────────────────────────────────────────────────────────

const vehicleStatusConfig: Record<VehicleStatus, { label: string; variant: 'success' | 'warning' | 'error' | 'secondary' }> = {
  active: { label: 'Active', variant: 'success' },
  maintenance: { label: 'Maintenance', variant: 'warning' },
  out_of_service: { label: 'Out of Service', variant: 'error' },
  retired: { label: 'Retired', variant: 'secondary' },
};

const maintenanceStatusConfig: Record<MaintenanceStatus, { label: string; variant: 'info' | 'warning' | 'success' | 'secondary' }> = {
  scheduled: { label: 'Scheduled', variant: 'info' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'secondary' },
};

const vehicleTypeLabels: Record<string, string> = {
  truck: 'Truck',
  van: 'Van',
  trailer: 'Trailer',
  car: 'Car',
  equipment: 'Equipment',
  other: 'Other',
};

const maintenanceTypeLabels: Record<string, string> = {
  oil_change: 'Oil Change',
  tire_rotation: 'Tire Rotation',
  brake_service: 'Brake Service',
  inspection: 'Inspection',
  engine: 'Engine',
  transmission: 'Transmission',
  electrical: 'Electrical',
  body: 'Body',
  scheduled_service: 'Scheduled Service',
  other: 'Other',
};

const priorityConfig: Record<string, { label: string; variant: 'secondary' | 'info' | 'warning' | 'error' }> = {
  low: { label: 'Low', variant: 'secondary' },
  medium: { label: 'Medium', variant: 'info' },
  high: { label: 'High', variant: 'warning' },
  critical: { label: 'Critical', variant: 'error' },
};

const DOT_CHECKLIST_ITEMS = [
  'Engine oil level',
  'Coolant level',
  'Brake fluid level',
  'Power steering fluid',
  'Windshield washer fluid',
  'Tire condition & pressure (all)',
  'Lug nuts tight',
  'Headlights (high/low)',
  'Tail lights',
  'Brake lights',
  'Turn signals (front/rear)',
  'Hazard lights',
  'Backup lights',
  'License plate light',
  'Horn',
  'Windshield wipers',
  'Mirrors (both sides)',
  'Windshield (no cracks)',
  'Seat belts',
  'Parking brake',
  'Service brake test',
  'Steering play',
  'Exhaust system',
  'Fire extinguisher',
  'First aid kit',
  'Reflective triangles/flares',
];

// ────────────────────────────────────────────────────────
// Main Page
// ────────────────────────────────────────────────────────

export default function FleetPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<FleetTab>('vehicles');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedVehicle, setExpandedVehicle] = useState<string | null>(null);
  const [maintenanceFilter, setMaintenanceFilter] = useState<'all' | 'overdue' | 'due_soon' | 'upcoming'>('all');
  const [fuelVehicleFilter, setFuelVehicleFilter] = useState('all');
  const [inspectionFilter, setInspectionFilter] = useState<'all' | 'pass' | 'fail' | 'missing'>('all');

  const {
    vehicles,
    maintenance,
    fuelLogs,
    loading,
    activeVehicles,
    maintenanceDue,
    totalFleetCost,
  } = useFleet();

  // ── Stats ──
  const inMaintenanceCount = vehicles.filter((v) => v.status === 'maintenance').length;
  const fuelSpendMTD = useMemo(() => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
    return fuelLogs
      .filter((f) => f.fuelDate >= monthStart)
      .reduce((sum, f) => sum + f.totalCost, 0);
  }, [fuelLogs]);

  // ── Vehicle filtering ──
  const filteredVehicles = useMemo(() => {
    return vehicles.filter((v) => {
      const matchesSearch =
        v.vehicleName.toLowerCase().includes(search.toLowerCase()) ||
        (v.make || '').toLowerCase().includes(search.toLowerCase()) ||
        (v.model || '').toLowerCase().includes(search.toLowerCase()) ||
        (v.licensePlate || '').toLowerCase().includes(search.toLowerCase()) ||
        (v.vin || '').toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || v.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [vehicles, search, statusFilter]);

  // ── Build maintenance schedule from hook data ──
  const maintenanceSchedule = useMemo(() => {
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const thirtyDaysOut = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const vehicleMap = new Map(vehicles.map((v) => [v.id, v]));

    return maintenance
      .filter((m) => m.status === 'scheduled' || m.status === 'in_progress')
      .map((m) => {
        const vehicle = vehicleMap.get(m.vehicleId);
        const currentMileage = vehicle?.currentOdometer ?? 0;

        let status: 'overdue' | 'due_soon' | 'upcoming' = 'upcoming';
        if (m.scheduledDate && m.scheduledDate < todayStr) {
          status = 'overdue';
        } else if (m.nextDueOdometer != null && currentMileage >= m.nextDueOdometer) {
          status = 'overdue';
        } else if (m.scheduledDate && m.scheduledDate <= thirtyDaysOut) {
          status = 'due_soon';
        } else if (m.nextDueOdometer != null && m.nextDueOdometer - currentMileage <= 1000) {
          status = 'due_soon';
        }

        let triggerType: 'mileage' | 'date' | 'both' = 'date';
        if (m.scheduledDate && m.nextDueOdometer != null) triggerType = 'both';
        else if (m.nextDueOdometer != null) triggerType = 'mileage';

        return {
          id: m.id,
          vehicleName: vehicle?.vehicleName ?? 'Unknown Vehicle',
          serviceType: maintenanceTypeLabels[m.maintenanceType] || m.title,
          triggerType,
          nextDueDate: m.scheduledDate || m.nextDueDate,
          nextDueMileage: m.nextDueOdometer,
          currentMileage,
          lastServiceDate: m.completedDate,
          status,
        };
      })
      .sort((a, b) => {
        const order = { overdue: 0, due_soon: 1, upcoming: 2 };
        return order[a.status] - order[b.status];
      });
  }, [maintenance, vehicles]);

  // ── Maintenance schedule filtering ──
  const filteredSchedule = useMemo(() => {
    if (maintenanceFilter === 'all') return maintenanceSchedule;
    return maintenanceSchedule.filter((m) => m.status === maintenanceFilter);
  }, [maintenanceFilter, maintenanceSchedule]);

  // ── Fuel log entries with computed MPG ──
  const fuelEntriesWithMpg = useMemo(() => {
    const vehicleMap = new Map(vehicles.map((v) => [v.id, v]));
    const sortedByVehicleAndDate = [...fuelLogs].sort((a, b) => {
      if (a.vehicleId !== b.vehicleId) return a.vehicleId.localeCompare(b.vehicleId);
      return a.fuelDate.localeCompare(b.fuelDate);
    });

    const mpgMap = new Map<string, number | null>();
    let prevByVehicle = new Map<string, FuelLog>();

    for (const entry of sortedByVehicleAndDate) {
      const prev = prevByVehicle.get(entry.vehicleId);
      if (prev && prev.odometer != null && entry.odometer != null && entry.gallons > 0) {
        const milesDriven = entry.odometer - prev.odometer;
        if (milesDriven > 0) {
          mpgMap.set(entry.id, Math.round((milesDriven / entry.gallons) * 10) / 10);
        } else {
          mpgMap.set(entry.id, null);
        }
      } else {
        mpgMap.set(entry.id, null);
      }
      prevByVehicle.set(entry.vehicleId, entry);
    }

    return fuelLogs.map((f) => {
      const vehicle = vehicleMap.get(f.vehicleId);
      const mpg = mpgMap.get(f.id) ?? null;
      const avgMpgForVehicle = fuelLogs
        .filter((fl) => fl.vehicleId === f.vehicleId)
        .reduce<number[]>((acc, fl) => {
          const m = mpgMap.get(fl.id);
          if (m != null) acc.push(m);
          return acc;
        }, []);
      const vehicleAvg = avgMpgForVehicle.length > 0
        ? avgMpgForVehicle.reduce((s, v) => s + v, 0) / avgMpgForVehicle.length
        : null;
      const anomaly = mpg != null && vehicleAvg != null && mpg < vehicleAvg * 0.6;

      return {
        id: f.id,
        vehicleId: f.vehicleId,
        vehicleName: vehicle?.vehicleName ?? 'Unknown Vehicle',
        fuelDate: f.fuelDate,
        gallons: f.gallons,
        pricePerGallon: f.pricePerGallon,
        totalCost: f.totalCost,
        odometer: f.odometer,
        stationName: f.stationName ?? '',
        fuelType: f.fuelType,
        mpg,
        anomaly,
      };
    });
  }, [fuelLogs, vehicles]);

  // ── Fuel log filtering ──
  const filteredFuel = useMemo(() => {
    if (fuelVehicleFilter === 'all') return fuelEntriesWithMpg;
    return fuelEntriesWithMpg.filter((f) => f.vehicleName === fuelVehicleFilter);
  }, [fuelVehicleFilter, fuelEntriesWithMpg]);

  const fuelStats = useMemo(() => {
    if (filteredFuel.length === 0) return { avgMpg: 0, avgCostPerGal: 0, totalSpent: 0, anomalyCount: 0 };
    const withMpg = filteredFuel.filter((e) => e.mpg !== null);
    const avgMpg = withMpg.length > 0 ? withMpg.reduce((s, e) => s + (e.mpg || 0), 0) / withMpg.length : 0;
    const avgCostPerGal = filteredFuel.reduce((s, e) => s + e.pricePerGallon, 0) / filteredFuel.length;
    const totalSpent = filteredFuel.reduce((s, e) => s + e.totalCost, 0);
    const anomalyCount = filteredFuel.filter((e) => e.anomaly).length;
    return { avgMpg, avgCostPerGal, totalSpent, anomalyCount };
  }, [filteredFuel]);

  // ── Build inspection records from maintenance items of type 'inspection' ──
  const inspectionRecords = useMemo(() => {
    const vehicleMap = new Map(vehicles.map((v) => [v.id, v]));
    return maintenance
      .filter((m) => m.maintenanceType === 'inspection')
      .map((m) => {
        const vehicle = vehicleMap.get(m.vehicleId);
        const isCompleted = m.status === 'completed';
        const isCancelled = m.status === 'cancelled';
        let result: 'pass' | 'fail' | 'missing' = 'missing';
        if (isCompleted) {
          const hasDefects = m.notes && m.notes.toLowerCase().includes('fail');
          result = hasDefects ? 'fail' : 'pass';
        } else if (!isCancelled) {
          result = 'missing';
        }

        const defects: string[] = [];
        if (m.description && result === 'fail') {
          defects.push(...m.description.split('\n').filter(Boolean));
        }

        const totalItems = DOT_CHECKLIST_ITEMS.length;
        const itemsFailed = defects.length;
        const itemsPassed = totalItems - itemsFailed;

        return {
          id: m.id,
          vehicleName: vehicle?.vehicleName ?? 'Unknown Vehicle',
          inspectorName: m.completedByUserId ? m.completedByUserId.slice(0, 8) + '...' : 'Unassigned',
          inspectionDate: m.completedDate || m.scheduledDate || m.createdAt,
          result,
          itemsPassed,
          itemsFailed,
          totalItems,
          defects,
          notes: m.notes,
        };
      })
      .sort((a, b) => (b.inspectionDate || '').localeCompare(a.inspectionDate || ''));
  }, [maintenance, vehicles]);

  // ── Inspection filtering ──
  const filteredInspections = useMemo(() => {
    if (inspectionFilter === 'all') return inspectionRecords;
    return inspectionRecords.filter((i) => i.result === inspectionFilter);
  }, [inspectionFilter, inspectionRecords]);

  const inspectionStats = useMemo(() => {
    const total = inspectionRecords.length;
    const passed = inspectionRecords.filter((i) => i.result === 'pass').length;
    const failed = inspectionRecords.filter((i) => i.result === 'fail').length;
    const missing = inspectionRecords.filter((i) => i.result === 'missing').length;
    return { total, passed, failed, missing, passRate: total > 0 ? (passed / total) * 100 : 0 };
  }, [inspectionRecords]);

  // ── Helpers to get related data ──
  const getMaintenanceForVehicle = (vehicleId: string) =>
    maintenance.filter((m) => m.vehicleId === vehicleId);

  const getFuelLogsForVehicle = (vehicleId: string) =>
    fuelLogs.filter((f) => f.vehicleId === vehicleId);

  // ── Unique vehicle names for fuel filter ──
  const uniqueFuelVehicles = useMemo(() => {
    const vehicleMap = new Map(vehicles.map((v) => [v.id, v]));
    const names = [...new Set(fuelLogs.map((f) => vehicleMap.get(f.vehicleId)?.vehicleName).filter(Boolean))] as string[];
    return names.sort();
  }, [fuelLogs, vehicles]);

  // ── Overdue / due soon counts from computed schedule ──
  const overdueCount = useMemo(() => maintenanceSchedule.filter((m) => m.status === 'overdue').length, [maintenanceSchedule]);
  const dueSoonCount = useMemo(() => maintenanceSchedule.filter((m) => m.status === 'due_soon').length, [maintenanceSchedule]);

  // ── Missing inspection alerts: vehicles with no inspection-type maintenance completed today ──
  const missingInspectionAlerts = useMemo(() => {
    const todayStr = new Date().toISOString().split('T')[0];
    return vehicles
      .filter((v) => v.status === 'active')
      .filter((v) => {
        const latestInspection = maintenance
          .filter((m) => m.vehicleId === v.id && m.maintenanceType === 'inspection' && m.status === 'completed')
          .sort((a, b) => (b.completedDate || '').localeCompare(a.completedDate || ''))[0];
        if (!latestInspection || !latestInspection.completedDate) return true;
        return latestInspection.completedDate.split('T')[0] < todayStr;
      })
      .map((v) => {
        const latestInspection = maintenance
          .filter((m) => m.vehicleId === v.id && m.maintenanceType === 'inspection' && m.status === 'completed')
          .sort((a, b) => (b.completedDate || '').localeCompare(a.completedDate || ''))[0];
        const lastDate = latestInspection?.completedDate?.split('T')[0] || null;
        const daysMissing = lastDate
          ? Math.floor((new Date().getTime() - new Date(lastDate).getTime()) / (1000 * 60 * 60 * 24))
          : null;
        return {
          vehicle: v.vehicleName,
          lastInspection: lastDate,
          daysMissing: daysMissing ?? 0,
        };
      });
  }, [vehicles, maintenance]);

  // ── Tab definitions ──
  const tabs: { key: FleetTab; label: string; icon: React.ReactNode; count?: number }[] = [
    { key: 'vehicles', label: 'Vehicles', icon: <Truck size={16} />, count: vehicles.length },
    { key: 'maintenance', label: 'Maintenance', icon: <Wrench size={16} />, count: overdueCount > 0 ? overdueCount : undefined },
    { key: 'fuel', label: 'Fuel Log', icon: <Fuel size={16} /> },
    { key: 'inspections', label: 'Inspections', icon: <ClipboardCheck size={16} />, count: inspectionStats.failed > 0 ? inspectionStats.failed : undefined },
  ];

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('fleet.title')}</h1>
          <p className="text-muted mt-1">{t('fleet.manageDesc')}</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary"><Fuel size={16} />{t('fleet.logFuel')}</Button>
          <Button variant="secondary"><Wrench size={16} />{t('fleet.scheduleMaintenance')}</Button>
          <Button><Plus size={16} />{t('fleet.newVehicle')}</Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Truck size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{vehicles.length}</p>
                <p className="text-sm text-muted">{t('fleet.totalVehicles')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Activity size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeVehicles.length}</p>
                <p className="text-sm text-muted">{t('common.active')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Wrench size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{inMaintenanceCount}</p>
                <p className="text-sm text-muted">{t('fleet.inMaintenance')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <DollarSign size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(fuelSpendMTD)}</p>
                <p className="text-sm text-muted">{t('fleet.fuelSpendMTD')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-main">
        <nav className="flex gap-0 -mb-px">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-5 py-3 text-sm font-medium border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-brand text-brand'
                  : 'border-transparent text-muted hover:text-main hover:border-main'
              )}
            >
              {tab.icon}
              {tab.label}
              {tab.count !== undefined && tab.count > 0 && (
                <span className={cn(
                  'ml-1 text-xs font-semibold px-1.5 py-0.5 rounded-full',
                  activeTab === tab.key
                    ? 'bg-brand/20 text-brand'
                    : tab.key === 'maintenance' || tab.key === 'inspections'
                      ? 'bg-red-500/20 text-red-400'
                      : 'bg-secondary text-muted'
                )}>
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'vehicles' && (
        <VehiclesTab
          vehicles={filteredVehicles}
          search={search}
          setSearch={setSearch}
          statusFilter={statusFilter}
          setStatusFilter={setStatusFilter}
          expandedVehicle={expandedVehicle}
          setExpandedVehicle={setExpandedVehicle}
          getMaintenanceForVehicle={getMaintenanceForVehicle}
          getFuelLogsForVehicle={getFuelLogsForVehicle}
        />
      )}
      {activeTab === 'maintenance' && (
        <MaintenanceTab
          schedule={filteredSchedule}
          history={maintenance}
          maintenanceFilter={maintenanceFilter}
          setMaintenanceFilter={setMaintenanceFilter}
          overdueCount={overdueCount}
          dueSoonCount={dueSoonCount}
          maintenanceDue={maintenanceDue}
          totalScheduled={maintenanceSchedule.length}
        />
      )}
      {activeTab === 'fuel' && (
        <FuelTab
          entries={filteredFuel}
          allEntries={fuelEntriesWithMpg}
          stats={fuelStats}
          vehicleFilter={fuelVehicleFilter}
          setVehicleFilter={setFuelVehicleFilter}
          uniqueVehicles={uniqueFuelVehicles}
        />
      )}
      {activeTab === 'inspections' && (
        <InspectionsTab
          inspections={filteredInspections}
          stats={inspectionStats}
          filter={inspectionFilter}
          setFilter={setInspectionFilter}
          missingAlerts={missingInspectionAlerts}
          activeVehicleCount={activeVehicles.length}
        />
      )}
    </div>
  );
}

// ────────────────────────────────────────────────────────
// TAB 1: Vehicles
// ────────────────────────────────────────────────────────

function VehiclesTab({
  vehicles,
  search,
  setSearch,
  statusFilter,
  setStatusFilter,
  expandedVehicle,
  setExpandedVehicle,
  getMaintenanceForVehicle,
  getFuelLogsForVehicle,
}: {
  vehicles: Vehicle[];
  search: string;
  setSearch: (v: string) => void;
  statusFilter: string;
  setStatusFilter: (v: string) => void;
  expandedVehicle: string | null;
  setExpandedVehicle: (v: string | null) => void;
  getMaintenanceForVehicle: (id: string) => VehicleMaintenance[];
  getFuelLogsForVehicle: (id: string) => FuelLog[];
}) {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('fleet.searchVehicles')}
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'active', label: 'Active' },
            { value: 'maintenance', label: 'Maintenance' },
            { value: 'out_of_service', label: 'Out of Service' },
            { value: 'retired', label: 'Retired' },
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Vehicles Table */}
      <Card>
        <CardContent className="p-0">
          {vehicles.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <Truck size={40} className="mx-auto mb-2 opacity-50" />
              <p>{t('fleet.noVehicles')}</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {/* Table Header */}
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-1" />
                <div className="col-span-2">{t('common.vehicle')}</div>
                <div className="col-span-1">{t('common.type')}</div>
                <div className="col-span-2">{t('common.makeModelYear')}</div>
                <div className="col-span-2">{t('common.assignedTo')}</div>
                <div className="col-span-1">{t('common.status')}</div>
                <div className="col-span-1">{t('common.odometer')}</div>
                <div className="col-span-2">{t('common.lastGps')}</div>
              </div>

              {vehicles.map((vehicle) => {
                const isExpanded = expandedVehicle === vehicle.id;
                const vehicleMaintenance = getMaintenanceForVehicle(vehicle.id);
                const vehicleFuel = getFuelLogsForVehicle(vehicle.id);

                return (
                  <div key={vehicle.id}>
                    <VehicleRow
                      vehicle={vehicle}
                      isExpanded={isExpanded}
                      onToggle={() => setExpandedVehicle(isExpanded ? null : vehicle.id)}
                    />
                    {isExpanded && (
                      <VehicleDetail
                        vehicle={vehicle}
                        maintenance={vehicleMaintenance}
                        fuelLogs={vehicleFuel}
                      />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Vehicle Row
// ────────────────────────────────────────────────────────

function VehicleRow({
  vehicle,
  isExpanded,
  onToggle,
}: {
  vehicle: Vehicle;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const { t } = useTranslation();
  const statusCfg = vehicleStatusConfig[vehicle.status];

  return (
    <div
      className={cn(
        'px-6 py-4 grid grid-cols-12 gap-4 items-center cursor-pointer hover:bg-surface-hover transition-colors',
        isExpanded && 'bg-surface-hover'
      )}
      onClick={onToggle}
    >
      <div className="col-span-1 flex items-center">
        {isExpanded ? (
          <ChevronDown size={16} className="text-muted" />
        ) : (
          <ChevronRight size={16} className="text-muted" />
        )}
      </div>
      <div className="col-span-2">
        <p className="font-medium text-main truncate">{vehicle.vehicleName}</p>
        {vehicle.licensePlate && (
          <p className="text-xs text-muted mt-0.5">{vehicle.licensePlate}</p>
        )}
      </div>
      <div className="col-span-1">
        <span className="text-sm text-muted">{vehicleTypeLabels[vehicle.vehicleType] || vehicle.vehicleType}</span>
      </div>
      <div className="col-span-2">
        <p className="text-sm text-main">
          {[vehicle.make, vehicle.model].filter(Boolean).join(' ') || '--'}
        </p>
        {vehicle.year && <p className="text-xs text-muted">{vehicle.year}</p>}
      </div>
      <div className="col-span-2">
        <p className="text-sm text-muted truncate">
          {vehicle.assignedToUserId ? vehicle.assignedToUserId.slice(0, 8) + '...' : 'Unassigned'}
        </p>
      </div>
      <div className="col-span-1">
        <Badge variant={statusCfg.variant} dot>{statusCfg.label}</Badge>
      </div>
      <div className="col-span-1">
        <p className="text-sm text-main">
          {vehicle.currentOdometer != null
            ? vehicle.currentOdometer.toLocaleString() + ' mi'
            : '--'}
        </p>
      </div>
      <div className="col-span-2">
        {vehicle.lastGpsTimestamp ? (
          <div className="flex items-center gap-1 text-sm text-muted">
            <MapPin size={12} />
            <span>{formatRelativeTime(vehicle.lastGpsTimestamp)}</span>
          </div>
        ) : (
          <span className="text-sm text-muted">{t('common.noGpsData')}</span>
        )}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Expanded Vehicle Detail (with VIN, insurance, registration)
// ────────────────────────────────────────────────────────

function VehicleDetail({
  vehicle,
  maintenance,
  fuelLogs,
}: {
  vehicle: Vehicle;
  maintenance: VehicleMaintenance[];
  fuelLogs: FuelLog[];
}) {
  const { t } = useTranslation();

  const isExpiringSoon = (dateStr: string | null) => {
    if (!dateStr) return false;
    const d = new Date(dateStr);
    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    return d <= thirtyDays;
  };

  const isExpired = (dateStr: string | null) => {
    if (!dateStr) return false;
    return new Date(dateStr) < new Date();
  };

  return (
    <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
      {/* Vehicle Profile Information */}
      <div className="mb-6">
        <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
          <FileText size={14} />
          Vehicle Details
        </h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <DetailField icon={<Hash size={13} />} label="VIN" value={vehicle.vin || 'Not recorded'} />
          <DetailField icon={<Car size={13} />} label="License Plate" value={vehicle.licensePlate || 'Not recorded'} />
          <DetailField icon={<Gauge size={13} />} label="Odometer" value={vehicle.currentOdometer != null ? formatNumber(vehicle.currentOdometer) + ' mi' : 'Not recorded'} />
          <DetailField icon={<User size={13} />} label="Assigned To" value={vehicle.assignedToUserId ? vehicle.assignedToUserId.slice(0, 8) + '...' : 'Unassigned'} />
          <div className="flex items-start gap-2">
            <Shield size={13} className="text-muted mt-0.5 shrink-0" />
            <div>
              <p className="text-xs text-muted">Insurance Policy</p>
              <p className="text-sm text-main">{vehicle.insurancePolicyNumber || 'Not recorded'}</p>
              {vehicle.insuranceExpiry && (
                <div className="flex items-center gap-1 mt-0.5">
                  <p className="text-xs text-muted">Expires: {formatDate(vehicle.insuranceExpiry)}</p>
                  {isExpired(vehicle.insuranceExpiry) && <Badge variant="error" size="sm">Expired</Badge>}
                  {!isExpired(vehicle.insuranceExpiry) && isExpiringSoon(vehicle.insuranceExpiry) && <Badge variant="warning" size="sm">Expiring Soon</Badge>}
                </div>
              )}
            </div>
          </div>
          <div className="flex items-start gap-2">
            <FileText size={13} className="text-muted mt-0.5 shrink-0" />
            <div>
              <p className="text-xs text-muted">Registration</p>
              <p className="text-sm text-main">{vehicle.registrationExpiry ? 'On file' : 'Not recorded'}</p>
              {vehicle.registrationExpiry && (
                <div className="flex items-center gap-1 mt-0.5">
                  <p className="text-xs text-muted">Expires: {formatDate(vehicle.registrationExpiry)}</p>
                  {isExpired(vehicle.registrationExpiry) && <Badge variant="error" size="sm">Expired</Badge>}
                  {!isExpired(vehicle.registrationExpiry) && isExpiringSoon(vehicle.registrationExpiry) && <Badge variant="warning" size="sm">Expiring Soon</Badge>}
                </div>
              )}
            </div>
          </div>
          <DetailField icon={<DollarSign size={13} />} label="Daily Rate" value={vehicle.dailyRate != null ? formatCurrency(vehicle.dailyRate) : 'Not set'} />
          <DetailField icon={<CircleDot size={13} />} label="Color" value={vehicle.color || 'Not recorded'} />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Maintenance History */}
        <div>
          <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
            <Wrench size={14} />
            Maintenance History ({maintenance.length})
          </h4>
          {maintenance.length === 0 ? (
            <p className="text-sm text-muted py-2">{t('common.noMaintenanceRecords')}</p>
          ) : (
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {maintenance.slice(0, 10).map((m) => {
                const statusCfg = maintenanceStatusConfig[m.status];
                return (
                  <div key={m.id} className="flex items-center justify-between p-3 bg-surface border border-main rounded-lg">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-main truncate">{m.title}</p>
                        <Badge variant={statusCfg.variant} size="sm">{statusCfg.label}</Badge>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                        {m.scheduledDate && (
                          <span className="flex items-center gap-1">
                            <Clock size={10} />{formatDate(m.scheduledDate)}
                          </span>
                        )}
                        {m.vendorName && <span>{m.vendorName}</span>}
                        {m.odometerAtService != null && (
                          <span>{formatNumber(m.odometerAtService)} mi</span>
                        )}
                      </div>
                    </div>
                    {m.totalCost != null && m.totalCost > 0 && (
                      <p className="text-sm font-medium text-main ml-4">{formatCurrency(m.totalCost)}</p>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Fuel Logs */}
        <div>
          <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
            <Fuel size={14} />
            Fuel Logs ({fuelLogs.length})
          </h4>
          {fuelLogs.length === 0 ? (
            <p className="text-sm text-muted py-2">{t('common.noFuelLogs')}</p>
          ) : (
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {fuelLogs.slice(0, 10).map((f) => (
                <div key={f.id} className="flex items-center justify-between p-3 bg-surface border border-main rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-main">
                      {f.gallons.toFixed(1)} gal @ {formatCurrency(f.pricePerGallon)}/gal
                    </p>
                    <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                      <span>{formatDate(f.fuelDate)}</span>
                      {f.stationName && <span>{f.stationName}</span>}
                      {f.odometer != null && <span>{f.odometer.toLocaleString()} mi</span>}
                    </div>
                  </div>
                  <p className="text-sm font-medium text-main ml-4">{formatCurrency(f.totalCost)}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Detail Field helper
// ────────────────────────────────────────────────────────

function DetailField({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-start gap-2">
      <span className="text-muted mt-0.5 shrink-0">{icon}</span>
      <div>
        <p className="text-xs text-muted">{label}</p>
        <p className="text-sm text-main">{value}</p>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// TAB 2: Maintenance
// ────────────────────────────────────────────────────────

interface ScheduleItem {
  id: string;
  vehicleName: string;
  serviceType: string;
  triggerType: 'mileage' | 'date' | 'both';
  nextDueDate: string | null;
  nextDueMileage: number | null;
  currentMileage: number;
  lastServiceDate: string | null;
  status: 'upcoming' | 'overdue' | 'due_soon';
}

function MaintenanceTab({
  schedule,
  history,
  maintenanceFilter,
  setMaintenanceFilter,
  overdueCount,
  dueSoonCount,
  maintenanceDue,
  totalScheduled,
}: {
  schedule: ScheduleItem[];
  history: VehicleMaintenance[];
  maintenanceFilter: 'all' | 'overdue' | 'due_soon' | 'upcoming';
  setMaintenanceFilter: (v: 'all' | 'overdue' | 'due_soon' | 'upcoming') => void;
  overdueCount: number;
  dueSoonCount: number;
  maintenanceDue: VehicleMaintenance[];
  totalScheduled: number;
}) {
  const scheduleStatusConfig: Record<string, { label: string; variant: 'error' | 'warning' | 'info' }> = {
    overdue: { label: 'Overdue', variant: 'error' },
    due_soon: { label: 'Due Soon', variant: 'warning' },
    upcoming: { label: 'Upcoming', variant: 'info' },
  };

  return (
    <div className="space-y-6">
      {/* Maintenance summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <AlertTriangle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{overdueCount}</p>
                <p className="text-sm text-muted">Overdue Services</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Clock size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{dueSoonCount}</p>
                <p className="text-sm text-muted">Due Soon</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Calendar size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalScheduled}</p>
                <p className="text-sm text-muted">Total Scheduled</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter bar */}
      <div className="flex items-center gap-2">
        {(['all', 'overdue', 'due_soon', 'upcoming'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setMaintenanceFilter(f)}
            className={cn(
              'px-3 py-1.5 text-sm rounded-lg border transition-colors',
              maintenanceFilter === f
                ? 'bg-brand/10 border-brand text-brand'
                : 'bg-surface border-main text-muted hover:text-main hover:border-main'
            )}
          >
            {f === 'all' ? 'All' : f === 'overdue' ? 'Overdue' : f === 'due_soon' ? 'Due Soon' : 'Upcoming'}
          </button>
        ))}
      </div>

      {/* Maintenance Schedule */}
      <div>
        <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
          <Calendar size={15} />
          Upcoming Maintenance Schedule
        </h3>
        <Card>
          <CardContent className="p-0">
            {schedule.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <CheckCircle2 size={40} className="mx-auto mb-2 opacity-50" />
                <p>No maintenance items match this filter</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {/* Table header */}
                <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                  <div className="col-span-3">Vehicle</div>
                  <div className="col-span-2">Service Type</div>
                  <div className="col-span-2">Trigger</div>
                  <div className="col-span-2">Next Due</div>
                  <div className="col-span-1">Status</div>
                  <div className="col-span-2">Last Service</div>
                </div>
                {schedule.map((item) => {
                  const sCfg = scheduleStatusConfig[item.status];
                  return (
                    <div key={item.id} className="px-6 py-4 grid grid-cols-12 gap-4 items-center hover:bg-surface-hover transition-colors">
                      <div className="col-span-3">
                        <p className="text-sm font-medium text-main truncate">{item.vehicleName}</p>
                        <p className="text-xs text-muted mt-0.5">{formatNumber(item.currentMileage)} mi current</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-main">{item.serviceType}</p>
                      </div>
                      <div className="col-span-2">
                        <div className="flex items-center gap-1 text-xs text-muted">
                          {item.triggerType === 'mileage' || item.triggerType === 'both' ? (
                            <span className="flex items-center gap-1"><Gauge size={11} /> Mileage</span>
                          ) : null}
                          {item.triggerType === 'both' && <span className="mx-0.5">+</span>}
                          {item.triggerType === 'date' || item.triggerType === 'both' ? (
                            <span className="flex items-center gap-1"><Calendar size={11} /> Date</span>
                          ) : null}
                        </div>
                      </div>
                      <div className="col-span-2">
                        <div className="space-y-0.5">
                          {item.nextDueDate && (
                            <p className="text-sm text-main">{formatDate(item.nextDueDate)}</p>
                          )}
                          {item.nextDueMileage != null && (
                            <p className="text-xs text-muted">{formatNumber(item.nextDueMileage)} mi</p>
                          )}
                        </div>
                      </div>
                      <div className="col-span-1">
                        <Badge variant={sCfg.variant} size="sm" dot>{sCfg.label}</Badge>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-muted">
                          {item.lastServiceDate ? formatDate(item.lastServiceDate) : 'Never'}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Maintenance History (from hook data) */}
      <div>
        <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
          <Wrench size={15} />
          Service History Log
        </h3>
        <Card>
          <CardContent className="p-0">
            {history.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <Wrench size={40} className="mx-auto mb-2 opacity-50" />
                <p>No service history recorded yet</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                  <div className="col-span-3">Service</div>
                  <div className="col-span-2">Type</div>
                  <div className="col-span-2">Date</div>
                  <div className="col-span-1">Priority</div>
                  <div className="col-span-1">Status</div>
                  <div className="col-span-1">Odometer</div>
                  <div className="col-span-2">Cost</div>
                </div>
                {history.slice(0, 20).map((m) => {
                  const statusCfg = maintenanceStatusConfig[m.status];
                  const priCfg = priorityConfig[m.priority] || priorityConfig.medium;
                  return (
                    <div key={m.id} className="px-6 py-4 grid grid-cols-12 gap-4 items-center hover:bg-surface-hover transition-colors">
                      <div className="col-span-3">
                        <p className="text-sm font-medium text-main truncate">{m.title}</p>
                        {m.vendorName && <p className="text-xs text-muted mt-0.5">{m.vendorName}</p>}
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-muted">{maintenanceTypeLabels[m.maintenanceType] || m.maintenanceType}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-main">{m.scheduledDate ? formatDate(m.scheduledDate) : '--'}</p>
                        {m.completedDate && (
                          <p className="text-xs text-muted mt-0.5">Done: {formatDate(m.completedDate)}</p>
                        )}
                      </div>
                      <div className="col-span-1">
                        <Badge variant={priCfg.variant} size="sm">{priCfg.label}</Badge>
                      </div>
                      <div className="col-span-1">
                        <Badge variant={statusCfg.variant} size="sm">{statusCfg.label}</Badge>
                      </div>
                      <div className="col-span-1">
                        <p className="text-sm text-muted">
                          {m.odometerAtService != null ? formatNumber(m.odometerAtService) : '--'}
                        </p>
                      </div>
                      <div className="col-span-2">
                        <div className="text-sm text-main">
                          {m.totalCost != null && m.totalCost > 0 ? (
                            <div>
                              <p className="font-medium">{formatCurrency(m.totalCost)}</p>
                              {(m.partsCost != null || m.laborCost != null) && (
                                <p className="text-xs text-muted mt-0.5">
                                  {m.partsCost != null ? `Parts: ${formatCurrency(m.partsCost)}` : ''}
                                  {m.partsCost != null && m.laborCost != null ? ' / ' : ''}
                                  {m.laborCost != null ? `Labor: ${formatCurrency(m.laborCost)}` : ''}
                                </p>
                              )}
                            </div>
                          ) : (
                            <span className="text-muted">--</span>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// TAB 3: Fuel Log
// ────────────────────────────────────────────────────────

interface FuelEntry {
  id: string;
  vehicleId: string;
  vehicleName: string;
  fuelDate: string;
  gallons: number;
  pricePerGallon: number;
  totalCost: number;
  odometer: number | null;
  stationName: string;
  fuelType: string;
  mpg: number | null;
  anomaly: boolean;
}

function FuelTab({
  entries,
  allEntries,
  stats,
  vehicleFilter,
  setVehicleFilter,
  uniqueVehicles,
}: {
  entries: FuelEntry[];
  allEntries: FuelEntry[];
  stats: { avgMpg: number; avgCostPerGal: number; totalSpent: number; anomalyCount: number };
  vehicleFilter: string;
  setVehicleFilter: (v: string) => void;
  uniqueVehicles: string[];
}) {
  return (
    <div className="space-y-6">
      {/* Fuel summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Gauge size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.avgMpg.toFixed(1)}</p>
                <p className="text-sm text-muted">Avg MPG</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.avgCostPerGal)}</p>
                <p className="text-sm text-muted">Avg Cost/Gallon</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <BarChart3 size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats.totalSpent)}</p>
                <p className="text-sm text-muted">Total Fuel Spend</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className={cn(
                'p-2 rounded-lg',
                stats.anomalyCount > 0
                  ? 'bg-red-100 dark:bg-red-900/30'
                  : 'bg-emerald-100 dark:bg-emerald-900/30'
              )}>
                <CircleAlert size={20} className={stats.anomalyCount > 0
                  ? 'text-red-600 dark:text-red-400'
                  : 'text-emerald-600 dark:text-emerald-400'
                } />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.anomalyCount}</p>
                <p className="text-sm text-muted">Anomaly Alerts</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter */}
      <div className="flex items-center gap-4">
        <Select
          options={[
            { value: 'all', label: 'All Vehicles' },
            ...uniqueVehicles.map((v) => ({ value: v, label: v })),
          ]}
          value={vehicleFilter}
          onChange={(e) => setVehicleFilter(e.target.value)}
          className="sm:w-72"
        />
      </div>

      {/* Fuel log table */}
      <Card>
        <CardContent className="p-0">
          {entries.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <Fuel size={40} className="mx-auto mb-2 opacity-50" />
              <p>No fuel logs recorded yet</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-3">Vehicle</div>
                <div className="col-span-1">Date</div>
                <div className="col-span-1">Gallons</div>
                <div className="col-span-1">Price/Gal</div>
                <div className="col-span-1">Total</div>
                <div className="col-span-1">Odometer</div>
                <div className="col-span-1">MPG</div>
                <div className="col-span-2">Station</div>
                <div className="col-span-1">Alert</div>
              </div>
              {entries.map((entry) => (
                <div
                  key={entry.id}
                  className={cn(
                    'px-6 py-4 grid grid-cols-12 gap-4 items-center hover:bg-surface-hover transition-colors',
                    entry.anomaly && 'bg-red-950/10'
                  )}
                >
                  <div className="col-span-3">
                    <p className="text-sm font-medium text-main truncate">{entry.vehicleName}</p>
                    <p className="text-xs text-muted mt-0.5">{entry.fuelType}</p>
                  </div>
                  <div className="col-span-1">
                    <p className="text-sm text-main">{formatDate(entry.fuelDate)}</p>
                  </div>
                  <div className="col-span-1">
                    <p className="text-sm text-main">{entry.gallons.toFixed(1)}</p>
                  </div>
                  <div className="col-span-1">
                    <p className="text-sm text-main">{formatCurrency(entry.pricePerGallon)}</p>
                  </div>
                  <div className="col-span-1">
                    <p className="text-sm font-medium text-main">{formatCurrency(entry.totalCost)}</p>
                  </div>
                  <div className="col-span-1">
                    <p className="text-sm text-muted">{entry.odometer != null ? formatNumber(entry.odometer) : '--'}</p>
                  </div>
                  <div className="col-span-1">
                    {entry.mpg != null ? (
                      <div className="flex items-center gap-1">
                        <p className={cn(
                          'text-sm font-medium',
                          entry.anomaly ? 'text-red-400' : 'text-main'
                        )}>
                          {entry.mpg.toFixed(1)}
                        </p>
                        {entry.mpg >= 18 ? (
                          <TrendingUp size={12} className="text-emerald-400" />
                        ) : entry.mpg < 12 ? (
                          <TrendingDown size={12} className="text-red-400" />
                        ) : null}
                      </div>
                    ) : (
                      <span className="text-sm text-muted">--</span>
                    )}
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-muted truncate">{entry.stationName || '--'}</p>
                  </div>
                  <div className="col-span-1">
                    {entry.anomaly ? (
                      <Badge variant="error" size="sm" dot>Anomaly</Badge>
                    ) : (
                      <span className="text-xs text-muted">--</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* MPG Trend Summary */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-medium text-main mb-4 flex items-center gap-2">
            <TrendingUp size={15} />
            MPG Trend Summary
          </h3>
          {uniqueVehicles.length === 0 ? (
            <p className="text-sm text-muted">No fuel data available to compute MPG trends.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {uniqueVehicles.map((vName) => {
                const vehicleEntries = allEntries.filter((e) => e.vehicleName === vName && e.mpg !== null);
                if (vehicleEntries.length === 0) return null;
                const avg = vehicleEntries.reduce((s, e) => s + (e.mpg || 0), 0) / vehicleEntries.length;
                const latest = vehicleEntries[0]?.mpg || 0;
                const trend = vehicleEntries.length > 1 ? latest - (vehicleEntries[vehicleEntries.length - 1]?.mpg || 0) : 0;
                return (
                  <div key={vName} className="p-3 bg-secondary/30 border border-main rounded-lg">
                    <p className="text-xs text-muted truncate mb-1">{vName}</p>
                    <div className="flex items-center justify-between">
                      <p className="text-lg font-semibold text-main">{avg.toFixed(1)} MPG</p>
                      <div className={cn(
                        'flex items-center gap-0.5 text-xs font-medium',
                        trend >= 0 ? 'text-emerald-400' : 'text-red-400'
                      )}>
                        {trend >= 0 ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                        {trend >= 0 ? '+' : ''}{trend.toFixed(1)}
                      </div>
                    </div>
                    <p className="text-xs text-muted mt-1">Latest: {latest.toFixed(1)} MPG</p>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* IRS Mileage Deduction Summary */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
            <DollarSign size={15} />
            IRS Mileage Deduction Estimate
          </h3>
          <p className="text-xs text-muted mb-4">
            Standard mileage rate for 2026: $0.70/mile (estimated). Consult your CPA for actual deduction amounts.
          </p>
          {uniqueVehicles.length === 0 ? (
            <p className="text-sm text-muted">No fuel data available to compute mileage deductions.</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {uniqueVehicles.map((vName) => {
                const vehicleEntries = allEntries
                  .filter((e) => e.vehicleName === vName && e.odometer != null)
                  .sort((a, b) => (a.odometer || 0) - (b.odometer || 0));
                if (vehicleEntries.length < 2) return null;
                const milesDriven = (vehicleEntries[vehicleEntries.length - 1].odometer || 0) - (vehicleEntries[0].odometer || 0);
                if (milesDriven <= 0) return null;
                const deduction = milesDriven * 0.70;
                return (
                  <div key={vName} className="p-3 bg-secondary/30 border border-main rounded-lg">
                    <p className="text-xs text-muted truncate mb-1">{vName}</p>
                    <p className="text-lg font-semibold text-main">{formatCurrency(deduction)}</p>
                    <p className="text-xs text-muted mt-1">{formatNumber(milesDriven)} miles tracked</p>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// TAB 4: Inspections
// ────────────────────────────────────────────────────────

interface InspectionRecord {
  id: string;
  vehicleName: string;
  inspectorName: string;
  inspectionDate: string;
  result: 'pass' | 'fail' | 'missing';
  itemsPassed: number;
  itemsFailed: number;
  totalItems: number;
  defects: string[];
  notes: string | null;
}

function InspectionsTab({
  inspections,
  stats,
  filter,
  setFilter,
  missingAlerts,
  activeVehicleCount,
}: {
  inspections: InspectionRecord[];
  stats: { total: number; passed: number; failed: number; missing: number; passRate: number };
  filter: 'all' | 'pass' | 'fail' | 'missing';
  setFilter: (v: 'all' | 'pass' | 'fail' | 'missing') => void;
  missingAlerts: { vehicle: string; lastInspection: string | null; daysMissing: number }[];
  activeVehicleCount: number;
}) {
  const [expandedInspection, setExpandedInspection] = useState<string | null>(null);
  const [showChecklist, setShowChecklist] = useState(false);

  const resultConfig: Record<string, { label: string; variant: 'success' | 'error' | 'warning' }> = {
    pass: { label: 'Pass', variant: 'success' },
    fail: { label: 'Fail', variant: 'error' },
    missing: { label: 'Missing', variant: 'warning' },
  };

  return (
    <div className="space-y-6">
      {/* Inspection stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <ClipboardCheck size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.total}</p>
                <p className="text-sm text-muted">Total Inspections</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle2 size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.passed}</p>
                <p className="text-sm text-muted">Passed</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <XCircle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.failed}</p>
                <p className="text-sm text-muted">Failed</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className={cn(
                'p-2 rounded-lg',
                stats.passRate >= 80
                  ? 'bg-emerald-100 dark:bg-emerald-900/30'
                  : 'bg-amber-100 dark:bg-amber-900/30'
              )}>
                <Activity size={20} className={
                  stats.passRate >= 80
                    ? 'text-emerald-600 dark:text-emerald-400'
                    : 'text-amber-600 dark:text-amber-400'
                } />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.passRate.toFixed(0)}%</p>
                <p className="text-sm text-muted">Pass Rate</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter + DOT Checklist toggle */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {(['all', 'pass', 'fail', 'missing'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={cn(
                'px-3 py-1.5 text-sm rounded-lg border transition-colors',
                filter === f
                  ? 'bg-brand/10 border-brand text-brand'
                  : 'bg-surface border-main text-muted hover:text-main hover:border-main'
              )}
            >
              {f === 'all' ? 'All' : f === 'pass' ? 'Passed' : f === 'fail' ? 'Failed' : 'Missing'}
            </button>
          ))}
        </div>
        <Button
          variant="secondary"
          onClick={() => setShowChecklist(!showChecklist)}
        >
          <Eye size={16} />
          {showChecklist ? 'Hide' : 'View'} DOT Checklist
        </Button>
      </div>

      {/* DOT Checklist Reference */}
      {showChecklist && (
        <Card>
          <CardContent className="p-5">
            <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
              <ClipboardCheck size={15} />
              DOT Pre-Trip Inspection Checklist ({DOT_CHECKLIST_ITEMS.length} items)
            </h3>
            <p className="text-xs text-muted mb-4">
              Federal Motor Carrier Safety Administration (FMCSA) required daily vehicle inspection items. Drivers must complete this checklist before each trip.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
              {DOT_CHECKLIST_ITEMS.map((item, idx) => (
                <div key={idx} className="flex items-center gap-2 p-2 bg-secondary/30 border border-main rounded-lg text-sm">
                  <span className="text-xs text-muted font-mono w-5 text-right shrink-0">{idx + 1}.</span>
                  <span className="text-main">{item}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Inspection records */}
      <Card>
        <CardContent className="p-0">
          {inspections.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <ClipboardCheck size={40} className="mx-auto mb-2 opacity-50" />
              <p>No inspections recorded yet</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-1" />
                <div className="col-span-3">Vehicle</div>
                <div className="col-span-2">Inspector</div>
                <div className="col-span-2">Date</div>
                <div className="col-span-1">Result</div>
                <div className="col-span-3">Score</div>
              </div>
              {inspections.map((insp) => {
                const rCfg = resultConfig[insp.result];
                const isExpanded = expandedInspection === insp.id;
                const passPercent = insp.totalItems > 0 ? (insp.itemsPassed / insp.totalItems) * 100 : 0;

                return (
                  <div key={insp.id}>
                    <div
                      className={cn(
                        'px-6 py-4 grid grid-cols-12 gap-4 items-center cursor-pointer hover:bg-surface-hover transition-colors',
                        isExpanded && 'bg-surface-hover'
                      )}
                      onClick={() => setExpandedInspection(isExpanded ? null : insp.id)}
                    >
                      <div className="col-span-1 flex items-center">
                        {isExpanded ? (
                          <ChevronDown size={16} className="text-muted" />
                        ) : (
                          <ChevronRight size={16} className="text-muted" />
                        )}
                      </div>
                      <div className="col-span-3">
                        <p className="text-sm font-medium text-main truncate">{insp.vehicleName}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-muted">{insp.inspectorName}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-main">{formatDate(insp.inspectionDate)}</p>
                      </div>
                      <div className="col-span-1">
                        <Badge variant={rCfg.variant} dot>{rCfg.label}</Badge>
                      </div>
                      <div className="col-span-3">
                        <div className="flex items-center gap-3">
                          <div className="flex-1 h-2 bg-secondary rounded-full overflow-hidden">
                            <div
                              className={cn(
                                'h-full rounded-full transition-all',
                                passPercent === 100 ? 'bg-emerald-500' : passPercent >= 80 ? 'bg-amber-500' : 'bg-red-500'
                              )}
                              style={{ width: `${passPercent}%` }}
                            />
                          </div>
                          <span className="text-xs text-muted font-medium whitespace-nowrap">
                            {insp.itemsPassed}/{insp.totalItems}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Expanded detail */}
                    {isExpanded && (
                      <div className="px-6 pb-5 pt-2 bg-secondary/30 border-t border-main">
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                          {/* Defects */}
                          <div>
                            <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
                              <AlertTriangle size={14} />
                              Defects Found ({insp.defects.length})
                            </h4>
                            {insp.defects.length === 0 ? (
                              <div className="flex items-center gap-2 p-3 bg-emerald-950/20 border border-emerald-800/30 rounded-lg">
                                <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                                <p className="text-sm text-emerald-300">No defects found. Vehicle passed all inspection items.</p>
                              </div>
                            ) : (
                              <div className="space-y-2">
                                {insp.defects.map((defect, idx) => (
                                  <div key={idx} className="flex items-start gap-2 p-3 bg-red-950/20 border border-red-800/30 rounded-lg">
                                    <XCircle size={14} className="text-red-400 shrink-0 mt-0.5" />
                                    <p className="text-sm text-red-300">{defect}</p>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>

                          {/* Summary */}
                          <div>
                            <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
                              <FileText size={14} />
                              Inspection Summary
                            </h4>
                            <div className="space-y-3">
                              <div className="grid grid-cols-3 gap-3">
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-emerald-400">{insp.itemsPassed}</p>
                                  <p className="text-xs text-muted">Passed</p>
                                </div>
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-red-400">{insp.itemsFailed}</p>
                                  <p className="text-xs text-muted">Failed</p>
                                </div>
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-main">{insp.totalItems}</p>
                                  <p className="text-xs text-muted">Total Items</p>
                                </div>
                              </div>
                              {insp.notes && (
                                <div className="p-3 bg-surface border border-main rounded-lg">
                                  <p className="text-xs text-muted mb-1">Inspector Notes</p>
                                  <p className="text-sm text-main">{insp.notes}</p>
                                </div>
                              )}
                              <div className="p-3 bg-surface border border-main rounded-lg">
                                <p className="text-xs text-muted mb-1">Overall Result</p>
                                <div className="flex items-center gap-2">
                                  {insp.result === 'pass' ? (
                                    <CheckCircle2 size={18} className="text-emerald-400" />
                                  ) : (
                                    <XCircle size={18} className="text-red-400" />
                                  )}
                                  <p className={cn(
                                    'text-sm font-medium',
                                    insp.result === 'pass' ? 'text-emerald-400' : 'text-red-400'
                                  )}>
                                    {insp.result === 'pass'
                                      ? 'Vehicle cleared for service'
                                      : 'Vehicle requires repairs before dispatch'}
                                  </p>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Missing inspection alerts */}
      <Card>
        <CardContent className="p-5">
          <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
            <AlertTriangle size={15} className="text-amber-400" />
            Missing Inspection Alerts
          </h3>
          <p className="text-xs text-muted mb-4">
            Vehicles that have not completed their daily pre-trip inspection. DOT requires a pre-trip inspection before each trip.
          </p>
          <div className="space-y-2">
            {missingAlerts.length > 0 ? (
              <>
                {missingAlerts.map((alert, idx) => (
                  <div key={idx} className="flex items-center justify-between p-3 bg-amber-950/20 border border-amber-800/30 rounded-lg">
                    <div className="flex items-center gap-3">
                      <AlertTriangle size={16} className="text-amber-400 shrink-0" />
                      <div>
                        <p className="text-sm font-medium text-main">{alert.vehicle}</p>
                        <p className="text-xs text-muted">
                          {alert.lastInspection ? `Last inspection: ${formatDate(alert.lastInspection)}` : 'No inspections recorded'}
                        </p>
                      </div>
                    </div>
                    <Badge variant="warning" size="sm">
                      {alert.daysMissing > 0
                        ? `${alert.daysMissing} day${alert.daysMissing !== 1 ? 's' : ''} overdue`
                        : 'Due today'}
                    </Badge>
                  </div>
                ))}
                {missingAlerts.length < activeVehicleCount && (
                  <div className="flex items-center gap-2 p-3 bg-secondary/30 border border-main rounded-lg">
                    <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                    <p className="text-sm text-muted">All other vehicles have completed today&apos;s pre-trip inspection</p>
                  </div>
                )}
              </>
            ) : activeVehicleCount > 0 ? (
              <div className="flex items-center gap-2 p-3 bg-emerald-950/20 border border-emerald-800/30 rounded-lg">
                <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                <p className="text-sm text-emerald-300">All active vehicles have completed today&apos;s pre-trip inspection</p>
              </div>
            ) : (
              <div className="flex items-center gap-2 p-3 bg-secondary/30 border border-main rounded-lg">
                <ClipboardCheck size={16} className="text-muted shrink-0" />
                <p className="text-sm text-muted">No active vehicles in fleet</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
