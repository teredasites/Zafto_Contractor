-- U13a: Add preferred_locale to client_portal_users
ALTER TABLE client_portal_users
  ADD COLUMN IF NOT EXISTS preferred_locale TEXT DEFAULT 'en';

COMMENT ON COLUMN client_portal_users.preferred_locale IS 'Client preferred locale: en, es, pt-BR, pl, zh, ht, ru, ko, vi, tl';
