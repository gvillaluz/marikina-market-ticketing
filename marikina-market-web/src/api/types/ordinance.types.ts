import type { Severity } from "./common.types";
import type { TicketCategories } from "./ticket.types";

export interface OrdinanceSummaryResponse {
  id: number;
  ordinanceNo: string;
  series: string;
  section: string | null;
  specificCategory: string | null;
  title: string;
  category: TicketCategories | number;
  createdAt: string;
  updatedAt: string;
  isActive: boolean;
  severity: Severity | number | null;
  warningEligible: boolean;
  penaltyTierCount: number;
}

export type FineKind = "Fixed" | "UpTo" | "Unconfirmed";

export interface OrdinancePenaltyTierResponse {
  id: number;
  offenseNumber: number;
  fineKind: FineKind | number;
  penaltyAmount: number | null;
  minimumFine: number | null;
  maximumFine: number | null;
  penaltyTerms: string | null;
  allowBloodDonation: boolean;
  allowCommunityService: boolean;
}

export interface OrdinanceDetailResponse extends OrdinanceSummaryResponse {
  penaltyTiers: OrdinancePenaltyTierResponse[];
}

export interface SavePenaltyTierRequest {
  offenseNumber: number;
  fineKind: FineKind;
  penaltyAmount: number | null;
  maximumFine: number | null;
  penaltyTerms: string | null;
  allowBloodDonation: boolean;
  allowCommunityService: boolean;
}

export interface SaveOrdinanceRequest {
  ordinanceNumber: string;
  series: string;
  section: string;
  specificCategory: string | null;
  category: TicketCategories;
  title: string;
  severity: Severity;
  warningEligible: boolean;
  penaltyTiers: SavePenaltyTierRequest[];
}
