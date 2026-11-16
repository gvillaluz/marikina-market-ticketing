export interface MarketSectionResponse {
  id: number;
  name: string;
  isActive: boolean;
  vendorCount: number;
}

export interface SaveMarketSectionRequest {
  name: string;
}
