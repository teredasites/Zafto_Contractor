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
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';
import {
  useFleet,
  type Vehicle,
  type VehicleMaintenance,
  type FuelLog,
  type VehicleStatus,
  type MaintenanceStatus,
} from '@/lib/hooks/use-fleet';
import { useTranslation } from '@/lib/translations';

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

// ────────────────────────────────────────────────────────
// Page
// ────────────────────────────────────────────────────────

export default function FleetPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedVehicle, setExpandedVehicle] = useState<string | null>(null);
  const {
    vehicles,
    maintenance,
    fuelLogs,
    loading,
    activeVehicles,
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

  // ── Filtering ──
  const filteredVehicles = useMemo(() => {
    return vehicles.filter((v) => {
      const matchesSearch =
        v.vehicleName.toLowerCase().includes(search.toLowerCase()) ||
        (v.make || '').toLowerCase().includes(search.toLowerCase()) ||
        (v.model || '').toLowerCase().includes(search.toLowerCase()) ||
        (v.licensePlate || '').toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || v.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [vehicles, search, statusFilter]);

  // ── Helpers to get related data ──
  const getMaintenanceForVehicle = (vehicleId: string) =>
    maintenance.filter((m) => m.vehicleId === vehicleId);

  const getFuelLogsForVehicle = (vehicleId: string) =>
    fuelLogs.filter((f) => f.vehicleId === vehicleId);

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
          {filteredVehicles.length === 0 ? (
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

              {filteredVehicles.map((vehicle) => {
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
// Expanded Detail
// ────────────────────────────────────────────────────────

function VehicleDetail({
  maintenance,
  fuelLogs,
}: {
  maintenance: VehicleMaintenance[];
  fuelLogs: FuelLog[];
}) {
  const { t } = useTranslation();
  return (
    <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
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
                      {f.gallons.toFixed(1)} gal @ ${f.pricePerGallon.toFixed(2)}/gal
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
