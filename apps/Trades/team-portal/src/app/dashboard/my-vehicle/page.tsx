'use client';

import { useState } from 'react';
import {
  Car, Fuel, Wrench, AlertTriangle, CheckCircle2,
  Calendar, Plus, X, MapPin, Gauge,
} from 'lucide-react';
import { useMyVehicle } from '@/lib/hooks/use-my-vehicle';
import type { FuelLogInput, MaintenanceRequestInput } from '@/lib/hooks/use-my-vehicle';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn, formatCurrency, formatDate } from '@/lib/utils';

// ============================================================
// SKELETON
// ============================================================

function VehicleSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="h-8 w-48 bg-surface-hover animate-pulse rounded" />
      <div className="h-40 bg-surface-hover animate-pulse rounded-xl" />
      <div className="grid grid-cols-2 gap-4">
        {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
    </div>
  );
}

// ============================================================
// TYPES
// ============================================================

type Tab = 'overview' | 'maintenance' | 'fuel';

const VEHICLE_STATUS_STYLES: Record<string, { label: string; variant: 'success' | 'warning' | 'error' | 'default' }> = {
  active: { label: 'Active', variant: 'success' },
  maintenance: { label: 'In Maintenance', variant: 'warning' },
  out_of_service: { label: 'Out of Service', variant: 'error' },
  retired: { label: 'Retired', variant: 'default' },
};

const MAINT_STATUS_STYLES: Record<string, { label: string; variant: 'success' | 'warning' | 'info' | 'default' }> = {
  scheduled: { label: 'Scheduled', variant: 'info' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'default' },
};

// ============================================================
// MAIN PAGE
// ============================================================

export default function MyVehiclePage() {
  const {
    vehicle, upcomingMaintenance, completedMaintenance, fuelLogs,
    loading, error,
    addFuelLog, reportIssue,
  } = useMyVehicle();

  const [activeTab, setActiveTab] = useState<Tab>('overview');
  const [showFuelForm, setShowFuelForm] = useState(false);
  const [showIssueForm, setShowIssueForm] = useState(false);

  // Fuel log form state
  const [fuelDate, setFuelDate] = useState(new Date().toISOString().split('T')[0]);
  const [fuelGallons, setFuelGallons] = useState('');
  const [fuelCost, setFuelCost] = useState('');
  const [fuelMileage, setFuelMileage] = useState('');
  const [fuelStation, setFuelStation] = useState('');
  const [fuelSubmitting, setFuelSubmitting] = useState(false);
  const [fuelError, setFuelError] = useState<string | null>(null);

  // Issue form state
  const [issueType, setIssueType] = useState('general');
  const [issueDesc, setIssueDesc] = useState('');
  const [issueSubmitting, setIssueSubmitting] = useState(false);
  const [issueError, setIssueError] = useState<string | null>(null);

  const handleFuelSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFuelSubmitting(true);
    setFuelError(null);
    try {
      const input: FuelLogInput = {
        logDate: fuelDate,
        gallons: parseFloat(fuelGallons),
        totalCost: parseFloat(fuelCost),
        mileage: parseInt(fuelMileage, 10),
        station: fuelStation,
      };
      await addFuelLog(input);
      setFuelGallons('');
      setFuelCost('');
      setFuelMileage('');
      setFuelStation('');
      setShowFuelForm(false);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to add fuel log';
      setFuelError(msg);
    } finally {
      setFuelSubmitting(false);
    }
  };

  const handleIssueSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIssueSubmitting(true);
    setIssueError(null);
    try {
      const input: MaintenanceRequestInput = {
        maintenanceType: issueType,
        description: issueDesc,
      };
      await reportIssue(input);
      setIssueDesc('');
      setIssueType('general');
      setShowIssueForm(false);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Failed to report issue';
      setIssueError(msg);
    } finally {
      setIssueSubmitting(false);
    }
  };

  if (loading) return <VehicleSkeleton />;

  const tabs: { key: Tab; label: string; icon: React.ReactNode }[] = [
    { key: 'overview', label: 'Overview', icon: <Car size={16} /> },
    { key: 'maintenance', label: 'Maintenance', icon: <Wrench size={16} /> },
    { key: 'fuel', label: 'Fuel Log', icon: <Fuel size={16} /> },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">My Fleet</h1>
        <p className="text-sm text-muted mt-1">
          Your assigned vehicle, maintenance, and fuel tracking
        </p>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* No vehicle assigned */}
      {!vehicle ? (
        <div className="flex flex-col items-center justify-center py-16">
          <Car size={40} className="text-muted opacity-30 mb-3" />
          <p className="text-main font-medium">No vehicle assigned</p>
          <p className="text-sm text-muted mt-1">Contact your admin to get a vehicle assigned to you.</p>
        </div>
      ) : (
        <>
          {/* Vehicle Card */}
          <Card>
            <CardContent className="p-5">
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-xl bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center flex-shrink-0">
                  <Car size={28} className="text-blue-600 dark:text-blue-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h2 className="text-lg font-bold text-main">
                      {vehicle.year} {vehicle.make} {vehicle.model}
                    </h2>
                    <Badge variant={VEHICLE_STATUS_STYLES[vehicle.status]?.variant || 'default'}>
                      {VEHICLE_STATUS_STYLES[vehicle.status]?.label || vehicle.status}
                    </Badge>
                  </div>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-3">
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wider">Plate</p>
                      <p className="text-sm font-semibold text-main">{vehicle.licensePlate || '--'}</p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wider">Mileage</p>
                      <p className="text-sm font-semibold text-main">{vehicle.currentMileage.toLocaleString()} mi</p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wider">Color</p>
                      <p className="text-sm font-semibold text-main">{vehicle.color || '--'}</p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wider">VIN</p>
                      <p className="text-sm font-semibold text-main truncate">{vehicle.vin || '--'}</p>
                    </div>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Tabs */}
          <div className="flex gap-1 p-1 bg-secondary rounded-lg">
            {tabs.map((tab) => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={cn(
                  'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors flex-1 justify-center',
                  activeTab === tab.key
                    ? 'bg-surface text-main shadow-sm'
                    : 'text-muted hover:text-main'
                )}
              >
                {tab.icon}
                {tab.label}
              </button>
            ))}
          </div>

          {/* Overview Tab */}
          {activeTab === 'overview' && (
            <div className="space-y-4">
              {/* Quick info cards */}
              <div className="grid grid-cols-2 gap-3">
                {vehicle.insuranceExpiry && (
                  <div className="bg-surface border border-main rounded-xl p-4">
                    <p className="text-[11px] text-muted uppercase tracking-wider mb-1">Insurance Expires</p>
                    <p className="text-sm font-semibold text-main">{formatDate(vehicle.insuranceExpiry)}</p>
                  </div>
                )}
                {vehicle.registrationExpiry && (
                  <div className="bg-surface border border-main rounded-xl p-4">
                    <p className="text-[11px] text-muted uppercase tracking-wider mb-1">Registration Expires</p>
                    <p className="text-sm font-semibold text-main">{formatDate(vehicle.registrationExpiry)}</p>
                  </div>
                )}
                {vehicle.lastInspection && (
                  <div className="bg-surface border border-main rounded-xl p-4">
                    <p className="text-[11px] text-muted uppercase tracking-wider mb-1">Last Inspection</p>
                    <p className="text-sm font-semibold text-main">{formatDate(vehicle.lastInspection)}</p>
                  </div>
                )}
                <div className="bg-surface border border-main rounded-xl p-4">
                  <p className="text-[11px] text-muted uppercase tracking-wider mb-1">Odometer</p>
                  <p className="text-sm font-semibold text-main">{vehicle.currentMileage.toLocaleString()} mi</p>
                </div>
              </div>

              {/* Upcoming maintenance preview */}
              {upcomingMaintenance.length > 0 && (
                <Card>
                  <CardHeader>
                    <CardTitle>Upcoming Maintenance</CardTitle>
                  </CardHeader>
                  <CardContent className="py-2">
                    {upcomingMaintenance.slice(0, 3).map(m => (
                      <div key={m.id} className="flex items-center gap-3 py-2.5 border-b border-main last:border-0">
                        <Wrench size={16} className="text-amber-500 flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-main truncate">{m.description || m.maintenanceType}</p>
                          {m.scheduledDate && (
                            <p className="text-xs text-muted">{formatDate(m.scheduledDate)}</p>
                          )}
                        </div>
                        <Badge variant={MAINT_STATUS_STYLES[m.status]?.variant || 'default'}>
                          {MAINT_STATUS_STYLES[m.status]?.label || m.status}
                        </Badge>
                      </div>
                    ))}
                  </CardContent>
                </Card>
              )}

              {/* Report Issue button */}
              <Button
                variant="secondary"
                onClick={() => setShowIssueForm(!showIssueForm)}
                className="w-full"
              >
                <AlertTriangle size={16} />
                Report Vehicle Issue
              </Button>

              {/* Issue Form */}
              {showIssueForm && (
                <Card>
                  <CardContent>
                    <form onSubmit={handleIssueSubmit} className="space-y-4">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-main">Report Issue</p>
                        <button type="button" onClick={() => setShowIssueForm(false)} className="p-1 rounded hover:bg-surface-hover">
                          <X size={16} className="text-muted" />
                        </button>
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-main">Issue Type</label>
                        <select
                          value={issueType}
                          onChange={(e) => setIssueType(e.target.value)}
                          className="w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main text-[15px] focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent"
                        >
                          <option value="general">General</option>
                          <option value="engine">Engine</option>
                          <option value="brakes">Brakes</option>
                          <option value="tires">Tires</option>
                          <option value="electrical">Electrical</option>
                          <option value="body_damage">Body Damage</option>
                          <option value="fluid_leak">Fluid Leak</option>
                          <option value="hvac">HVAC</option>
                          <option value="other">Other</option>
                        </select>
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-main">Description</label>
                        <textarea
                          rows={3}
                          value={issueDesc}
                          onChange={(e) => setIssueDesc(e.target.value)}
                          placeholder="Describe the issue..."
                          required
                          className="w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent text-[15px] resize-none"
                        />
                      </div>

                      {issueError && <p className="text-xs text-red-500">{issueError}</p>}

                      <Button type="submit" loading={issueSubmitting} disabled={!issueDesc.trim()}>
                        <AlertTriangle size={14} />
                        Submit Report
                      </Button>
                    </form>
                  </CardContent>
                </Card>
              )}
            </div>
          )}

          {/* Maintenance Tab */}
          {activeTab === 'maintenance' && (
            <div className="space-y-4">
              {/* Upcoming */}
              {upcomingMaintenance.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-muted mb-2">Upcoming</p>
                  <div className="space-y-2">
                    {upcomingMaintenance.map(m => (
                      <Card key={m.id}>
                        <CardContent className="py-3.5">
                          <div className="flex items-center gap-3">
                            <div className="p-2 rounded-lg bg-amber-100 dark:bg-amber-900/30 flex-shrink-0">
                              <Calendar size={16} className="text-amber-600 dark:text-amber-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-main truncate">{m.description || m.maintenanceType}</p>
                              <p className="text-xs text-muted">{m.scheduledDate ? formatDate(m.scheduledDate) : 'Not scheduled'}</p>
                              {m.vendor && <p className="text-xs text-muted">{m.vendor}</p>}
                            </div>
                            <Badge variant={MAINT_STATUS_STYLES[m.status]?.variant || 'default'}>
                              {MAINT_STATUS_STYLES[m.status]?.label || m.status}
                            </Badge>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </div>
              )}

              {/* Completed */}
              {completedMaintenance.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-muted mb-2">History</p>
                  <div className="space-y-2">
                    {completedMaintenance.map(m => (
                      <Card key={m.id}>
                        <CardContent className="py-3.5">
                          <div className="flex items-center gap-3">
                            <div className="p-2 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex-shrink-0">
                              <CheckCircle2 size={16} className="text-emerald-600 dark:text-emerald-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-main truncate">{m.description || m.maintenanceType}</p>
                              <p className="text-xs text-muted">{m.completedDate ? formatDate(m.completedDate) : 'Completed'}</p>
                              {m.mileageAtService && (
                                <p className="text-xs text-muted">{m.mileageAtService.toLocaleString()} mi</p>
                              )}
                            </div>
                            {m.cost > 0 && (
                              <span className="text-sm font-medium text-main">{formatCurrency(m.cost)}</span>
                            )}
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                </div>
              )}

              {upcomingMaintenance.length === 0 && completedMaintenance.length === 0 && (
                <div className="flex flex-col items-center justify-center py-12">
                  <Wrench size={40} className="text-muted opacity-30 mb-3" />
                  <p className="text-main font-medium">No maintenance records</p>
                  <p className="text-sm text-muted mt-1">Maintenance records will appear here.</p>
                </div>
              )}
            </div>
          )}

          {/* Fuel Tab */}
          {activeTab === 'fuel' && (
            <div className="space-y-4">
              {/* Add Fuel Log button */}
              <Button onClick={() => setShowFuelForm(!showFuelForm)} className="w-full sm:w-auto">
                <Plus size={16} />
                Add Fuel Log
              </Button>

              {/* Fuel Log Form */}
              {showFuelForm && (
                <Card>
                  <CardContent>
                    <form onSubmit={handleFuelSubmit} className="space-y-4">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-main">New Fuel Log</p>
                        <button type="button" onClick={() => setShowFuelForm(false)} className="p-1 rounded hover:bg-surface-hover">
                          <X size={16} className="text-muted" />
                        </button>
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <Input
                          label="Date"
                          type="date"
                          value={fuelDate}
                          onChange={(e) => setFuelDate(e.target.value)}
                          required
                        />
                        <Input
                          label="Gallons"
                          type="number"
                          step="0.01"
                          placeholder="12.5"
                          value={fuelGallons}
                          onChange={(e) => setFuelGallons(e.target.value)}
                          required
                        />
                        <Input
                          label="Total Cost ($)"
                          type="number"
                          step="0.01"
                          placeholder="45.00"
                          value={fuelCost}
                          onChange={(e) => setFuelCost(e.target.value)}
                          required
                        />
                        <Input
                          label="Odometer"
                          type="number"
                          placeholder="52340"
                          value={fuelMileage}
                          onChange={(e) => setFuelMileage(e.target.value)}
                          required
                        />
                      </div>

                      <Input
                        label="Station"
                        type="text"
                        placeholder="Shell on Main St"
                        value={fuelStation}
                        onChange={(e) => setFuelStation(e.target.value)}
                      />

                      {fuelError && <p className="text-xs text-red-500">{fuelError}</p>}

                      <Button type="submit" loading={fuelSubmitting}>
                        <Fuel size={14} />
                        Save Fuel Log
                      </Button>
                    </form>
                  </CardContent>
                </Card>
              )}

              {/* Fuel Log List */}
              {fuelLogs.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12">
                  <Fuel size={40} className="text-muted opacity-30 mb-3" />
                  <p className="text-main font-medium">No fuel logs yet</p>
                  <p className="text-sm text-muted mt-1">Add a fuel log to start tracking.</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {fuelLogs.map(log => (
                    <Card key={log.id}>
                      <CardContent className="py-3.5">
                        <div className="flex items-center gap-3">
                          <div className="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex-shrink-0">
                            <Fuel size={16} className="text-blue-600 dark:text-blue-400" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <p className="text-sm font-medium text-main">
                                {log.gallons.toFixed(2)} gal
                              </p>
                              <span className="text-xs text-muted">@ ${log.pricePerGallon.toFixed(3)}/gal</span>
                            </div>
                            <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
                              <span className="flex items-center gap-1">
                                <Calendar size={11} />
                                {formatDate(log.logDate)}
                              </span>
                              <span className="flex items-center gap-1">
                                <Gauge size={11} />
                                {log.mileage.toLocaleString()} mi
                              </span>
                              {log.station && (
                                <span className="flex items-center gap-1 truncate">
                                  <MapPin size={11} />
                                  {log.station}
                                </span>
                              )}
                            </div>
                          </div>
                          <div className="text-right flex-shrink-0">
                            <p className="text-sm font-semibold text-main">{formatCurrency(log.totalCost)}</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  );
}
