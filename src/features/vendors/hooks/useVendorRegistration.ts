import { useState } from 'react';
import type { VendorRegistrationWizardInput } from '@/api/types/vendor.types';
import { isValidEmail, isValidPhone } from '@/utils/validators';
import { vendorApi } from '@/api/endpoints/vendor.api';


export const TOTAL_STEPS = 4;

export const initialWizardState: VendorRegistrationWizardInput = {
  lastName: '',
  firstName: '',
  middleName: '',
  dateOfBirth: '',
  age: '',
  mobileNumber: '',
  houseNo: '',
  street: '',
  barangay: '',
  city: 'Marikina City',

  businessName: '',
  natureOfBusiness: '',
  stallNumber: '',
  section: '',

  govIdType: '',
  govIdNumber: '',
  govIdPhoto: '',
  businessDocument: '',

  email: '',
  password: '',
  confirmPassword: '',
};

export interface StepErrors {
  [key: string]: string;
}


function validateStep(step: number, form: VendorRegistrationWizardInput): StepErrors {
  const errs: StepErrors = {};

  if (step === 1) {
    if (!form.lastName.trim()) errs.lastName = 'Last name is required.';
    if (!form.firstName.trim()) errs.firstName = 'First name is required.';
    if (!form.dateOfBirth.trim()) errs.dateOfBirth = 'Date of birth is required.';
    if (!form.age.trim()) errs.age = 'Age is required.';
    if (!isValidPhone(form.mobileNumber)) errs.mobileNumber = 'Enter a valid PH mobile number.';
    if (!form.street.trim()) errs.street = 'Street is required.';
    if (!form.barangay.trim()) errs.barangay = 'Barangay is required.';
  }

  if (step === 2) {
    if (!form.businessName.trim()) errs.businessName = 'Business name is required.';
    if (!form.natureOfBusiness.trim()) errs.natureOfBusiness = 'Nature of business is required.';
    if (!form.stallNumber.trim()) errs.stallNumber = 'Stall number is required.';
    if (!form.section.trim()) errs.section = 'Market section is required.';
  }

  if (step === 3) {
    if (!form.govIdType.trim()) errs.govIdType = 'Select an ID type.';
    if (!form.govIdNumber.trim()) errs.govIdNumber = 'ID number is required.';
    if (!form.govIdPhoto) errs.govIdPhoto = 'Upload a government ID photo.';
    if (!form.businessDocument) errs.businessDocument = 'Upload a business document.';
  }

  if (step === 4) {
    if (!form.email.trim()) errs.email = 'Email is required.';
    else if (!isValidEmail(form.email)) errs.email = 'Enter a valid email.';
    if (!form.password) errs.password = 'Password is required.';
    else if (form.password.length < 6) errs.password = 'Password must be at least 6 characters.';
    if (form.confirmPassword !== form.password) errs.confirmPassword = 'Passwords do not match.';
  }

  return errs;
}

export function useVendorRegistration() {
  const [step, setStep] = useState(1);
  const [form, setForm] = useState<VendorRegistrationWizardInput>(initialWizardState);
  const [errors, setErrors] = useState<StepErrors>({});
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const update = <K extends keyof VendorRegistrationWizardInput>(
    key: K,
    value: VendorRegistrationWizardInput[K],
  ) => {
    setForm((prev) => ({ ...prev, [key]: value }));
    
    setErrors((prev) => {
      if (!prev[key]) return prev;
      const next = { ...prev };
      delete next[key];
      return next;
    });
  };

  const next = () => {
    const errs = validateStep(step, form);
    setErrors(errs);
    if (Object.keys(errs).length > 0) return false;
    setStep((s) => Math.min(s + 1, TOTAL_STEPS));
    return true;
  };

  const back = () => {
    setStep((s) => Math.max(s - 1, 1));
    setErrors({});
  };

  const cancel = () => {
    setForm(initialWizardState);
    setStep(1);
    setErrors({});
    setSubmitError(null);
  };

  const submit = async () => {
    const errs = validateStep(4, form);
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;

    setLoading(true);
    setSubmitError(null);
    try {
      await vendorApi.register(form as any);
      setSubmitted(true);
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Registration failed.');
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
    cancel,
    submit,
    setStep,
  };
}

export type UseVendorRegistration = ReturnType<typeof useVendorRegistration>;

