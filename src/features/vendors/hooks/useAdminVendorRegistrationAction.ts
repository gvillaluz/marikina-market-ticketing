import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { VendorRegistrationDetails } from "@/api/types/admin-vendor.types";
import { ROUTES } from "@/routes/routePaths";
import { getApiErrorMessage } from "@/utils/apiErrors";

export type RegistrationActionMode = "approve" | "decline" | "information";

export interface RegistrationActionOption {
  value: string;
  title: string;
  description: string;
}

export const DECLINE_OPTIONS: RegistrationActionOption[] = [
  {
    value: "Invalid or unverifiable government ID",
    title: "Invalid or unverifiable government ID",
    description: "Identity evidence cannot be authenticated.",
  },
  {
    value: "Business eligibility requirements not met",
    title: "Business eligibility requirements not met",
    description: "The submitted permit or operations do not meet requirements.",
  },
  {
    value: "Duplicate active vendor account",
    title: "Duplicate active vendor account",
    description:
      "An existing active vendor record already represents this applicant.",
  },
  {
    value: "False or materially inconsistent information",
    title: "False or materially inconsistent information",
    description: "Submitted details conflict with verified records.",
  },
];

export const INFORMATION_OPTIONS: RegistrationActionOption[] = [
  {
    value: "Document is missing",
    title: "Document is missing",
    description: "A required record was not included in the submission.",
  },
  {
    value: "Documents are unreadable or incomplete",
    title: "Documents are unreadable or incomplete",
    description: "A replacement image or full page scan is needed.",
  },
  {
    value: "Information does not match",
    title: "Information does not match",
    description: "The application contains conflicting information.",
  },
  {
    value: "Document is expired",
    title: "Document is expired",
    description: "A current document must be submitted.",
  },
];

export const DEFAULT_REMARKS = {
  decline:
    "The submitted business permit does not establish eligibility for the requested market section. Please submit a valid document or resolve the noted issue before applying again.",
  information:
    "Hello Mark, please upload a clearer full-frame image of your Philippine National ID and a complete copy of the 2026 business permit showing its issue date and official seal. We will review your application once both items are received.",
};

export function useAdminVendorRegistrationAction(
  mode: RegistrationActionMode,
  details: VendorRegistrationDetails,
) {
  const navigate = useNavigate();
  const defaultReason =
    mode === "decline"
      ? DECLINE_OPTIONS[0].value
      : INFORMATION_OPTIONS[0].value;
  const [selectedReason, setSelectedReason] = useState(defaultReason);
  const [remarks, setRemarks] = useState(
    mode === "decline" ? DEFAULT_REMARKS.decline : DEFAULT_REMARKS.information,
  );
  const [submitError, setSubmitError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showApprovalModal, setShowApprovalModal] = useState(false);

  const submit = async () => {
    setSubmitError("");
    if (mode !== "approve" && (!selectedReason || !remarks.trim())) {
      setSubmitError("Select a reason and provide detailed remarks.");
      return false;
    }

    setIsSubmitting(true);
    try {
      const request = {
        vendorRegistrationId: details.registrationId,
        version: details.version ?? 0,
      };
      if (mode === "approve") {
        await adminVendorsApi.approveRegistration(request);
      } else if (mode === "decline") {
        await adminVendorsApi.declineRegistration({
          ...request,
          reviewReason: selectedReason,
          reviewRemarks: remarks.trim(),
        });
      } else {
        await adminVendorsApi.requestMoreInformation({
          ...request,
          reviewReason: selectedReason,
          reviewRemarks: remarks.trim(),
        });
      }
      navigate(ROUTES.adminVendorRegistrations);
      return true;
    } catch (error) {
      setSubmitError(
        getApiErrorMessage(
          error,
          "The registration action could not be completed.",
        ),
      );
      return false;
    } finally {
      setIsSubmitting(false);
      setShowApprovalModal(false);
    }
  };

  const cancel = () =>
    navigate(ROUTES.adminVendorRegistration(String(details.registrationId)));

  return {
    selectedReason,
    setSelectedReason,
    remarks,
    setRemarks,
    submitError,
    isSubmitting,
    showApprovalModal,
    setShowApprovalModal,
    submit,
    cancel,
  };
}
