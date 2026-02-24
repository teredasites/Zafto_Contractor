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

const vehicleStatusConfig: Record<VehicleStatus, { tKey: string; variant: 'success' | 'warning' | 'error' | 'secondary' }> = {
  active: { tKey: 'common.active', variant: 'success' },
  maintenance: { tKey: 'fleet.statusMaintenance', variant: 'warning' },
  out_of_service: { tKey: 'fleet.statusOutOfService', variant: 'error' },
  retired: { tKey: 'fleet.statusRetired', variant: 'secondary' },
};

const maintenanceStatusConfig: Record<MaintenanceStatus, { tKey: string; variant: 'info' | 'warning' | 'success' | 'secondary' }> = {
  scheduled: { tKey: 'common.scheduled', variant: 'info' },
  in_progress: { tKey: 'common.inProgress', variant: 'warning' },
  completed: { tKey: 'common.completed', variant: 'success' },
  cancelled: { tKey: 'common.cancelled', variant: 'secondary' },
};

const vehicleTypeTKeys: Record<string, string> = {
  truck: 'fleet.typeTruck',
  van: 'fleet.typeVan',
  trailer: 'fleet.typeTrailer',
  car: 'fleet.typeCar',
  equipment: 'fleet.typeEquipment',
  other: 'fleet.typeOther',
};

const maintenanceTypeTKeys: Record<string, string> = {
  oil_change: 'fleet.maintOilChange',
  tire_rotation: 'fleet.maintTireRotation',
  brake_service: 'fleet.maintBrakeService',
  inspection: 'fleet.maintInspection',
  engine: 'fleet.maintEngine',
  transmission: 'fleet.maintTransmission',
  electrical: 'fleet.maintElectrical',
  body: 'fleet.maintBody',
  scheduled_service: 'fleet.maintScheduledService',
  other: 'fleet.typeOther',
};

const priorityConfig: Record<string, { tKey: string; variant: 'secondary' | 'info' | 'warning' | 'error' }> = {
  low: { tKey: 'common.low', variant: 'secondary' },
  medium: { tKey: 'common.medium', variant: 'info' },
  high: { tKey: 'common.high', variant: 'warning' },
  critical: { tKey: 'common.critical', variant: 'error' },
};

const DOT_CHECKLIST_TKEYS = [
  'fleet.dotEngineOil',
  'fleet.dotCoolant',
  'fleet.dotBrakeFluid',
  'fleet.dotPowerSteering',
  'fleet.dotWasherFluid',
  'fleet.dotTireCondition',
  'fleet.dotLugNuts',
  'fleet.dotHeadlights',
  'fleet.dotTailLights',
  'fleet.dotBrakeLights',
  'fleet.dotTurnSignals',
  'fleet.dotHazardLights',
  'fleet.dotBackupLights',
  'fleet.dotLicensePlateLight',
  'fleet.dotHorn',
  'fleet.dotWipers',
  'fleet.dotMirrors',
  'fleet.dotWindshield',
  'fleet.dotSeatBelts',
  'fleet.dotParkingBrake',
  'fleet.dotServiceBrake',
  'fleet.dotSteeringPlay',
  'fleet.dotExhaust',
  'fleet.dotFireExtinguisher',
  'fleet.dotFirstAid',
  'fleet.dotReflectiveTriangles',
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
          vehicleName: vehicle?.vehicleName ?? t('fleet.unknownVehicle'),
          serviceTypeTKey: maintenanceTypeTKeys[m.maintenanceType] || null,
          serviceTypeFallback: m.title,
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
        vehicleName: vehicle?.vehicleName ?? t('fleet.unknownVehicle'),
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

        const totalItems = DOT_CHECKLIST_TKEYS.length;
        const itemsFailed = defects.length;
        const itemsPassed = totalItems - itemsFailed;

        return {
          id: m.id,
          vehicleName: vehicle?.vehicleName ?? t('fleet.unknownVehicle'),
          inspectorName: m.completedByUserId ? m.completedByUserId.slice(0, 8) + '...' : t('common.unassigned'),
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
  const tabs: { key: FleetTab; tKey: string; icon: React.ReactNode; count?: number }[] = [
    { key: 'vehicles', tKey: 'fleet.tabVehicles', icon: <Truck size={16} />, count: vehicles.length },
    { key: 'maintenance', tKey: 'fleet.tabMaintenance', icon: <Wrench size={16} />, count: overdueCount > 0 ? overdueCount : undefined },
    { key: 'fuel', tKey: 'fleet.tabFuelLog', icon: <Fuel size={16} /> },
    { key: 'inspections', tKey: 'fleet.tabInspections', icon: <ClipboardCheck size={16} />, count: inspectionStats.failed > 0 ? inspectionStats.failed : undefined },
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
              {t(tab.tKey)}
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
            { value: 'all', label: t('fleet.allStatuses') },
            { value: 'active', label: t('common.active') },
            { value: 'maintenance', label: t('fleet.statusMaintenance') },
            { value: 'out_of_service', label: t('fleet.statusOutOfService') },
            { value: 'retired', label: t('fleet.statusRetired') },
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
        <span className="text-sm text-muted">{vehicleTypeTKeys[vehicle.vehicleType] ? t(vehicleTypeTKeys[vehicle.vehicleType]) : vehicle.vehicleType}</span>
      </div>
      <div className="col-span-2">
        <p className="text-sm text-main">
          {[vehicle.make, vehicle.model].filter(Boolean).join(' ') || '--'}
        </p>
        {vehicle.year && <p className="text-xs text-muted">{vehicle.year}</p>}
      </div>
      <div className="col-span-2">
        <p className="text-sm text-muted truncate">
          {vehicle.assignedToUserId ? vehicle.assignedToUserId.slice(0, 8) + '...' : t('common.unassigned')}
        </p>
      </div>
      <div className="col-span-1">
        <Badge variant={statusCfg.variant} dot>{t(statusCfg.tKey)}</Badge>
      </div>
      <div className="col-span-1">
        <p className="text-sm text-main">
          {vehicle.currentOdometer != null
            ? vehicle.currentOdometer.toLocaleString() + ' ' + t('fleet.miAbbrev')
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
          {t('fleet.vehicleDetails')}
        </h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <DetailField icon={<Hash size={13} />} label={t('fleet.vin')} value={vehicle.vin || t('fleet.notRecorded')} />
          <DetailField icon={<Car size={13} />} label={t('fleet.licensePlate')} value={vehicle.licensePlate || t('fleet.notRecorded')} />
          <DetailField icon={<Gauge size={13} />} label={t('common.odometer')} value={vehicle.currentOdometer != null ? formatNumber(vehicle.currentOdometer) + ' ' + t('fleet.miAbbrev') : t('fleet.notRecorded')} />
          <DetailField icon={<User size={13} />} label={t('common.assignedTo')} value={vehicle.assignedToUserId ? vehicle.assignedToUserId.slice(0, 8) + '...' : t('common.unassigned')} />
          <div className="flex items-start gap-2">
            <Shield size={13} className="text-muted mt-0.5 shrink-0" />
            <div>
              <p className="text-xs text-muted">{t('fleet.insurancePolicy')}</p>
              <p className="text-sm text-main">{vehicle.insurancePolicyNumber || t('fleet.notRecorded')}</p>
              {vehicle.insuranceExpiry && (
                <div className="flex items-center gap-1 mt-0.5">
                  <p className="text-xs text-muted">{t('fleet.expires')}: {formatDate(vehicle.insuranceExpiry)}</p>
                  {isExpired(vehicle.insuranceExpiry) && <Badge variant="error" size="sm">{t('common.expired')}</Badge>}
                  {!isExpired(vehicle.insuranceExpiry) && isExpiringSoon(vehicle.insuranceExpiry) && <Badge variant="warning" size="sm">{t('fleet.expiringSoon')}</Badge>}
                </div>
              )}
            </div>
          </div>
          <div className="flex items-start gap-2">
            <FileText size={13} className="text-muted mt-0.5 shrink-0" />
            <div>
              <p className="text-xs text-muted">{t('fleet.registration')}</p>
              <p className="text-sm text-main">{vehicle.registrationExpiry ? t('fleet.onFile') : t('fleet.notRecorded')}</p>
              {vehicle.registrationExpiry && (
                <div className="flex items-center gap-1 mt-0.5">
                  <p className="text-xs text-muted">{t('fleet.expires')}: {formatDate(vehicle.registrationExpiry)}</p>
                  {isExpired(vehicle.registrationExpiry) && <Badge variant="error" size="sm">{t('common.expired')}</Badge>}
                  {!isExpired(vehicle.registrationExpiry) && isExpiringSoon(vehicle.registrationExpiry) && <Badge variant="warning" size="sm">{t('fleet.expiringSoon')}</Badge>}
                </div>
              )}
            </div>
          </div>
          <DetailField icon={<DollarSign size={13} />} label={t('fleet.dailyRate')} value={vehicle.dailyRate != null ? formatCurrency(vehicle.dailyRate) : t('fleet.notSet')} />
          <DetailField icon={<CircleDot size={13} />} label={t('fleet.color')} value={vehicle.color || t('fleet.notRecorded')} />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Maintenance History */}
        <div>
          <h4 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
            <Wrench size={14} />
            {t('fleet.maintenanceHistory')} ({maintenance.length})
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
                        <Badge variant={statusCfg.variant} size="sm">{t(statusCfg.tKey)}</Badge>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                        {m.scheduledDate && (
                          <span className="flex items-center gap-1">
                            <Clock size={10} />{formatDate(m.scheduledDate)}
                          </span>
                        )}
                        {m.vendorName && <span>{m.vendorName}</span>}
                        {m.odometerAtService != null && (
                          <span>{formatNumber(m.odometerAtService)} {t('fleet.miAbbrev')}</span>
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
            {t('fleet.fuelLogs')} ({fuelLogs.length})
          </h4>
          {fuelLogs.length === 0 ? (
            <p className="text-sm text-muted py-2">{t('common.noFuelLogs')}</p>
          ) : (
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {fuelLogs.slice(0, 10).map((f) => (
                <div key={f.id} className="flex items-center justify-between p-3 bg-surface border border-main rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-main">
                      {t('fleet.galAtPrice', { gallons: f.gallons.toFixed(1), price: formatCurrency(f.pricePerGallon) })}
                    </p>
                    <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                      <span>{formatDate(f.fuelDate)}</span>
                      {f.stationName && <span>{f.stationName}</span>}
                      {f.odometer != null && <span>{f.odometer.toLocaleString()} {t('fleet.miAbbrev')}</span>}
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
  serviceTypeTKey: string | null;
  serviceTypeFallback: string;
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
  const { t } = useTranslation();
  const scheduleStatusConfig: Record<string, { tKey: string; variant: 'error' | 'warning' | 'info' }> = {
    overdue: { tKey: 'common.overdue', variant: 'error' },
    due_soon: { tKey: 'fleet.dueSoon', variant: 'warning' },
    upcoming: { tKey: 'fleet.upcoming', variant: 'info' },
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
                <p className="text-sm text-muted">{t('fleet.overdueServices')}</p>
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
                <p className="text-sm text-muted">{t('fleet.dueSoon')}</p>
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
                <p className="text-sm text-muted">{t('fleet.totalScheduled')}</p>
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
            {f === 'all' ? t('common.all') : f === 'overdue' ? t('common.overdue') : f === 'due_soon' ? t('fleet.dueSoon') : t('fleet.upcoming')}
          </button>
        ))}
      </div>

      {/* Maintenance Schedule */}
      <div>
        <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
          <Calendar size={15} />
          {t('fleet.upcomingMaintenanceSchedule')}
        </h3>
        <Card>
          <CardContent className="p-0">
            {schedule.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <CheckCircle2 size={40} className="mx-auto mb-2 opacity-50" />
                <p>{t('fleet.noMaintenanceMatch')}</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {/* Table header */}
                <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                  <div className="col-span-3">{t('common.vehicle')}</div>
                  <div className="col-span-2">{t('fleet.serviceType')}</div>
                  <div className="col-span-2">{t('fleet.trigger')}</div>
                  <div className="col-span-2">{t('fleet.nextDue')}</div>
                  <div className="col-span-1">{t('common.status')}</div>
                  <div className="col-span-2">{t('fleet.lastServiceDate')}</div>
                </div>
                {schedule.map((item) => {
                  const sCfg = scheduleStatusConfig[item.status];
                  return (
                    <div key={item.id} className="px-6 py-4 grid grid-cols-12 gap-4 items-center hover:bg-surface-hover transition-colors">
                      <div className="col-span-3">
                        <p className="text-sm font-medium text-main truncate">{item.vehicleName}</p>
                        <p className="text-xs text-muted mt-0.5">{formatNumber(item.currentMileage)} {t('fleet.miCurrent')}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-main">{item.serviceTypeTKey ? t(item.serviceTypeTKey) : item.serviceTypeFallback}</p>
                      </div>
                      <div className="col-span-2">
                        <div className="flex items-center gap-1 text-xs text-muted">
                          {item.triggerType === 'mileage' || item.triggerType === 'both' ? (
                            <span className="flex items-center gap-1"><Gauge size={11} /> {t('fleet.triggerMileage')}</span>
                          ) : null}
                          {item.triggerType === 'both' && <span className="mx-0.5">+</span>}
                          {item.triggerType === 'date' || item.triggerType === 'both' ? (
                            <span className="flex items-center gap-1"><Calendar size={11} /> {t('common.date')}</span>
                          ) : null}
                        </div>
                      </div>
                      <div className="col-span-2">
                        <div className="space-y-0.5">
                          {item.nextDueDate && (
                            <p className="text-sm text-main">{formatDate(item.nextDueDate)}</p>
                          )}
                          {item.nextDueMileage != null && (
                            <p className="text-xs text-muted">{formatNumber(item.nextDueMileage)} {t('fleet.miAbbrev')}</p>
                          )}
                        </div>
                      </div>
                      <div className="col-span-1">
                        <Badge variant={sCfg.variant} size="sm" dot>{t(sCfg.tKey)}</Badge>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-muted">
                          {item.lastServiceDate ? formatDate(item.lastServiceDate) : t('fleet.never')}
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
          {t('fleet.serviceHistoryLog')}
        </h3>
        <Card>
          <CardContent className="p-0">
            {history.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <Wrench size={40} className="mx-auto mb-2 opacity-50" />
                <p>{t('fleet.noServiceHistory')}</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                  <div className="col-span-3">{t('fleet.service')}</div>
                  <div className="col-span-2">{t('common.type')}</div>
                  <div className="col-span-2">{t('common.date')}</div>
                  <div className="col-span-1">{t('common.priority')}</div>
                  <div className="col-span-1">{t('common.status')}</div>
                  <div className="col-span-1">{t('common.odometer')}</div>
                  <div className="col-span-2">{t('fleet.cost')}</div>
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
                        <p className="text-sm text-muted">{maintenanceTypeTKeys[m.maintenanceType] ? t(maintenanceTypeTKeys[m.maintenanceType]) : m.maintenanceType}</p>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm text-main">{m.scheduledDate ? formatDate(m.scheduledDate) : '--'}</p>
                        {m.completedDate && (
                          <p className="text-xs text-muted mt-0.5">{t('fleet.done')}: {formatDate(m.completedDate)}</p>
                        )}
                      </div>
                      <div className="col-span-1">
                        <Badge variant={priCfg.variant} size="sm">{t(priCfg.tKey)}</Badge>
                      </div>
                      <div className="col-span-1">
                        <Badge variant={statusCfg.variant} size="sm">{t(statusCfg.tKey)}</Badge>
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
                                  {m.partsCost != null ? `${t('fleet.parts')}: ${formatCurrency(m.partsCost)}` : ''}
                                  {m.partsCost != null && m.laborCost != null ? ' / ' : ''}
                                  {m.laborCost != null ? `${t('fleet.labor')}: ${formatCurrency(m.laborCost)}` : ''}
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
  const { t } = useTranslation();

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
                <p className="text-sm text-muted">{t('fleet.avgMpg')}</p>
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
                <p className="text-sm text-muted">{t('fleet.avgCostPerGallon')}</p>
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
                <p className="text-sm text-muted">{t('fleet.totalFuelSpend')}</p>
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
                <p className="text-sm text-muted">{t('fleet.anomalyAlerts')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter */}
      <div className="flex items-center gap-4">
        <Select
          options={[
            { value: 'all', label: t('fleet.allVehicles') },
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
              <p>{t('fleet.noFuelLogsRecorded')}</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-3">{t('common.vehicle')}</div>
                <div className="col-span-1">{t('common.date')}</div>
                <div className="col-span-1">{t('fleet.gallons')}</div>
                <div className="col-span-1">{t('fleet.pricePerGal')}</div>
                <div className="col-span-1">{t('common.total')}</div>
                <div className="col-span-1">{t('common.odometer')}</div>
                <div className="col-span-1">{t('fleet.mpg')}</div>
                <div className="col-span-2">{t('fleet.station')}</div>
                <div className="col-span-1">{t('fleet.alert')}</div>
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
                      <Badge variant="error" size="sm" dot>{t('fleet.anomaly')}</Badge>
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
            {t('fleet.mpgTrendSummary')}
          </h3>
          {uniqueVehicles.length === 0 ? (
            <p className="text-sm text-muted">{t('fleet.noFuelDataMpg')}</p>
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
                      <p className="text-lg font-semibold text-main">{avg.toFixed(1)} {t('fleet.mpg')}</p>
                      <div className={cn(
                        'flex items-center gap-0.5 text-xs font-medium',
                        trend >= 0 ? 'text-emerald-400' : 'text-red-400'
                      )}>
                        {trend >= 0 ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                        {trend >= 0 ? '+' : ''}{trend.toFixed(1)}
                      </div>
                    </div>
                    <p className="text-xs text-muted mt-1">{t('fleet.latest')}: {latest.toFixed(1)} {t('fleet.mpg')}</p>
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
            {t('fleet.irsMileageDeduction')}
          </h3>
          <p className="text-xs text-muted mb-4">
            {t('fleet.irsMileageDisclaimer')}
          </p>
          {uniqueVehicles.length === 0 ? (
            <p className="text-sm text-muted">{t('fleet.noFuelDataDeductions')}</p>
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
                    <p className="text-xs text-muted mt-1">{t('fleet.milesTracked', { miles: formatNumber(milesDriven) })}</p>
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
  const { t } = useTranslation();
  const [expandedInspection, setExpandedInspection] = useState<string | null>(null);
  const [showChecklist, setShowChecklist] = useState(false);

  const resultConfig: Record<string, { tKey: string; variant: 'success' | 'error' | 'warning' }> = {
    pass: { tKey: 'fleet.resultPass', variant: 'success' },
    fail: { tKey: 'fleet.resultFail', variant: 'error' },
    missing: { tKey: 'fleet.resultMissing', variant: 'warning' },
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
                <p className="text-sm text-muted">{t('common.totalInspections')}</p>
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
                <p className="text-sm text-muted">{t('fleet.passed')}</p>
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
                <p className="text-sm text-muted">{t('common.failed')}</p>
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
                <p className="text-sm text-muted">{t('fleet.passRate')}</p>
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
              {f === 'all' ? t('common.all') : f === 'pass' ? t('fleet.passed') : f === 'fail' ? t('common.failed') : t('fleet.resultMissing')}
            </button>
          ))}
        </div>
        <Button
          variant="secondary"
          onClick={() => setShowChecklist(!showChecklist)}
        >
          <Eye size={16} />
          {showChecklist ? t('fleet.hideDotChecklist') : t('fleet.viewDotChecklist')}
        </Button>
      </div>

      {/* DOT Checklist Reference */}
      {showChecklist && (
        <Card>
          <CardContent className="p-5">
            <h3 className="text-sm font-medium text-main mb-3 flex items-center gap-2">
              <ClipboardCheck size={15} />
              {t('fleet.dotChecklistTitle', { count: String(DOT_CHECKLIST_TKEYS.length) })}
            </h3>
            <p className="text-xs text-muted mb-4">
              {t('fleet.dotChecklistDesc')}
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
              {DOT_CHECKLIST_TKEYS.map((tKey, idx) => (
                <div key={idx} className="flex items-center gap-2 p-2 bg-secondary/30 border border-main rounded-lg text-sm">
                  <span className="text-xs text-muted font-mono w-5 text-right shrink-0">{idx + 1}.</span>
                  <span className="text-main">{t(tKey)}</span>
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
              <p>{t('fleet.noInspections')}</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-1" />
                <div className="col-span-3">{t('common.vehicle')}</div>
                <div className="col-span-2">{t('fleet.inspector')}</div>
                <div className="col-span-2">{t('common.date')}</div>
                <div className="col-span-1">{t('fleet.result')}</div>
                <div className="col-span-3">{t('fleet.score')}</div>
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
                        <Badge variant={rCfg.variant} dot>{t(rCfg.tKey)}</Badge>
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
                              {t('fleet.defectsFound')} ({insp.defects.length})
                            </h4>
                            {insp.defects.length === 0 ? (
                              <div className="flex items-center gap-2 p-3 bg-emerald-950/20 border border-emerald-800/30 rounded-lg">
                                <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                                <p className="text-sm text-emerald-300">{t('fleet.noDefectsFound')}</p>
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
                              {t('fleet.inspectionSummary')}
                            </h4>
                            <div className="space-y-3">
                              <div className="grid grid-cols-3 gap-3">
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-emerald-400">{insp.itemsPassed}</p>
                                  <p className="text-xs text-muted">{t('fleet.passed')}</p>
                                </div>
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-red-400">{insp.itemsFailed}</p>
                                  <p className="text-xs text-muted">{t('common.failed')}</p>
                                </div>
                                <div className="p-3 bg-surface border border-main rounded-lg text-center">
                                  <p className="text-lg font-semibold text-main">{insp.totalItems}</p>
                                  <p className="text-xs text-muted">{t('fleet.totalItems')}</p>
                                </div>
                              </div>
                              {insp.notes && (
                                <div className="p-3 bg-surface border border-main rounded-lg">
                                  <p className="text-xs text-muted mb-1">{t('fleet.inspectorNotes')}</p>
                                  <p className="text-sm text-main">{insp.notes}</p>
                                </div>
                              )}
                              <div className="p-3 bg-surface border border-main rounded-lg">
                                <p className="text-xs text-muted mb-1">{t('fleet.overallResult')}</p>
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
                                      ? t('fleet.vehicleClearedForService')
                                      : t('fleet.vehicleRequiresRepairs')}
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
            {t('fleet.missingInspectionAlerts')}
          </h3>
          <p className="text-xs text-muted mb-4">
            {t('fleet.missingInspectionDesc')}
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
                          {alert.lastInspection ? t('fleet.lastInspection', { date: formatDate(alert.lastInspection) }) : t('fleet.noInspectionsRecorded')}
                        </p>
                      </div>
                    </div>
                    <Badge variant="warning" size="sm">
                      {alert.daysMissing > 0
                        ? t('fleet.daysOverdue', { count: String(alert.daysMissing) })
                        : t('fleet.dueToday')}
                    </Badge>
                  </div>
                ))}
                {missingAlerts.length < activeVehicleCount && (
                  <div className="flex items-center gap-2 p-3 bg-secondary/30 border border-main rounded-lg">
                    <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                    <p className="text-sm text-muted">{t('fleet.allOtherVehiclesInspected')}</p>
                  </div>
                )}
              </>
            ) : activeVehicleCount > 0 ? (
              <div className="flex items-center gap-2 p-3 bg-emerald-950/20 border border-emerald-800/30 rounded-lg">
                <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
                <p className="text-sm text-emerald-300">{t('fleet.allVehiclesInspected')}</p>
              </div>
            ) : (
              <div className="flex items-center gap-2 p-3 bg-secondary/30 border border-main rounded-lg">
                <ClipboardCheck size={16} className="text-muted shrink-0" />
                <p className="text-sm text-muted">{t('fleet.noActiveVehicles')}</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
