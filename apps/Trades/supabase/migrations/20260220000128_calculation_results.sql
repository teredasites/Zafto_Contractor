-- ============================================================
-- DEPTH6: Calculation Results — Save calculator outputs to jobs
-- ============================================================
-- Supports the "Save to Job" feature on all 1,073+ calculators.
-- Replaces Hive-only local storage with cloud persistence.
-- RLS: users can only see their own company's saved calculations.

CREATE TABLE IF NOT EXISTS public.calculation_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  calculator_id TEXT NOT NULL,       -- e.g. 'voltage_drop', 'btu_calc'
  calculator_name TEXT NOT NULL,     -- e.g. 'Voltage Drop Calculator'
  inputs JSONB NOT NULL DEFAULT '{}'::jsonb,
  outputs JSONB NOT NULL DEFAULT '{}'::jsonb,
  notes TEXT,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  tags TEXT[] DEFAULT '{}',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_calculation_results_company ON public.calculation_results(company_id);
CREATE INDEX idx_calculation_results_user ON public.calculation_results(user_id);
CREATE INDEX idx_calculation_results_job ON public.calculation_results(job_id);
CREATE INDEX idx_calculation_results_calculator ON public.calculation_results(calculator_id);
CREATE INDEX idx_calculation_results_favorite ON public.calculation_results(company_id, is_favorite) WHERE is_favorite = true AND deleted_at IS NULL;
CREATE INDEX idx_calculation_results_deleted ON public.calculation_results(deleted_at) WHERE deleted_at IS NULL;

-- Audit trigger for updated_at
CREATE TRIGGER set_calculation_results_updated_at
  BEFORE UPDATE ON public.calculation_results
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS
ALTER TABLE public.calculation_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own company calculations"
  ON public.calculation_results FOR SELECT
  USING (company_id IN (
    SELECT cm.company_id FROM public.company_members cm
    WHERE cm.user_id = auth.uid() AND cm.deleted_at IS NULL
  ) AND deleted_at IS NULL);

CREATE POLICY "Users can insert calculations for own company"
  ON public.calculation_results FOR INSERT
  WITH CHECK (company_id IN (
    SELECT cm.company_id FROM public.company_members cm
    WHERE cm.user_id = auth.uid() AND cm.deleted_at IS NULL
  ) AND user_id = auth.uid());

CREATE POLICY "Users can update own calculations"
  ON public.calculation_results FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can soft-delete own calculations"
  ON public.calculation_results FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

COMMENT ON TABLE public.calculation_results IS 'Saved calculator outputs linked to jobs. Supports favorites and tagging.';
