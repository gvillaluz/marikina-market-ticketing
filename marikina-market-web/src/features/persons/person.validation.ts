import type { SavePersonRequest } from "@/api/types/person.types";

export type PersonErrors = Partial<Record<keyof SavePersonRequest, string>>;

export function validatePerson(form: SavePersonRequest): PersonErrors {
  const errors: PersonErrors = {};
  if (!form.fullName.trim() || form.fullName.length > 200)
    errors.fullName = "Enter a name of up to 200 characters.";
  if (!form.address.trim() || form.address.length > 500)
    errors.address = "Enter an address of up to 500 characters.";
  if (form.phoneNumber?.trim() && !/^09[0-9]{9}$/.test(form.phoneNumber.trim()))
    errors.phoneNumber = "Enter an 11-digit mobile number starting with 09.";
  return errors;
}
