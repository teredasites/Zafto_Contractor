-- T9e: TPA Schedule Integration Bridge
-- Since GC (Gantt/CPM) tables don't exist yet, create a staging table
-- that GC10 will consume when Schedule phase is built.
-- When TPA assignment is accepted → auto-queue for scheduling.

-- ============================================================================
-- TABLE: TPA SCHEDULE QUEUE — staging for future schedule integration
-- ============================================================================

CREATE TABLE tpa_schedule_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_assignment_id UUID NOT NULL REFERENCES tpa_assignments(id),
  job_id UUID REFERENCES jobs(id),
  -- Scheduling data
  sla_deadline TIMESTAMPTZ,
  estimated_duration_hours NUMERIC(6,1),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('urgent', 'high', 'normal', 'low')),
  loss_type TEXT,
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'consumed', 'cancelled')),
  scheduled_at TIMESTAMPTZ,  -- when it was picked up by the scheduler
  consumed_at TIMESTAMPTZ,   -- when GC consumed it into schedule_tasks
  schedule_task_id UUID,     -- FK to future schedule_tasks table
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE tpa_schedule_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY tsq_company ON tpa_schedule_queue
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_tsq_company ON tpa_schedule_queue(company_id);
CREATE INDEX idx_tsq_assignment ON tpa_schedule_queue(tpa_assignment_id);
CREATE INDEX idx_tsq_status ON tpa_schedule_queue(status) WHERE status = 'pending';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER tsq_updated BEFORE UPDATE ON tpa_schedule_queue FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- AUTO-QUEUE: When TPA assignment status changes to 'accepted' or 'scheduled'
-- ============================================================================

CREATE OR REPLACE FUNCTION tpa_auto_queue_schedule()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire when status changes to an active state
  IF NEW.status IN ('contacted', 'scheduled', 'onsite') AND OLD.status = 'received' THEN
    -- Check if not already queued
    IF NOT EXISTS (
      SELECT 1 FROM tpa_schedule_queue
      WHERE tpa_assignment_id = NEW.id AND status IN ('pending', 'scheduled')
    ) THEN
      INSERT INTO tpa_schedule_queue (
        company_id, tpa_assignment_id, job_id,
        sla_deadline, loss_type, priority
      ) VALUES (
        NEW.company_id, NEW.id, NEW.job_id,
        NEW.sla_deadline, NEW.loss_type,
        CASE
          WHEN NEW.loss_type IN ('water', 'fire', 'mold') THEN 'urgent'
          WHEN NEW.sla_deadline IS NOT NULL AND NEW.sla_deadline < (now() + interval '48 hours') THEN 'high'
          ELSE 'normal'
        END
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER tpa_schedule_auto_queue
  AFTER UPDATE OF status ON tpa_assignments
  FOR EACH ROW
  EXECUTE FUNCTION tpa_auto_queue_schedule();
