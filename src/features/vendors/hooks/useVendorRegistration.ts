import { useState } from "react";
import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import { vendorApi } from "@/api/endpoints/vendor.api";
import { isValidEmail } from "@/utils/validators";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { TOTAL_STEPS } from "../registration.constants";

const MAX_FILE_SIZE = 5 * 1024 * 1024;
const ALLOWED_FILE_TYPES = ["image/jpeg", "image/png", "application/pdf"];

export const initialWizardState: VendorRegistrationForm = {
  firstName: "",
  middleName: "",
  lastName: "",
  dateOfBirth: "",
  phoneNumber: "",
  houseNumber: "",
  street: "",
  barangay: "",
  city: "",
  businessId: "",
  businessName: "",
  natureOfBusiness: "",
  vendorType: "",
  stallNumber: "",
  marketSectionId: "",
  governmentIdType: "",
  governmentIdPhoto: null,
  businessDocumentPhoto: null,
  email: "",
  password: "",
  confirmPassword: "",
};

export type RegistrationFieldErrors = Partial<
  Record<keyof VendorRegistrationForm, string>
>;

function validateRequiredText(
  value: string,
  fieldName: string,
  minimumLength: number,
  maximumLength: number,
): string | undefined {
  const normalized = value.trim();
  if (!normalized) return `${fieldName} is required.`;
  if (normalized.length < minimumLength || normalized.length > maximumLength) {
    return `${fieldName} must be between ${minimumLength} and ${maximumLength} characters.`;
  }
  return undefined;
}

function validateFile(file: File | null, fieldName: string): string | undefined {
  if (!file) return `${fieldName} is required.`;
  if (!ALLOWED_FILE_TYPES.includes(file.type)) {
    return `${fieldName} must be a JPG, PNG, or PDF file.`;
  }
  if (file.size > MAX_FILE_SIZE) {
    return `${fieldName} must be 5 MB or smaller.`;
  }
  return undefined;
}

function validateStep(
  step: number,
  form: VendorRegistrationForm,
): RegistrationFieldErrors {
  const errors: RegistrationFieldErrors = {};

  if (step === 1) {
    const firstNameError = validateRequiredText(form.firstName, "First name", 2, 50);
    const lastNameError = validateRequiredText(form.lastName, "Last name", 2, 50);
    if (firstNameError) errors.firstName = firstNameError;
    if (lastNameError) errors.lastName = lastNameError;

    if (!form.dateOfBirth) {
      errors.dateOfBirth = "Birth date is required.";
    } else if (
      Number.isNaN(Date.parse(form.dateOfBirth)) ||
      new Date(`${form.dateOfBirth}T00:00:00`) > new Date()
    ) {
      errors.dateOfBirth = "Enter a valid birth date that is not in the future.";
    }

    if (!/^09\d{9}$/.test(form.phoneNumber.trim())) {
      errors.phoneNumber = "Enter a valid PH mobile number (e.g. 09171234567).";
    }

    const addressFields = [
      ["houseNumber", form.houseNumber, "House number", 50],
      ["street", form.street, "Street", 50],
      ["barangay", form.barangay, "Barangay", 60],
      ["city", form.city, "City", 100],
    ] as const;
    addressFields.forEach(([key, value, label, maxLength]) => {
      const error = validateRequiredText(value, label, 1, maxLength);
      if (error) errors[key] = error;
    });
  }

  if (step === 2) {
    const businessNameError = validateRequiredText(form.businessName, "Business name", 2, 100);
    const natureError = validateRequiredText(
      form.natureOfBusiness,
      "Nature of business",
      10,
      100,
    );
    if (businessNameError) errors.businessName = businessNameError;
    if (natureError) errors.natureOfBusiness = natureError;
    if (!form.vendorType) {
      errors.vendorType = "Vendor type is required.";
    }
    if (!form.marketSectionId || Number(form.marketSectionId) < 1) {
      errors.marketSectionId = "Select a valid market section.";
    }
    if (form.vendorType === "Public" && !form.stallNumber.trim()) {
      errors.stallNumber = "Stall number is required for public vendors.";
    }
  }

  if (step === 3) {
    const businessIdError = validateRequiredText(
      form.businessId,
      "Business ID",
      1,
      20,
    );
    if (businessIdError) errors.businessId = businessIdError;
    if (!form.governmentIdType) {
      errors.governmentIdType = "Government ID type is required.";
    }
    const governmentIdPhotoError = validateFile(
      form.governmentIdPhoto,
      "Government ID photo",
    );
    const businessDocumentError = validateFile(
      form.businessDocumentPhoto,
      "Business document photo",
    );
    if (governmentIdPhotoError) errors.governmentIdPhoto = governmentIdPhotoError;
    if (businessDocumentError) errors.businessDocumentPhoto = businessDocumentError;
  }

  if (step === 4) {
    if (!form.email.trim()) errors.email = "Email is required.";
    else if (!isValidEmail(form.email.trim())) {
      errors.email = "Enter a valid email address.";
    }

    if (!form.password) errors.password = "Password is required.";
    else if (form.password.length < 8 || form.password.length > 100) {
      errors.password = "Password must be between 8 and 100 characters.";
    }
    if (!form.confirmPassword) {
      errors.confirmPassword = "Confirm password is required.";
    } else if (form.confirmPassword !== form.password) {
      errors.confirmPassword = "Passwords do not match.";
    }
  }

  return errors;
}

export function useVendorRegistration() {
  const [step, setStep] = useState(1);
  const [form, setForm] = useState<VendorRegistrationForm>(initialWizardState);
  const [errors, setErrors] = useState<RegistrationFieldErrors>({});
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const update = <K extends keyof VendorRegistrationForm>(
    key: K,
    value: VendorRegistrationForm[K],
  ) => {
    setForm((previous) => ({ ...previous, [key]: value }));
    setErrors((previous) => {
      const next = { ...previous };
      delete next[key];
      if (
        key === "password" &&
        typeof value === "string" &&
        value === form.confirmPassword
      ) {
        delete next.confirmPassword;
      }
      return next;
    });
    setSubmitError(null);
  };

  const next = () => {
    const stepErrors = validateStep(step, form);
    setErrors(stepErrors);
    if (Object.keys(stepErrors).length > 0) return false;
    setStep((current) => Math.min(current + 1, TOTAL_STEPS));
    return true;
  };

  const back = () => {
    setStep((current) => Math.max(current - 1, 1));
    setErrors({});
    setSubmitError(null);
  };

  const goToStep = (targetStep: number) => {
    if (targetStep >= 1 && targetStep < step) {
      setStep(targetStep);
      setErrors({});
      setSubmitError(null);
    }
  };

  const cancel = () => {
    setForm(initialWizardState);
    setStep(1);
    setErrors({});
    setSubmitError(null);
  };

  const submit = async () => {
    const allErrors = [1, 2, 3, 4].reduce<RegistrationFieldErrors>(
      (combined, currentStep) => ({
        ...combined,
        ...validateStep(currentStep, form),
      }),
      {},
    );
    setErrors(allErrors);
    if (Object.keys(allErrors).length > 0) {
      const firstInvalidStep = [1, 2, 3, 4].find(
        (currentStep) => Object.keys(validateStep(currentStep, form)).length > 0,
      );
      if (firstInvalidStep) setStep(firstInvalidStep);
      return;
    }

    setLoading(true);
    setSubmitError(null);
    try {
      await vendorApi.register(form);
      setSubmitted(true);
    } catch (error) {
      setSubmitError(
        getApiErrorMessage(error, "Registration could not be submitted. Please try again."),
      );
    } finally {
      setLoading(false);
    }
  };

  return {
    step,
    form,
    errors,
    loading,
    submitted,
    submitError,
    update,
    next,
    back,
    goToStep,
    cancel,
    submit,
  };
}

export type UseVendorRegistration = ReturnType<typeof useVendorRegistration>;
