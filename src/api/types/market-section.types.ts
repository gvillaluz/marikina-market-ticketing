export interface MarketSectionResponse {
  id: number;
  name: string;
  description: string;
  isActive: boolean;
  vendorCount: number;
}

export interface SaveMarketSectionRequest {
  name: string;
  description: string;
}
