import { APP_CONSTANTS } from './constants';

/** Format a date string to a readable local format. */
export function formatDate(value: string | Date | null | undefined, options?: Intl.DateTimeFormatOptions): string {
  if (!value) return '—';
  const date = typeof value === 'string' ? new Date(value) : value;
  if (Number.isNaN(date.getTime())) return '—';
  return new Intl.DateTimeFormat('en-PH', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    ...options,
  }).format(date);
}

/** Format a full date-time string. */
export function formatDateTime(value: string | Date): string {
  return formatDate(value, {
    hour: 'numeric',
    minute: '2-digit',
  });
}

/** Format a number to Philippine Peso currency. */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-PH', {
    style: 'currency',
    currency: 'PHP',
  }).format(value);
}

/** Format a number with thousands separators. */
export function formatNumber(value: number): string {
  return new Intl.NumberFormat('en-PH').format(value);
}

/** Convert a string to title case. */
export function titleCase(value: string): string {
  return value
    .split(/[\s_-]+/)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(' ');
}

/** Relative time from a given date. */
export function timeAgo(value: string | Date): string {
  const date = typeof value === 'string' ? new Date(value) : value;
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  const intervals: [number, string][] = [
    [31536000, 'year'],
    [2592000, 'month'],
    [604800, 'week'],
    [86400, 'day'],
    [3600, 'hour'],
    [60, 'minute'],
  ];
  for (const [secs, label] of intervals) {
    const count = Math.floor(seconds / secs);
    if (count >= 1) return `${count} ${label}${count > 1 ? 's' : ''} ago`;
  }
  return 'just now';
}

/** Returns the currency symbol. */
export function currencySymbol(): string {
  return APP_CONSTANTS.currency;
}

/** Format a number into an ordinal string (e.g. 1st, 2nd, 3rd, 4th). */
export function formatOrdinal(value: number): string {
  if (!Number.isFinite(value)) return '—';

  const n = Math.abs(Math.floor(value));
  const mod100 = n % 100;

  // Handle teens (11th, 12th, 13th)
  if (mod100 >= 11 && mod100 <= 13) {
    return `${value}th`;
  }

  const mod10 = n % 10;
  switch (mod10) {
    case 1:
      return `${value}st`;
    case 2:
      return `${value}nd`;
    case 3:
      return `${value}rd`;
    default:
      return `${value}th`;
  }
}

/** Format remaining days until due date (e.g. "14 days left", "Due today", "Overdue by 3 days"). */
export function daysLeft(value: string | Date): string {
  const targetDate = new Date(value);

  if (isNaN(targetDate.getTime())) {
    return 'Invalid date';
  }

  // Normalize both dates to midnight (start of day) to avoid time-of-day offsets
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const startOfTarget = new Date(targetDate);
  startOfTarget.setHours(0, 0, 0, 0);

  const msPerDay = 1000 * 60 * 60 * 24;
  const diffDays = Math.round((startOfTarget.getTime() - startOfToday.getTime()) / msPerDay);

  if (diffDays > 1) return `${diffDays} days left`;
  if (diffDays === 1) return '1 day left';
  if (diffDays === 0) return 'Due today';
  if (diffDays === -1) return 'Overdue by 1 day';
  return `Overdue by ${Math.abs(diffDays)} days`;
}