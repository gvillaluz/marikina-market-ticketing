import { useEffect, useRef, useState, type FormEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { useAuthStore } from "@/store/store";
import { accountsApi } from "@/api/endpoints/accounts.api";
import { STAFF_ROLES } from "@/api/types/common.types";
import type { CreateStaffAccountRequest } from "@/api/types/accounts.types";
import { useToast } from "@/components/ui/Toast/useToast";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { isValidEmail, isValidPhone } from "@/utils/validators";

export interface StaffAccountForm
  extends Omit<CreateStaffAccountRequest, "middleName"> {
  middleName: string;
}
type FieldErrors = Partial<Record<keyof StaffAccountForm, string>>;
const initialForm = (): StaffAccountForm => ({
  role: "MarketEnforcer",
  firstName: "",
  middleName: "",
  lastName: "",
  dateOfBirth: "",
  email: "",
  phoneNumber: "",
  houseNumber: "",
  street: "",
  barangay: "",
  city: "Marikina City",
});

export function useAddStaffAccount() {
  const canCreate = useAuthStore((state) => state.user?.role === "HeadAdmin");
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState(initialForm);
  const [errors, setErrors] = useState<FieldErrors>({});
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const busy = useRef(false);
  const formRef = useRef<HTMLFormElement | null>(null);
  const errorRef = useRef<HTMLParagraphElement | null>(null);
  useEffect(() => {
    if (open && error) errorRef.current?.focus();
  }, [open, error]);
  function change<K extends keyof StaffAccountForm>(
    key: K,
    value: StaffAccountForm[K],
  ) {
    if (busy.current) return;
    setForm((previous) => ({
      ...previous,
      [key]: value.replace(/[\u0000-\u001f\u007f]/g, ""),
    }));
    setErrors((previous) => ({ ...previous, [key]: undefined }));
    setError("");
  }
  return {
    canCreate,
    open,
    form,
    errors,
    error,
    saving,
    formRef,
    errorRef,
    change,
    show() {
      if (!canCreate || busy.current) return;
      setForm(initialForm());
      setErrors({});
      setError("");
      setOpen(true);
    },
    close() {
      if (busy.current) return;
      setOpen(false);
      setForm(initialForm());
      setErrors({});
      setError("");
    },
    async submit(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (busy.current || !open) return;
      if (!canCreate || useAuthStore.getState().user?.role !== "HeadAdmin") {
        setError("Only Head Admin can create staff accounts.");
        return;
      }
      const next: FieldErrors = {};
      if (!STAFF_ROLES.includes(form.role)) next.role = "Select a staff role.";
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
      setError("");
      if (Object.keys(next).length) {
        window.requestAnimationFrame(() =>
          formRef.current
            ?.querySelector<HTMLElement>('[aria-invalid="true"]')
            ?.focus(),
        );
        return;
      }
      busy.current = true;
      setSaving(true);
      try {
        const phone = form.phoneNumber
          .replace(/[\s-]/g, "")
          .replace(/^\+?63/, "0");
        const request: CreateStaffAccountRequest = {
          role: form.role,
          firstName: form.firstName.trim(),
          middleName: form.middleName.trim() || null,
          lastName: form.lastName.trim(),
          dateOfBirth: form.dateOfBirth,
          email: form.email.trim(),
          phoneNumber: phone,
          houseNumber: form.houseNumber.trim(),
          street: form.street.trim(),
          barangay: form.barangay.trim(),
          city: form.city.trim(),
        };
        const result = await accountsApi.createStaff(request);
        if (
          !result ||
          !Number.isSafeInteger(result.id) ||
          result.id < 1 ||
          typeof result.username !== "string" ||
          !result.username ||
          !STAFF_ROLES.includes(result.role) ||
          result.status !== "Active" ||
          result.mustChangePassword !== true ||
          typeof result.emailSent !== "boolean"
        ) {
          setError(
            "The request completed, but its confirmation was incomplete. Refresh the account list before submitting again.",
          );
          void queryClient.invalidateQueries({ queryKey: ["account-counts"] });
          void queryClient.invalidateQueries({ queryKey: ["accounts"] });
          return;
        }
        showToast({
          title:
            typeof result.message === "string" && result.message.trim()
              ? result.message
              : "Staff account created",
          description: `Username: ${result.username}`,
          variant: "success",
        });
        if (result.emailSent === false)
          showToast({
            title: "Account created; email was not sent",
            description:
              "The account exists, but its notification email could not be delivered.",
            variant: "warning",
            duration: 0,
          });
        setOpen(false);
        setForm(initialForm());
        void queryClient.invalidateQueries({ queryKey: ["account-counts"] });
        void queryClient.invalidateQueries({ queryKey: ["accounts"] });
      } catch (failure) {
        setError(
          getApiErrorMessage(
            failure,
            "Unable to create the staff account. Please try again.",
          ),
        );
      } finally {
        busy.current = false;
        setSaving(false);
      }
    },
  };
}

export type AddStaffAccountModel = ReturnType<typeof useAddStaffAccount>;
