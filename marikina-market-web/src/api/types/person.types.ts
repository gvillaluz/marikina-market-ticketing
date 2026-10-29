export interface PersonRecord {
  id: number;
  fullName: string;
  address: string;
  phoneNumber: string | null;
  createdAt: string;
}

export interface SavePersonRequest {
  fullName: string;
  address: string;
  phoneNumber: string | null;
}

export interface PersonPage {
  items: PersonRecord[];
  total: number;
  hasMore: boolean;
}
