import type { Severity } from '@/api/types/common.types';
import type { TicketCategories } from '@/api/types/ticket.types';
import type { FineKind } from '@/api/types/ordinance.types';

export const CATEGORY_OPTIONS: readonly { value: TicketCategories; label: string; }[] = [
  { value: 'Traffic', label: 'Traffic' },
  { value: 'Obstruction', label: 'Obstruction' },
  { value: 'Sanitation', label: 'Sanitation' },
  { value: 'WeightMeasures', label: 'Weights & Measures' },
  { value: 'DressCode', label: 'Dress Code' },
  { value: 'IllegalVendor', label: 'Illegal Vendor' },
  { value: 'NonSmoking', label: 'Non-Smoking' },
  { value: 'Others', label: 'Others' },
];

// Historical enum values remain readable even after their choices are retired.
export const CATEGORY_VALUES: readonly TicketCategories[] = [
  'Traffic', 'Obstruction', 'Sanitation', 'Licensing', 'Noise', 'WeightMeasures',
  'DressCode', 'IllegalVendor', 'NonSmoking', 'Others',
];

export const SEVERITY_OPTIONS: readonly { value: Severity; label: string; }[] = [
  { value: 'Minor', label: 'Minor' },
  { value: 'Moderate', label: 'Moderate' },
  { value: 'High', label: 'High' },
];

export const FINE_KIND_OPTIONS: readonly { value: FineKind; label: string; }[] = [
  { value: 'Fixed', label: 'Fixed fine' },
  { value: 'UpTo', label: 'Up to a maximum' },
  { value: 'Unconfirmed', label: 'Unconfirmed rule' },
];

export const ordinancesListKey = ['ordinances', 'list'] as const;
export const ordinanceCountKey = ['ordinance', 'configurations', 'count'] as const;
export const ordinanceDetailKey = (id: number) => ['ordinances', 'detail', id] as const;
