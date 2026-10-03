export interface ViolationTrendPoint {
  year: number;
  month: number;
  monthName: string;
  lowSeverityCount: number;
  mediumSeverityCount: number;
  highSeverityCount: number;
}

export interface PeakViolationTime {
  day: string;
  dayOfWeek: number;
  timeBlock: number;
  timeRange: string;
  ticketCount: number;
}

export interface ViolationCategoryDistribution {
  category: string;
  ticketCount: number;
  percentage: number;
}

export interface InspectionRatio {
  warningCount: number;
  ticketCount: number;
  totalInspectionCount: number;
  warningPercentage: number;
  ticketPercentage: number;
}

export interface ViolationResolutionRate {
  ticketCount: number;
  resolvedWithinSevenDays: number;
  resolutionRate: number;
}

export interface MarketSectionAggregation {
  marketSectionId: number;
  marketSectionName: string;
  warningCount: number;
  ticketCount: number;
  totalInspectionCount: number;
}

export interface HotspotRanking {
  rank: number;
  marketSectionId: number;
  marketSectionName: string;
  warningCount: number;
  ticketCount: number;
  totalInspectionCount: number;
  previousPeriodCount: number;
  trend: string;
}

export interface VendorRiskRanking {
  rank: number;
  businessId: string;
  businessName: string;
  offenseCount: number;
  highestSeverity: string | number | null;
  riskScore: number;
}
