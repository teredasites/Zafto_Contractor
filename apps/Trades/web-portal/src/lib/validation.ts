// ============================================================
// Form Validation Utilities
// Centralized validation for all CRM forms
// ============================================================

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

export function isValidPhone(phone: string): boolean {
  const digits = phone.replace(/\D/g, '');
  return digits.length >= 10 && digits.length <= 15;
}

export function formatPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 10) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
  }
  if (digits.length === 11 && digits[0] === '1') {
    return `(${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
  }
  return phone;
}

export function isValidZip(zip: string): boolean {
  return /^\d{5}(-\d{4})?$/.test(zip.trim());
}

export function isPositiveNumber(value: string | number): boolean {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  return !isNaN(num) && num >= 0;
}

export function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, value));
}

export function clampTaxRate(value: number): number {
  return Math.max(0, Math.min(100, value));
}

export function parseCurrency(value: string): number {
  const cleaned = value.replace(/[^0-9.-]/g, '');
  const num = parseFloat(cleaned);
  return isNaN(num) ? 0 : Math.max(0, Math.round(num * 100) / 100);
}

export interface ValidationError {
  field: string;
  message: string;
}

export function validateRequired(value: string | null | undefined, fieldName: string): ValidationError | null {
  if (!value || !value.trim()) {
    return { field: fieldName, message: `${fieldName} is required` };
  }
  return null;
}

export function validateEmail(email: string, fieldName: string = 'Email'): ValidationError | null {
  if (!email.trim()) return null; // optional unless combined with validateRequired
  if (!isValidEmail(email)) {
    return { field: fieldName, message: 'Invalid email address' };
  }
  return null;
}

export function validatePhone(phone: string, fieldName: string = 'Phone'): ValidationError | null {
  if (!phone.trim()) return null;
  if (!isValidPhone(phone)) {
    return { field: fieldName, message: 'Invalid phone number' };
  }
  return null;
}

export function validatePositiveAmount(value: string | number, fieldName: string): ValidationError | null {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num) || num < 0) {
    return { field: fieldName, message: `${fieldName} must be a positive number` };
  }
  return null;
}
