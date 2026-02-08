-- FM: Firebase → Supabase Migration — Payments + Credits Tables
-- Replaces Firestore collections: paymentIntents, payments, paymentFailures, users (credits), scans, purchases

-- ============================================================================
-- PAYMENT INTENTS (tracks Stripe PaymentIntent lifecycle)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_intents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  stripe_payment_intent_id TEXT NOT NULL UNIQUE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  customer_id UUID REFERENCES customers(id),
  payment_type TEXT NOT NULL CHECK (payment_type IN ('bid_deposit', 'invoice', 'subscription', 'credit_purchase')),
  reference_id UUID, -- bid_id or invoice_id
  amount INTEGER NOT NULL, -- cents
  currency TEXT NOT NULL DEFAULT 'usd',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed', 'canceled', 'requires_action')),
  failure_message TEXT,
  receipt_email TEXT,
  succeeded_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payment_intents_company ON payment_intents(company_id);
CREATE INDEX idx_payment_intents_stripe_id ON payment_intents(stripe_payment_intent_id);
CREATE INDEX idx_payment_intents_reference ON payment_intents(payment_type, reference_id);
CREATE INDEX idx_payment_intents_status ON payment_intents(status);

ALTER TABLE payment_intents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members can view payment intents"
  ON payment_intents FOR SELECT
  USING (company_id IN (
    SELECT company_id FROM users WHERE id = auth.uid()
  ));

CREATE POLICY "Authenticated users can create payment intents"
  ON payment_intents FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- PAYMENTS (confirmed successful payments — immutable audit trail)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  stripe_payment_intent_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  customer_id UUID REFERENCES customers(id),
  payment_type TEXT NOT NULL CHECK (payment_type IN ('bid_deposit', 'invoice', 'subscription', 'credit_purchase')),
  reference_id UUID,
  amount INTEGER NOT NULL, -- cents
  currency TEXT NOT NULL DEFAULT 'usd',
  status TEXT NOT NULL DEFAULT 'succeeded',
  receipt_email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_company ON payments(company_id);
CREATE INDEX idx_payments_reference ON payments(payment_type, reference_id);
CREATE INDEX idx_payments_stripe_id ON payments(stripe_payment_intent_id);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company members can view payments"
  ON payments FOR SELECT
  USING (company_id IN (
    SELECT company_id FROM users WHERE id = auth.uid()
  ));

-- INSERT via service role only (webhook handler)

-- ============================================================================
-- PAYMENT FAILURES (log for debugging — immutable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment_failures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_payment_intent_id TEXT NOT NULL,
  payment_type TEXT,
  reference_id UUID,
  error_message TEXT,
  error_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_payment_failures_stripe ON payment_failures(stripe_payment_intent_id);

ALTER TABLE payment_failures ENABLE ROW LEVEL SECURITY;

-- Only super_admin / service role can read failures
CREATE POLICY "Super admin can view payment failures"
  ON payment_failures FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'super_admin')
  );

-- ============================================================================
-- USER CREDITS (AI scan credits per user)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
  company_id UUID REFERENCES companies(id),
  free_credits INTEGER NOT NULL DEFAULT 3,
  paid_credits INTEGER NOT NULL DEFAULT 0,
  total_scans INTEGER NOT NULL DEFAULT 0,
  last_scan_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_credits_user ON user_credits(user_id);
CREATE INDEX idx_user_credits_company ON user_credits(company_id);

ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own credits"
  ON user_credits FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own credits"
  ON user_credits FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own credits"
  ON user_credits FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- SCAN LOGS (AI scan audit trail — immutable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS scan_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  company_id UUID REFERENCES companies(id),
  scan_type TEXT NOT NULL CHECK (scan_type IN ('panel', 'nameplate', 'wire', 'violation', 'smart', 'photo_diagnose', 'troubleshoot', 'parts_identify', 'repair_guide')),
  success BOOLEAN NOT NULL DEFAULT true,
  confidence NUMERIC(3,2),
  response_preview TEXT, -- first 500 chars
  credits_charged INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_scan_logs_user ON scan_logs(user_id);
CREATE INDEX idx_scan_logs_company ON scan_logs(company_id);
CREATE INDEX idx_scan_logs_type ON scan_logs(scan_type);
CREATE INDEX idx_scan_logs_created ON scan_logs(created_at DESC);

ALTER TABLE scan_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own scan logs"
  ON scan_logs FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own scan logs"
  ON scan_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- CREDIT PURCHASES (verified IAP/Stripe credit purchases — immutable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS credit_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  company_id UUID REFERENCES companies(id),
  product_id TEXT NOT NULL,
  transaction_id TEXT,
  credits_added INTEGER NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('revenuecat', 'stripe', 'manual', 'promo')),
  event_type TEXT, -- e.g. INITIAL_PURCHASE, NON_RENEWING_PURCHASE
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_credit_purchases_user ON credit_purchases(user_id);
CREATE INDEX idx_credit_purchases_product ON credit_purchases(product_id);

ALTER TABLE credit_purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own purchases"
  ON credit_purchases FOR SELECT
  USING (user_id = auth.uid());

-- INSERT via service role only (webhook handlers)

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_payment_intents_updated') THEN
    CREATE TRIGGER trg_payment_intents_updated
      BEFORE UPDATE ON payment_intents
      FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_user_credits_updated') THEN
    CREATE TRIGGER trg_user_credits_updated
      BEFORE UPDATE ON user_credits
      FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
  END IF;
END $$;
