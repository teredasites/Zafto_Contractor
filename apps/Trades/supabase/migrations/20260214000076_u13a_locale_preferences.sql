-- ============================================================
-- U13a: Locale Preferences — user + company language settings
-- ============================================================

-- User preferred locale
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS preferred_locale TEXT DEFAULT 'en';

-- Company default locale
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS default_locale TEXT DEFAULT 'en';

-- Comment for documentation
COMMENT ON COLUMN users.preferred_locale IS 'User preferred locale: en, es, pt-BR, pl, zh, ht, ru, ko, vi, tl';
COMMENT ON COLUMN companies.default_locale IS 'Company default locale, individual users can override';
