import type { SaveBusinessRequest } from "@/api/types/admin-vendor.types";

export type BusinessErrors = Partial<Record<keyof SaveBusinessRequest, string>>;

export function validateBusiness(form: SaveBusinessRequest): BusinessErrors {
  const errors: BusinessErrors = {};
  const required: Array<[keyof SaveBusinessRequest, string, number]> = [
    ["businessAccountNumber", "Business account number", 20], ["businessName", "Business name", 100],
    ["ownerFirstName", "Owner's first name", 100], ["ownerLastName", "Owner's last name", 100],
    ["houseNumber", "House number", 50], ["street", "Street", 50],
    ["barangay", "Barangay", 60], ["city", "City", 100],
  ];
  for (const [key, label, max] of required) {
    const value = String(form[key] ?? "").trim();
    if (!value) errors[key] = `${label} is required.`;
    else if (value.length > max) errors[key] = `${label} must be ${max} characters or fewer.`;
  }
  if (!Number.isSafeInteger(form.marketSectionId) || form.marketSectionId < 1)
    errors.marketSectionId = "Select a market section.";
  if (form.businessType !== "Public" && form.businessType !== "Private")
    errors.businessType = "Select Public or Private.";
  if (form.businessType === "Public" && !form.stallNumber?.trim())
    errors.stallNumber = "Stall number is required for public businesses.";
  if ((form.stallNumber?.trim().length ?? 0) > 20) errors.stallNumber = "Stall number must be 20 characters or fewer.";
  if (form.phoneNumber?.trim() && !/^09\d{9}$/.test(form.phoneNumber.trim()))
    errors.phoneNumber = "Enter a valid PH mobile number.";
  if (form.email?.trim() && (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim()) || form.email.trim().length > 255))
    errors.email = "Enter a valid email address.";
  return errors;
}
