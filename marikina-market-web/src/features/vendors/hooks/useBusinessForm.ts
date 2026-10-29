import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { SaveBusinessRequest } from "@/api/types/admin-vendor.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { validateBusiness, type BusinessErrors } from "../business.validation";

const EMPTY: SaveBusinessRequest = {
  businessAccountNumber: "", businessName: "", ownerFirstName: "", ownerLastName: "",
  houseNumber: "", street: "", barangay: "", city: "Marikina City", phoneNumber: "", email: "",
  marketSectionId: 0, businessType: "", stallNumber: "",
};

export function useBusinessForm(open: boolean, id: number | null, onSaved: () => Promise<void>, onClose: () => void) {
  const [form, setForm] = useState<SaveBusinessRequest>(EMPTY);
  const [errors, setErrors] = useState<BusinessErrors>({});
  const [saving, setSaving] = useState(false);
  const savePending = useRef(false);
  const [submitError, setSubmitError] = useState("");
  const record = useQuery({
    queryKey: ["admin-business", id], queryFn: () => adminVendorsApi.getBusiness(id!),
    enabled: open && id !== null, staleTime: 0, refetchOnWindowFocus: false, refetchOnReconnect: false
  });

  useEffect(() => {
    setErrors({}); setSubmitError(""); setForm(EMPTY);
  }, [open, id]);
  useEffect(() => {
    if (!open || !record.data || id === null) return;
    const business = record.data;
    // Send only editable business fields; IDs and metadata remain server-owned.
    setForm({
      businessAccountNumber: business.businessAccountNumber, businessName: business.businessName,
      ownerFirstName: business.ownerFirstName, ownerLastName: business.ownerLastName,
      houseNumber: business.houseNumber, street: business.street, barangay: business.barangay,
      city: business.city, phoneNumber: business.phoneNumber, email: business.email,
      marketSectionId: business.marketSectionId, businessType: business.businessType, stallNumber: business.stallNumber
    });
  }, [open, id, record.data]);

  const update = <K extends keyof SaveBusinessRequest>(key: K, value: SaveBusinessRequest[K]) => {
    setForm(previous => ({ ...previous, [key]: value }));
    setErrors(previous => ({
      ...previous, [key]: undefined,
      ...(key === "businessType" ? { stallNumber: undefined } : {})
    })); setSubmitError("");
  };
  const submit = async () => {
    if (savePending.current || (id !== null && (record.isFetching || record.isError))) return;
    const next = validateBusiness(form); setErrors(next);
    if (Object.keys(next).length) return;
    savePending.current = true;
    setSaving(true); setSubmitError("");
    try {
      await adminVendorsApi.saveBusiness(id, form);
      onClose();
      await onSaved();
    } catch (error) {
      setSubmitError(getApiErrorMessage(error, "Business record could not be saved. Please try again."));
    } finally { savePending.current = false; setSaving(false); }
  };
  return {
    form, errors, saving, submitError, update, submit, createdAt: record.data?.createdAt,
    loading: id !== null && record.isFetching, loadError: id !== null && record.isError
      ? getApiErrorMessage(record.error, "Unable to load this business.") : "", retry: record.refetch
  };
}
