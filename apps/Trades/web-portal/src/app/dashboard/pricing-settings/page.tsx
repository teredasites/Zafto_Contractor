'use client';

// J5: Smart Pricing Settings — configure pricing rules per trade

import { useState, useEffect, useCallback } from 'react';
import {
  Settings,
  Plus,
  ToggleLeft,
  ToggleRight,
  Trash2,
  Zap,
  MapPin,
  Sun,
  Clock,
  Brain,
  Repeat,
  TrendingUp,
  AlertTriangle,
} from 'lucide-react';
import { createClient } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

const supabase = createClient();

interface PricingRule {
  id: string;
  company_id: string;
  rule_type: string;
  rule_config: Record<string, unknown>;
  trade_type: string | null;
  active: boolean;
  priority: number;
  created_at: string;
}

const RULE_TYPES = [
  { type: 'demand_surge', label: 'Demand Surge', icon: Zap, description: 'Increase price when schedule is nearly full',
    defaults: { threshold_pct: 80, surge_multiplier: 1.15, lookback_days: 7, max_weekly_capacity: 20 } },
  { type: 'distance_markup', label: 'Distance Markup', icon: MapPin, description: 'Add markup based on drive distance',
    defaults: { base_miles: 15, per_mile_rate: 2.50, max_markup: 150 } },
  { type: 'seasonal', label: 'Seasonal', icon: Sun, description: 'Adjust pricing for peak/off-peak seasons',
    defaults: { peak_months: [6, 7, 8], peak_multiplier: 1.10, off_peak_discount: 0.95 } },
  { type: 'urgency', label: 'Urgency', icon: Clock, description: 'Premium for same-day or rush service',
    defaults: { same_day_multiplier: 1.25, next_day_multiplier: 1.10, emergency_multiplier: 1.50 } },
  { type: 'complexity', label: 'Complexity', icon: Brain, description: 'Adjust for high-complexity jobs',
    defaults: { high_multiplier: 1.20, medium_multiplier: 1.0 } },
  { type: 'repeat_customer', label: 'Repeat Customer', icon: Repeat, description: 'Loyalty discount for returning customers',
    defaults: { discount_pct: 5, min_previous_jobs: 3 } },
  { type: 'material_market', label: 'Material Market', icon: TrendingUp, description: 'Adjust for current material prices',
    defaults: { index_source: 'manual', markup_pct: 8 } },
  { type: 'time_of_day', label: 'Time of Day', icon: Clock, description: 'After-hours and weekend premiums',
    defaults: { after_hours_multiplier: 1.50, weekend_multiplier: 1.25 } },
];

export default function PricingSettingsPage() {
  const { t } = useTranslation();
  const [rules, setRules] = useState<PricingRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);

  const fetchRules = useCallback(async () => {
    const { data } = await supabase
      .from('pricing_rules')
      .select('*')
      .is('deleted_at', null)
      .order('priority', { ascending: false });
    setRules(data || []);
    setLoading(false);
  }, []);

  useEffect(() => { fetchRules(); }, [fetchRules]);

  const toggleRule = async (id: string, active: boolean) => {
    await supabase.from('pricing_rules').update({ active: !active }).eq('id', id);
    fetchRules();
  };

  const deleteRule = async (id: string) => {
    await supabase.from('pricing_rules').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    fetchRules();
  };

  const addRule = async (ruleType: string) => {
    const template = RULE_TYPES.find(r => r.type === ruleType);
    if (!template) return;

    const { data: { user } } = await supabase.auth.getUser();
    const companyId = user?.app_metadata?.company_id;
    if (!companyId) return;

    await supabase.from('pricing_rules').insert({
      company_id: companyId,
      rule_type: ruleType,
      rule_config: template.defaults,
      active: true,
      priority: rules.length,
    });

    setShowAdd(false);
    fetchRules();
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin h-8 w-8 border-2 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const existingTypes = new Set(rules.map(r => r.rule_type));
  const availableTypes = RULE_TYPES.filter(r => !existingTypes.has(r.type));

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-white flex items-center gap-3">
            <Settings className="h-6 w-6 text-zinc-400" />
            {t('pricingSettings.title')}
          </h1>
          <p className="text-sm text-zinc-500 mt-1">
            Configure automatic pricing adjustments for your estimates
          </p>
        </div>
        {availableTypes.length > 0 && (
          <button
            onClick={() => setShowAdd(!showAdd)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-500/10 border border-blue-500/30 rounded-lg text-blue-400 hover:bg-blue-500/20 transition-colors"
          >
            <Plus className="h-4 w-4" />
            <span className="text-sm font-medium">Add Rule</span>
          </button>
        )}
      </div>

      {/* Add Rule Panel */}
      {showAdd && (
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5 mb-6">
          <h3 className="text-sm font-medium text-zinc-300 mb-4">Choose a Rule Type</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {availableTypes.map((rt) => {
              const Icon = rt.icon;
              return (
                <button
                  key={rt.type}
                  onClick={() => addRule(rt.type)}
                  className="flex items-center gap-3 p-3 bg-zinc-700/30 border border-zinc-600/30 rounded-lg hover:bg-zinc-700/50 transition-colors text-left"
                >
                  <Icon className="h-5 w-5 text-blue-400 flex-shrink-0" />
                  <div>
                    <p className="text-sm font-medium text-zinc-200">{rt.label}</p>
                    <p className="text-xs text-zinc-500">{rt.description}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Rules List */}
      {rules.length === 0 ? (
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-12 text-center">
          <AlertTriangle className="h-12 w-12 text-zinc-600 mx-auto mb-4" />
          <p className="text-zinc-400">No pricing rules configured</p>
          <p className="text-zinc-600 text-sm mt-2">
            Add rules to automatically suggest optimized pricing on estimates
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {rules.map((rule) => {
            const template = RULE_TYPES.find(r => r.type === rule.rule_type);
            const Icon = template?.icon || Settings;

            return (
              <div
                key={rule.id}
                className={`rounded-xl p-5 border transition-colors ${
                  rule.active
                    ? 'bg-zinc-800/50 border-zinc-700/50'
                    : 'bg-zinc-800/20 border-zinc-700/20 opacity-60'
                }`}
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <Icon className={`h-5 w-5 ${rule.active ? 'text-blue-400' : 'text-zinc-600'}`} />
                    <div>
                      <p className="text-sm font-semibold text-zinc-200">
                        {template?.label || rule.rule_type}
                      </p>
                      <p className="text-xs text-zinc-500">
                        {template?.description || 'Custom rule'}
                        {rule.trade_type && ` — ${rule.trade_type}`}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => toggleRule(rule.id, rule.active)}
                      className="p-1.5 rounded-lg hover:bg-zinc-700/50 transition-colors"
                      title={rule.active ? 'Disable' : 'Enable'}
                    >
                      {rule.active ? (
                        <ToggleRight className="h-5 w-5 text-emerald-400" />
                      ) : (
                        <ToggleLeft className="h-5 w-5 text-zinc-600" />
                      )}
                    </button>
                    <button
                      onClick={() => deleteRule(rule.id)}
                      className="p-1.5 rounded-lg hover:bg-red-500/10 transition-colors"
                      title={t('common.delete')}
                    >
                      <Trash2 className="h-4 w-4 text-zinc-600 hover:text-red-400" />
                    </button>
                  </div>
                </div>

                {/* Config display */}
                <div className="flex flex-wrap gap-2">
                  {Object.entries(rule.rule_config).map(([key, val]) => (
                    <span
                      key={key}
                      className="text-xs bg-zinc-700/30 text-zinc-400 px-2 py-1 rounded"
                    >
                      {key.replace(/_/g, ' ')}: {Array.isArray(val) ? val.join(', ') : String(val)}
                    </span>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
