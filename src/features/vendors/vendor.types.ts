export type { Vendor, VendorRegistrationInput, VendorCategory } from '@/api/types/vendor.types';

export interface VendorRegisterPayload {
  government_id_type: string;
  government_id_number: string;
  government_id_photo_url: string;
  business_document_photo_url: string;
  business_name: string;
  first_name: string;
  middle_name: string;
  last_name: string;
  email: string;
  password: string;
  stall_number: string;
  market_section_id: number;
}