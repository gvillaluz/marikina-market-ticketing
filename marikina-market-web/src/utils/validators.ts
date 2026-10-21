/** Email validation. */
export function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

/** Philippine mobile number validation (e.g. 0917 123 4567). */
export function isValidPhone(value: string): boolean {
  const cleaned = value.replace(/[\s-]/g, '');
  return /^(\+?63|0)9\d{9}$/.test(cleaned);
}

/** Alphanumeric check. */
export function isAlphanumeric(value: string): boolean {
  return /^[a-zA-Z0-9]+$/.test(value);
}

/** Minimum length check. */
export function hasMinLength(value: string, min: number): boolean {
  return value.trim().length >= min;
}

/** Required field check. */
export function isRequired(value: string | undefined | null): boolean {
  return !!value && value.trim().length > 0;
}

/** Validate a ticket severity against allowed values. */
export function isValidSeverity(value: string): boolean {
  return ['low', 'medium', 'high', 'critical'].includes(value);
}
