import type { Severity } from '@/api/types/common.types';
import type { TicketCategories } from '@/api/types/ticket.types';

import type { OrdinanceSummaryResponse } from '@/api/types/ordinance.types';

export interface OrdinanceSummary extends Omit<OrdinanceSummaryResponse, 'category' | 'severity'> {
  category: TicketCategories;
  severity: Severity | null;
}

export interface OrdinanceFields {
  ordinanceNumber: string;
  series: string;
  marketCode: string;
  title: string;
  description: string;
  category: TicketCategories | '';
}

export interface DraftPenaltyTier {
  key: string;
  severity: Severity | '';
  amount: string;
}

export interface OrdinanceDraft {
  fields: OrdinanceFields;
  tiers: DraftPenaltyTier[];
}

export type OrdinanceFieldName = keyof OrdinanceFields;
export type TierFieldName = 'severity' | 'amount';
export type OrdinanceFieldErrors = Partial<Record<OrdinanceFieldName, string>>;
export type TierFieldErrors = Partial<Record<TierFieldName, string>>;
