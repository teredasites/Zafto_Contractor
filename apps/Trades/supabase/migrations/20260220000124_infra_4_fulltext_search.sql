-- INFRA-4: Full-text search foundation
-- S143: TSVECTOR columns, GIN indexes, auto-update triggers on core searchable tables

-- ============================================================
-- Generic search vector update function
-- ============================================================
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.search_text, '')
  );
  RETURN NEW;
END;
$$;

-- ============================================================
-- customers: name, email, phone, address, city, notes
-- ============================================================
ALTER TABLE customers ADD COLUMN IF NOT EXISTS search_text TEXT GENERATED ALWAYS AS (
  coalesce(name, '') || ' ' ||
  coalesce(email, '') || ' ' ||
  coalesce(phone, '') || ' ' ||
  coalesce(alternate_phone, '') || ' ' ||
  coalesce(address, '') || ' ' ||
  coalesce(city, '') || ' ' ||
  coalesce(state, '') || ' ' ||
  coalesce(zip_code, '') || ' ' ||
  coalesce(notes, '')
) STORED;

ALTER TABLE customers ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_customers_search ON customers USING GIN (search_vector);

CREATE OR REPLACE FUNCTION customers_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.email, '') || ' ' ||
    coalesce(NEW.phone, '') || ' ' ||
    coalesce(NEW.address, '') || ' ' ||
    coalesce(NEW.city, '') || ' ' ||
    coalesce(NEW.notes, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS customers_search_update ON customers;
CREATE TRIGGER customers_search_update
  BEFORE INSERT OR UPDATE OF name, email, phone, alternate_phone, address, city, state, zip_code, notes
  ON customers FOR EACH ROW EXECUTE FUNCTION customers_search_trigger();

-- ============================================================
-- jobs: title, description, address, notes
-- ============================================================
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_jobs_search ON jobs USING GIN (search_vector);

CREATE OR REPLACE FUNCTION jobs_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.title, '') || ' ' ||
    coalesce(NEW.description, '') || ' ' ||
    coalesce(NEW.address, '') || ' ' ||
    coalesce(NEW.notes, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS jobs_search_update ON jobs;
CREATE TRIGGER jobs_search_update
  BEFORE INSERT OR UPDATE OF title, description, address, notes
  ON jobs FOR EACH ROW EXECUTE FUNCTION jobs_search_trigger();

-- ============================================================
-- invoices: invoice_number, notes
-- ============================================================
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_invoices_search ON invoices USING GIN (search_vector);

CREATE OR REPLACE FUNCTION invoices_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.invoice_number, '') || ' ' ||
    coalesce(NEW.notes, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS invoices_search_update ON invoices;
CREATE TRIGGER invoices_search_update
  BEFORE INSERT OR UPDATE OF invoice_number, notes
  ON invoices FOR EACH ROW EXECUTE FUNCTION invoices_search_trigger();

-- ============================================================
-- estimates: title, notes, description
-- ============================================================
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_estimates_search ON estimates USING GIN (search_vector);

CREATE OR REPLACE FUNCTION estimates_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.title, '') || ' ' ||
    coalesce(NEW.notes, '') || ' ' ||
    coalesce(NEW.description, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS estimates_search_update ON estimates;
CREATE TRIGGER estimates_search_update
  BEFORE INSERT OR UPDATE OF title, notes, description
  ON estimates FOR EACH ROW EXECUTE FUNCTION estimates_search_trigger();

-- ============================================================
-- properties: address, city, state, zip_code, notes, property_type
-- ============================================================
ALTER TABLE properties ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_properties_search ON properties USING GIN (search_vector);

CREATE OR REPLACE FUNCTION properties_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.address, '') || ' ' ||
    coalesce(NEW.city, '') || ' ' ||
    coalesce(NEW.state, '') || ' ' ||
    coalesce(NEW.zip_code, '') || ' ' ||
    coalesce(NEW.notes, '') || ' ' ||
    coalesce(NEW.property_type, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS properties_search_update ON properties;
CREATE TRIGGER properties_search_update
  BEFORE INSERT OR UPDATE OF address, city, state, zip_code, notes, property_type
  ON properties FOR EACH ROW EXECUTE FUNCTION properties_search_trigger();

-- ============================================================
-- leads: name, email, phone, address, notes, source
-- ============================================================
ALTER TABLE leads ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
CREATE INDEX IF NOT EXISTS idx_leads_search ON leads USING GIN (search_vector);

CREATE OR REPLACE FUNCTION leads_search_trigger()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.email, '') || ' ' ||
    coalesce(NEW.phone, '') || ' ' ||
    coalesce(NEW.address, '') || ' ' ||
    coalesce(NEW.notes, '') || ' ' ||
    coalesce(NEW.source, '')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS leads_search_update ON leads;
CREATE TRIGGER leads_search_update
  BEFORE INSERT OR UPDATE OF name, email, phone, address, notes, source
  ON leads FOR EACH ROW EXECUTE FUNCTION leads_search_trigger();

-- ============================================================
-- Backfill existing data (run once)
-- ============================================================
UPDATE customers SET search_vector = to_tsvector('english',
  coalesce(name, '') || ' ' || coalesce(email, '') || ' ' || coalesce(phone, '') || ' ' ||
  coalesce(address, '') || ' ' || coalesce(city, '') || ' ' || coalesce(notes, '')
) WHERE search_vector IS NULL;

UPDATE jobs SET search_vector = to_tsvector('english',
  coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
  coalesce(address, '') || ' ' || coalesce(notes, '')
) WHERE search_vector IS NULL;

UPDATE invoices SET search_vector = to_tsvector('english',
  coalesce(invoice_number, '') || ' ' || coalesce(notes, '')
) WHERE search_vector IS NULL;

UPDATE estimates SET search_vector = to_tsvector('english',
  coalesce(title, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(description, '')
) WHERE search_vector IS NULL;

UPDATE properties SET search_vector = to_tsvector('english',
  coalesce(address, '') || ' ' || coalesce(city, '') || ' ' || coalesce(state, '') || ' ' ||
  coalesce(zip_code, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(property_type, '')
) WHERE search_vector IS NULL;

UPDATE leads SET search_vector = to_tsvector('english',
  coalesce(name, '') || ' ' || coalesce(email, '') || ' ' || coalesce(phone, '') || ' ' ||
  coalesce(address, '') || ' ' || coalesce(notes, '') || ' ' || coalesce(source, '')
) WHERE search_vector IS NULL;
