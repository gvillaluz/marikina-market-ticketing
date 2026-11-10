import type { Status } from './common.types';

export type VendorCategory =
  | 'retail'
  | 'food'
  | 'services'
  | 'manufacturing'
  | 'construction'
  | 'other';

export interface Vendor {
  id: string;
  name: string;
  businessName: string;
  category: VendorCategory;
  address: string;
  barangay: string;
  contactPerson: string;
  email: string;
  phone: string;
  status: Status;
  registrationDate: string;
  expiryDate: string;
  complianceScore: number;
  qrCode: string;
  ownerId?: string;
}
