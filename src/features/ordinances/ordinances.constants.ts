import type { Severity } from '@/api/types/common.types';
import type { TicketCategories } from '@/api/types/ticket.types';

// Keep this order aligned with the backend enum for numeric API responses.
export const CATEGORY_OPTIONS: readonly { value: TicketCategories; label: string }[] = [
  { value: 'Traffic', label: 'Traffic' },
  { value: 'Obstruction', label: 'Obstruction' },
  { value: 'Sanitation', label: 'Sanitation' },
  { value: 'Licensing', label: 'Licensing' },
  { value: 'Noise', label: 'Noise' },
  { value: 'WeightMeasures', label: 'Weights & Measures' },
];

export const SEVERITY_OPTIONS: readonly { value: Severity; label: string }[] = [
  { value: 'Minor', label: 'Minor' },
  { value: 'Moderate', label: 'Moderate' },
  { value: 'High', label: 'High' },
];

export const ordinancesListKey = ['ordinances', 'list'] as const;
export const ordinanceCountKey = ['ordinance', 'configurations', 'count'] as const;
export const ordinanceDetailKey = (id: number) => ['ordinances', 'detail', id] as const;
