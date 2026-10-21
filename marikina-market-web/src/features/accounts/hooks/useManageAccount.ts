import { useEffect, useRef, useState, type FormEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { accountsApi } from "@/api/endpoints/accounts.api";
import type {
  AccountDetails,
  UpdateAccountRequest,
} from "@/api/types/accounts.types";
import type { UserRole } from "@/api/types/common.types";
import { useAuthStore } from "@/store/store";
import { useToast } from "@/components/ui/Toast/useToast";
import { getApiErrorMessage, ApiRequestError } from "@/utils/apiErrors";
import { isValidEmail, isValidPhone } from "@/utils/validators";

type AccountForm = Omit<
  UpdateAccountRequest,
  "version" | "middleName" | "email" | "phoneNumber"
> & {
  middleName: string;
  email: string;
  phoneNumber: string;
  role: UserRole | null;
};
const emptyForm = (): AccountForm => ({
  role: null,
  firstName: "",
  middleName: "",
  lastName: "",
  dateOfBirth: "",
  email: "",
  phoneNumber: "",
  houseNumber: "",
  street: "",
  barangay: "",
  city: "",
});
type FieldErrors = Partial<Record<keyof AccountForm, string>>;

export function useManageAccount() {
  const currentUser = useAuthStore((state) => state.user);
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [open, setOpen] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [details, setDetails] = useState<AccountDetails | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [errors, setErrors] = useState<FieldErrors>({});
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [stale, setStale] = useState(false);
  const busy = useRef(false);
  const savePending = useRef(false);
  const generation = useRef(0);
  const formRef = useRef<HTMLFormElement | null>(null);
  const errorRef = useRef<HTMLParagraphElement | null>(null);
  useEffect(() => {
    if (open && error) errorRef.current?.focus();
  }, [open, error]);
  useEffect(() => {
    generation.current++;
    busy.current = false;
    savePending.current = false;
    setOpen(false);
    setDetails(null);
    setSelectedId(null);
    setForm(emptyForm());
    setLoading(false);
    setSaving(false);
    setStale(false);
    setErrors({});
    setError("");
  }, [currentUser?.userId, currentUser?.role]);

  async function show(id: number, preserveEdits = false) {
    const actor = useAuthStore.getState().user;
    if (
      busy.current ||
      actor?.role !== "HeadAdmin" ||
      id === actor.userId ||
      !Number.isSafeInteger(id) ||
      id < 1
    )
      return;
    const requestGeneration = ++generation.current;
    busy.current = true;
    setOpen(true);
    setSelectedId(id);
    if (!preserveEdits) {
      setDetails(null);
      setForm(emptyForm());
      setStale(false);
    }
    setLoading(true);
    setErrors({});
    setError("");
    try {
      const account = await accountsApi.getAccount(id);
      if (
        requestGeneration !== generation.current ||
        useAuthStore.getState().user?.userId !== actor.userId
      )
        return;
      setDetails(account);
      setStale(false);
      setForm({
        role: account.role,
        firstName: account.firstName,
        middleName: account.middleName ?? "",
        lastName: account.lastName,
        dateOfBirth: account.dateOfBirth,
        email: account.email ?? "",
        phoneNumber: account.phoneNumber ?? "",
        houseNumber: account.houseNumber,
        street: account.street,
        barangay: account.barangay,
        city: account.city,
      });
    } catch (failure) {
      if (requestGeneration === generation.current)
        setError(
          getApiErrorMessage(
            failure,
            "Unable to load this account. Try again.",
          ),
        );
    } finally {
      if (requestGeneration === generation.current) {
        busy.current = false;
        setLoading(false);
      }
    }
  }
  return {
    open,
    selectedId,
    details,
    form,
    errors,
    error,
    loading,
    saving,
    stale,
    formRef,
    errorRef,
    canSave:
      currentUser?.role === "HeadAdmin" &&
      details !== null &&
      !loading &&
      !stale,
    show,
    reload() {
      if (selectedId !== null) return show(selectedId, true);
    },
    close() {
      if (savePending.current) return;
      generation.current++;
      busy.current = false;
      setOpen(false);
      setDetails(null);
      setSelectedId(null);
      setForm(emptyForm());
      setError("");
      setErrors({});
    },
    change<K extends keyof AccountForm>(key: K, value: AccountForm[K]) {
      if (busy.current || key === "role" || value === null) return;
      setForm((previous) => ({
        ...previous,
        [key]: value.replace(/[\u0000-\u001f\u007f]/g, ""),
      }));
      setErrors((previous) => ({ ...previous, [key]: undefined }));
      if (!stale) setError("");
    },
    async submit(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      const actor = useAuthStore.getState().user;
      if (
        busy.current ||
        !open ||
        !details ||
        stale ||
        actor?.role !== "HeadAdmin" ||
        actor.userId === selectedId
      )
        return;
      const next: FieldErrors = {};
      for (const key of [
        "firstName",
        "lastName",
        "houseNumber",
        "street",
        "barangay",
        "city",
      ] as const)
        if (!form[key].trim()) next[key] = "This field is required.";
      if (!isValidEmail(form.email.trim()))
        next.email = "Enter a valid email address.";
      if (!isValidPhone(form.phoneNumber))
        next.phoneNumber = "Enter a valid Philippine mobile number.";
      const date = new Date(`${form.dateOfBirth}T00:00:00`);
      const [year, month, day] = form.dateOfBirth.split("-").map(Number);
      if (
        !/^\d{4}-\d{2}-\d{2}$/.test(form.dateOfBirth) ||
        date.getFullYear() !== year ||
        date.getMonth() + 1 !== month ||
        date.getDate() !== day ||
        date > new Date()
      )
        next.dateOfBirth =
          "Enter a valid birth date that is not in the future.";
      setErrors(next);
      if (Object.keys(next).length) {
        window.requestAnimationFrame(() =>
          formRef.current
            ?.querySelector<HTMLElement>('[aria-invalid="true"]')
            ?.focus(),
        );
        return;
      }
      busy.current = true;
      savePending.current = true;
      setSaving(true);
      setError("");
      const requestGeneration = generation.current;
      try {
        await accountsApi.updateAccount(details.id, {
          version: details.version,
          firstName: form.firstName.trim(),
          middleName: form.middleName.trim() || null,
          lastName: form.lastName.trim(),
          dateOfBirth: form.dateOfBirth,
          email: form.email.trim(),
          phoneNumber: form.phoneNumber
            .replace(/[\s-]/g, "")
            .replace(/^\+?63/, "0"),
          houseNumber: form.houseNumber.trim(),
          street: form.street.trim(),
          barangay: form.barangay.trim(),
          city: form.city.trim(),
        });
        if (
          requestGeneration !== generation.current ||
          useAuthStore.getState().user?.userId !== actor.userId
        )
          return;
        showToast({ title: "Account updated", variant: "success" });
        setOpen(false);
        setDetails(null);
        setForm(emptyForm());
        void queryClient.invalidateQueries({ queryKey: ["accounts"] });
        void queryClient.invalidateQueries({ queryKey: ["account-counts"] });
      } catch (failure) {
        if (requestGeneration !== generation.current) return;
        if (failure instanceof ApiRequestError && failure.status === 409)
          setStale(true);
        setError(
          getApiErrorMessage(
            failure,
            "Unable to update this account. Please try again.",
          ),
        );
      } finally {
        if (requestGeneration === generation.current) {
          busy.current = false;
          savePending.current = false;
          setSaving(false);
        }
      }
    },
  };
}

export type ManageAccountModel = ReturnType<typeof useManageAccount>;
