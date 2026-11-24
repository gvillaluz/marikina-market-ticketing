export type RiskLevel = "High" | "Moderate" | "Low";

export type PatternConfidence = "High" | "Moderate" | "Low";

export type RecommendationDecision = "Reviewed" | "Dismissed";

export interface RecommendationReview {
  decision: RecommendationDecision;
  reviewedByName: string;
  reviewedAt: string;
}

export interface RecommendationRun {
  finishedAt: string;
  windowStart: string;
  windowEnd: string;
  recordCount: number;
  detectedRecordCount: number;
}

export interface SectionRecommendation {
  id: number;
  marketSectionId: number;
  marketSectionName: string;
  categoryCode: string;
  categoryNameEnglish: string;
  categoryNameFilipino: string;
  recommendedAction: string;
  categoryRecordCount: number;
  sectionRecordCount: number;
  riskScore: number;
  riskLevel: RiskLevel;
  patternConfidence: PatternConfidence;
  peakStartHour: number;
  hourlyCounts: number[];
  lastFlaggedAt: string;
  review: RecommendationReview | null;
}

export interface DetectedViolation {
  ticketId: number;
  controlNumber: string | null;
  type: "Warning" | "Ticket";
  marketSectionName: string;
  description: string;
  issuedAt: string;
  categoryCodes: string[];
}

export interface DetectedViolationParams {
  offset: number;
  search?: string;
  type?: "Warning" | "Ticket";
  marketSectionId?: number;
  categoryCode?: string;
}

export interface RecommendationsResponse {
  run: RecommendationRun | null;
  recommendations: SectionRecommendation[];
  sectionsWithoutRecommendation: string[];
}
