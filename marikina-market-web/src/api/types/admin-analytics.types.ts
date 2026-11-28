export interface ViolationTrendPoint {
  year: number;
  month: number;
  monthName: string;
  level1Count: number;
  level2Count: number;
  level3Count: number;
  level4Count: number;
  level5Count: number;
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
  businessAccountNumber: string;
  businessName: string;
  offenseCount: number;
  highestSeverityLevel: number | null;
  riskScore: number;
}
