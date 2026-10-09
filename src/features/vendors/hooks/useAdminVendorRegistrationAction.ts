import { useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { useToast } from "@/components/ui/Toast/useToast";
import { useNavigate } from "react-router-dom";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type {
  RegistrationApprovalResponse,
  RegistrationDeclinedResponse,
  VendorRegistrationDetails,
} from "@/api/types/admin-vendor.types";
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

export function useAdminVendorRegistrationAction(
  mode: RegistrationActionMode,
  details: VendorRegistrationDetails | undefined,
) {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const submitting = useRef(false);
  const [selectedReason, setSelectedReason] = useState("");
  const [remarks, setRemarks] = useState("");
  const [submitError, setSubmitError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const canDecide = Boolean(
    details &&
      !["approved", "rejected"].includes(String(details.status).toLowerCase()),
  );
  const hasVersion =
    details?.version != null &&
    Number.isSafeInteger(details.version) &&
    details.version >= 0;

  const submit = async () => {
    if (submitting.current) return false;
    setSubmitError("");
    if (
      !details ||
      !Number.isSafeInteger(details.registrationId) ||
      details.registrationId < 1 ||
      !hasVersion ||
      !canDecide
    ) {
      setSubmitError(
        "This registration cannot be processed. Reload its latest details before making a decision.",
      );
      return false;
    }
    const options = mode === "decline" ? DECLINE_OPTIONS : INFORMATION_OPTIONS;
    if (
      mode !== "approve" &&
      (!options.some((option) => option.value === selectedReason) ||
        !remarks.trim() ||
        remarks.length > 2000)
    ) {
      setSubmitError("Select a reason and provide detailed remarks.");
      return false;
    }

    submitting.current = true;
    setIsSubmitting(true);
    try {
      const request = {
        vendorRegistrationId: details.registrationId,
        version: details.version!,
      };
      let result: RegistrationApprovalResponse | RegistrationDeclinedResponse;
      if (mode === "approve") {
        result = await adminVendorsApi.approveRegistration(request);
      } else if (mode === "decline") {
        result = await adminVendorsApi.declineRegistration({
          ...request,
          reviewReason: selectedReason,
          reviewRemarks: remarks.trim(),
        });
      } else {
        result = await adminVendorsApi.requestMoreInformation({
          ...request,
          reviewReason: selectedReason,
          reviewRemarks: remarks.trim(),
        });
      }
      showToast({
        title:
          mode === "approve"
            ? "Registration approved"
            : mode === "decline"
              ? "Registration rejected"
              : "Information requested",
        variant: "success",
      });
      if (result.emailSent === false)
        showToast({
          title: "Decision saved; email was not sent",
          description:
            "The registration decision succeeded, but the applicant notification could not be delivered.",
          variant: "warning",
          duration: 0,
        });
      for (const key of [
        "admin-vendor-registration",
        "admin-vendor-registration-documents",
        "admin-vendor-registration-counts",
        "admin-vendor-registrations",
        "admin-vendors",
        "account-counts",
        "accounts",
      ]) {
        void queryClient.invalidateQueries({ queryKey: [key] });
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
      submitting.current = false;
      setIsSubmitting(false);
      setShowApprovalModal(false);
    }
  };

  const cancel = () => {
    if (!submitting.current)
      navigate(
        details
          ? ROUTES.adminVendorRegistration(String(details.registrationId))
          : ROUTES.adminVendorRegistrations,
      );
  };

  return {
    selectedReason,
    setSelectedReason: (value: string) => {
      if (!submitting.current) setSelectedReason(value);
    },
    remarks,
    setRemarks: (value: string) => {
      if (!submitting.current)
        setRemarks(
          value
            .slice(0, 2000)
            .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, ""),
        );
    },
    submitError,
    isSubmitting,
    showApprovalModal,
    setShowApprovalModal,
    submit,
    cancel,
    canSubmit: canDecide && hasVersion,
  };
}
