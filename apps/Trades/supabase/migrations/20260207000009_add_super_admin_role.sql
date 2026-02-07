-- Migration: Add super_admin and cpa roles to users table
-- Sprint C3 fix: Ops Portal requires super_admin role

-- Drop existing CHECK constraint and recreate with super_admin + cpa
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (
  role IN ('owner', 'admin', 'office_manager', 'technician', 'apprentice', 'cpa', 'super_admin')
);
