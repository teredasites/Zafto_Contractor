# Flutter-Writable Tables

Tables that the Flutter mobile app performs INSERT or UPDATE operations on.
When adding new columns to these tables, they MUST be nullable with defaults
for at least 2 app update cycles (~4 weeks).

**Rationale:** Web portals deploy instantly via Vercel. Flutter goes through
app stores (1-3 day review). Users on older versions send the old `toJson()`
without new columns — causes silent failures or crashes.

**Rule:** NEVER add `NOT NULL` without `DEFAULT` on Flutter-writable tables.

## Tables (as of S143)

| Table | Flutter Operations | Key Columns |
|-------|-------------------|-------------|
| customers | INSERT, UPDATE | name, email, phone, address, city, state, zip_code, notes |
| jobs | INSERT, UPDATE | title, description, status, address, total_price, notes |
| estimates | INSERT, UPDATE | title, description, status, total, notes |
| invoices | INSERT, UPDATE | invoice_number, status, total, due_date, notes |
| time_entries | INSERT, UPDATE | user_id, job_id, clock_in, clock_out, hours, notes |
| inspections | INSERT, UPDATE | template_id, property_id, status, findings, notes |
| walkthrough_items | INSERT, UPDATE | walkthrough_id, room_name, photos, notes |
| walkthroughs | INSERT, UPDATE | property_id, status, notes |
| properties | INSERT, UPDATE | address, city, state, zip_code, property_type, notes |
| schedules | INSERT, UPDATE | job_id, assigned_to, start_date, end_date, notes |
| bids | INSERT, UPDATE | job_id, amount, status, notes |
| change_orders | INSERT, UPDATE | job_id, description, amount, status |
| daily_logs | INSERT, UPDATE | job_id, date, weather, notes, activities |
| photos | INSERT | job_id, walkthrough_id, file_path, caption |
| voice_notes | INSERT | job_id, file_path, duration, transcript |
| receipts | INSERT | job_id, amount, vendor, category, photo_path |
| signatures | INSERT | document_id, signer_name, signature_data |
| mileage_trips | INSERT, UPDATE | start_location, end_location, miles, purpose |
| punch_list_items | INSERT, UPDATE | job_id, description, status, assigned_to |
| leads | INSERT, UPDATE | name, email, phone, address, source, status, notes |
| contacts | INSERT, UPDATE | customer_id, name, email, phone, role |

## Migration Safety Checklist

Before adding a new column to any table above:

- [ ] Column is nullable OR has a DEFAULT value
- [ ] Column is NOT referenced in any existing Flutter `toJson()` method (would be missing from old app versions)
- [ ] If column affects queries (filters, sorts), add index in the same migration
- [ ] Update this document with the new column
