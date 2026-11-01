import type { Severity } from '@/api/types/common.types';
import type { TicketCategories } from '@/api/types/ticket.types';

import type { FineKind, OrdinanceSummaryResponse } from '@/api/types/ordinance.types';

export interface OrdinanceSummary extends Omit<OrdinanceSummaryResponse, 'category' | 'severity'> {
  category: TicketCategories;
  severity: Severity | null;
}

export interface OrdinanceFields {
  ordinanceNumber: string;
  series: string;
  section: string;
  specificCategory: string;
  title: string;
  category: TicketCategories | '';
  severity: Severity | '';
  warningEligible: boolean;
}

export interface DraftPenaltyTier {
  key: string;
  fineKind: FineKind | '';
  amount: string;
  maximumFine: string;
  penaltyTerms: string;
  allowBloodDonation: boolean;
  allowCommunityService: boolean;
}

export interface OrdinanceDraft {
  fields: OrdinanceFields;
  tiers: DraftPenaltyTier[];
}

export type OrdinanceFieldName = keyof OrdinanceFields;
export type TierFieldName = Exclude<keyof DraftPenaltyTier, 'key'>;
export type OrdinanceFieldErrors = Partial<Record<OrdinanceFieldName, string>>;
export type TierFieldErrors = Partial<Record<TierFieldName, string>>;
