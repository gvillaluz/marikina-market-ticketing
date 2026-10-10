import type { ProfileUpdateInput } from "@/api/endpoints/profile.api";

export type ProfileField = keyof ProfileUpdateInput;
export type ProfileFormValues = Record<ProfileField, string>;
export type ProfileFormErrors = Partial<Record<ProfileField, string>>;

export interface PasswordValues {
  currentPassword: string;
  newPassword: string;
  confirmNewPassword: string;
}

export function todayDate(): string {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

export function validateProfileForm(
  values: ProfileFormValues,
): ProfileFormErrors {
  const errors: ProfileFormErrors = {};
  for (const field of Object.keys(profilePayload(values)) as ProfileField[]) {
    if (field !== "middleName" && !values[field].trim()) {
      errors[field] = "This field is required.";
    }
  }
  if (
    values.email.trim() &&
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values.email.trim())
  ) {
    errors.email = "Enter a valid email address.";
  }
  const phone = values.phoneNumber.trim();
  if (
    phone &&
    (!/^\+?[\d ()-]+$/.test(phone) ||
      !/^\d{10,15}$/.test(phone.replace(/\D/g, "")))
  ) {
    errors.phoneNumber = "Enter a valid phone number with 10 to 15 digits.";
  }
  const birthDate = values.dateOfBirth;
  if (birthDate) {
    const date = new Date(`${birthDate}T00:00:00Z`);
    if (
      !/^\d{4}-\d{2}-\d{2}$/.test(birthDate) ||
      !Number.isFinite(date.getTime()) ||
      date.toISOString().slice(0, 10) !== birthDate ||
      birthDate > todayDate() ||
      birthDate < "0001-01-01"
    ) {
      errors.dateOfBirth =
        "Enter a valid birth date that is not in the future.";
    }
  }
  return errors;
}

export function validatePasswordForm(
  values: PasswordValues,
): Partial<Record<keyof PasswordValues, string>> {
  const errors: Partial<Record<keyof PasswordValues, string>> = {};
  if (!values.currentPassword)
    errors.currentPassword = "Enter your current password.";
  if (values.newPassword.length < 6)
    errors.newPassword = "Use at least 6 characters.";
  if (!values.confirmNewPassword)
    errors.confirmNewPassword = "Confirm your new password.";
  else if (values.confirmNewPassword !== values.newPassword)
    errors.confirmNewPassword = "Passwords do not match.";
  return errors;
}

export function profilePayload(values: ProfileFormValues): ProfileUpdateInput {
  return {
    firstName: values.firstName.trim(),
    middleName: values.middleName.trim() || null,
    lastName: values.lastName.trim(),
    dateOfBirth: values.dateOfBirth,
    email: values.email.trim(),
    phoneNumber: values.phoneNumber.trim(),
    houseNumber: values.houseNumber.trim(),
    street: values.street.trim(),
    barangay: values.barangay.trim(),
    city: values.city.trim(),
  };
}
