import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { personsApi } from "@/api/endpoints/persons.api";
import type { SavePersonRequest } from "@/api/types/person.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { validatePerson, type PersonErrors } from "../person.validation";

const EMPTY: SavePersonRequest = { fullName: "", address: "", phoneNumber: "" };

export function usePersonForm(open: boolean, id: number | null, onSaved: () => Promise<void>, onClose: () => void) {
  const [form, setForm] = useState<SavePersonRequest>(EMPTY);
  const [errors, setErrors] = useState<PersonErrors>({});
  const [saving, setSaving] = useState(false);
  const [submitError, setSubmitError] = useState("");
  const [uncertainCreate, setUncertainCreate] = useState(false);
  const pending = useRef(false);
  const initialized = useRef(false);
  const record = useQuery({
    queryKey: ["person", id], queryFn: () => personsApi.get(id!),
    enabled: open && id !== null, staleTime: 0,
    refetchOnWindowFocus: false, refetchOnReconnect: false,
  });
  useEffect(() => {
    setForm(EMPTY); setErrors({}); setSubmitError(""); setUncertainCreate(false);
    initialized.current = false;
  }, [open, id]);
  useEffect(() => {
    if (!open || id === null || !record.data || record.isFetching || initialized.current) return;
    setForm({ fullName: record.data.fullName, address: record.data.address, phoneNumber: record.data.phoneNumber });
    initialized.current = true;
  }, [open, id, record.data, record.isFetching]);

  const update = (key: keyof SavePersonRequest, value: string) => {
    setForm(previous => ({ ...previous, [key]: value }));
    setErrors(previous => ({ ...previous, [key]: undefined })); setSubmitError("");
  };
  const submit = async () => {
    if (pending.current || uncertainCreate || (id !== null && (record.isFetching || record.isError))) return;
    const next = validatePerson(form); setErrors(next);
    if (Object.keys(next).length) return;
    pending.current = true; setSaving(true); setSubmitError("");
    try {
      await personsApi.save(id, form);
    } catch (error) {
      setSubmitError(getApiErrorMessage(error, "Person could not be saved. Please try again."));
      // A failed create response cannot establish whether the server committed it.
      // Require an explicit registry check before allowing another create.
      if (id === null) setUncertainCreate(true);
      return;
    } finally { pending.current = false; setSaving(false); }
    onClose();
    await onSaved();
  };
  return {
    form, errors, saving, submitError, uncertainCreate, update, submit,
    confirmNotSaved: () => setUncertainCreate(false),
    createdAt: record.data?.createdAt,
    loading: id !== null && record.isFetching,
    loadError: id !== null && record.isError ? getApiErrorMessage(record.error, "Unable to load this person.") : "",
    retry: () => { void record.refetch(); },
  };
}
