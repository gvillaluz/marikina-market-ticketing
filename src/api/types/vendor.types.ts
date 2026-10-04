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

export interface VendorRegistrationForm {
  firstName: string;
  middleName: string;
  lastName: string;
  dateOfBirth: string;
  phoneNumber: string;
  houseNumber: string;
  street: string;
  barangay: string;
  city: string;
  businessId: string;
  businessName: string;
  natureOfBusiness: string;
  vendorType: string;
  stallNumber: string;
  marketSectionId: string;
  governmentIdType: string;
  governmentIdPhoto: File | null;
  businessDocumentPhoto: File | null;
  email: string;
  password: string;
  confirmPassword: string;
}
