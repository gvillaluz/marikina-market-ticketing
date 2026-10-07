import type { Severity } from "./common.types";
import type { TicketCategories } from "./ticket.types";

export interface OrdinanceSummaryResponse {
  id: number;
  ordinanceNo: string;
  series: string;
  marketCode: string;
  title: string;
  description: string;
  category: TicketCategories | number;
  createdAt: string;
  updatedAt: string;
  isActive: boolean;
  severity: Severity | number | null;
  penaltyTierCount: number;
}

export interface OrdinancePenaltyTierResponse {
  id: number;
  offenseNumber: number;
  severity: Severity | number;
  penaltyAmount: number;
}

export interface OrdinanceDetailResponse extends OrdinanceSummaryResponse {
  penaltyTiers: OrdinancePenaltyTierResponse[];
}

export interface SavePenaltyTierRequest {
  offenseNumber: number;
  severity: Severity;
  penaltyAmount: number;
}

export interface SaveOrdinanceRequest {
  ordinanceNumber: string;
  series: string;
  marketCode: string;
  category: TicketCategories;
  title: string;
  description: string;
  penaltyTiers: SavePenaltyTierRequest[];
}
