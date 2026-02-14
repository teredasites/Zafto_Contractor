-- J3: Smart Pricing Foundation Tables
-- pricing_rules: configurable rules per company/trade
-- pricing_suggestions: per-estimate suggested pricing with factor breakdown

-- ══════════════════════════════════════════════════════════
-- pricing_rules — configurable pricing rule definitions
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS pricing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  rule_type TEXT NOT NULL CHECK (rule_type IN (
    'demand_surge', 'distance_markup', 'seasonal', 'urgency',
    'complexity', 'repeat_customer', 'material_market', 'time_of_day'
  )),
  rule_config JSONB NOT NULL DEFAULT '{}',
  -- rule_config examples:
  --   demand_surge: { "threshold_pct": 80, "surge_multiplier": 1.15, "lookback_days": 7 }
  --   distance_markup: { "base_miles": 15, "per_mile_rate": 2.50, "max_markup": 150 }
  --   seasonal: { "peak_months": [6,7,8], "peak_multiplier": 1.10, "off_peak_discount": 0.95 }
  --   urgency: { "same_day_multiplier": 1.25, "next_day_multiplier": 1.10 }
  --   complexity: { "high_multiplier": 1.20, "medium_multiplier": 1.0 }
  --   repeat_customer: { "discount_pct": 5, "min_previous_jobs": 3 }
  --   material_market: { "index_source": "manual", "markup_pct": 8 }
  --   time_of_day: { "after_hours_multiplier": 1.50, "weekend_multiplier": 1.25 }
  trade_type TEXT,           -- NULL = all trades, or specific trade
  active BOOLEAN NOT NULL DEFAULT true,
  priority INT NOT NULL DEFAULT 0,  -- higher = applied first

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE pricing_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own pricing rules"
  ON pricing_rules FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage pricing rules"
  ON pricing_rules FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_pricing_rules_company ON pricing_rules(company_id);
CREATE INDEX idx_pricing_rules_type ON pricing_rules(rule_type);
CREATE INDEX idx_pricing_rules_active ON pricing_rules(active) WHERE active = true;

CREATE TRIGGER update_pricing_rules_updated_at
  BEFORE UPDATE ON pricing_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER pricing_rules_audit
  AFTER INSERT OR UPDATE OR DELETE ON pricing_rules
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ══════════════════════════════════════════════════════════
-- pricing_suggestions — per-estimate AI-suggested pricing
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS pricing_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  estimate_id UUID REFERENCES estimates(id),
  job_id UUID REFERENCES jobs(id),

  base_price NUMERIC(12,2) NOT NULL,         -- original estimate price
  suggested_price NUMERIC(12,2) NOT NULL,    -- price after rule application
  factors_applied JSONB NOT NULL DEFAULT '[]',
  -- factors_applied example:
  -- [
  --   { "rule_type": "demand_surge", "label": "High Demand", "adjustment_pct": 15, "amount": 450 },
  --   { "rule_type": "repeat_customer", "label": "Loyal Customer", "adjustment_pct": -5, "amount": -150 }
  -- ]
  final_price NUMERIC(12,2),                 -- price user actually chose (may differ from suggested)
  accepted BOOLEAN,                           -- did user accept the suggestion?
  job_won BOOLEAN,                            -- did the estimate convert to a job?

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE pricing_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members read own pricing suggestions"
  ON pricing_suggestions FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "Company members manage pricing suggestions"
  ON pricing_suggestions FOR ALL
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE INDEX idx_pricing_suggestions_company ON pricing_suggestions(company_id);
CREATE INDEX idx_pricing_suggestions_estimate ON pricing_suggestions(estimate_id);
CREATE INDEX idx_pricing_suggestions_accepted ON pricing_suggestions(accepted);
CREATE INDEX idx_pricing_suggestions_won ON pricing_suggestions(job_won) WHERE job_won IS NOT NULL;

CREATE TRIGGER update_pricing_suggestions_updated_at
  BEFORE UPDATE ON pricing_suggestions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER pricing_suggestions_audit
  AFTER INSERT OR UPDATE OR DELETE ON pricing_suggestions
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
