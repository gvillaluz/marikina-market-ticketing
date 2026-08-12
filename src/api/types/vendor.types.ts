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

export interface VendorRegistrationInput {
  businessName: string;
  category: VendorCategory;
  address: string;
  barangay: string;
  contactPerson: string;
  email: string;
  phone: string;
}


export interface VendorRegistrationWizardInput {
  // Personal information
  lastName: string;
  firstName: string;
  middleName: string;
  dateOfBirth: string;
  age: string;
  mobileNumber: string;
  houseNo: string;
  street: string;
  barangay: string;
  city: string;

  // Business details
  businessName: string;
  natureOfBusiness: string;
  stallNumber: string;
  section: string;

  // Required documents
  govIdType: string;
  govIdNumber: string;
  govIdPhoto?: string | null;
  businessDocument?: string | null;

  // Account registration
  email: string;
  password: string;
  confirmPassword: string;
}
