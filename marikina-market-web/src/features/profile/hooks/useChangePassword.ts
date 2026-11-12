import { useRef, useState } from "react";
import { authApi } from "@/api/endpoints/auth.api";
import { useAuth } from "@/context/AuthContext";
import { useToast } from "@/components/ui/Toast/useToast";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import {
  validatePasswordForm,
  type PasswordValues,
} from "../profile.validation";

export function useChangePassword(onClose: () => void) {
  const [values, setValues] = useState<PasswordValues>({
    currentPassword: "",
    newPassword: "",
    confirmNewPassword: "",
  });
  const [touched, setTouched] = useState<
    Partial<Record<keyof PasswordValues, boolean>>
  >({});
  const [visible, setVisible] = useState<
    Partial<Record<keyof PasswordValues, boolean>>
  >({});
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const saving = useRef(false);
  const { logout } = useAuth();
  const { showToast } = useToast();
  const errors = validatePasswordForm(values);

  async function submit() {
    if (saving.current || Object.keys(validatePasswordForm(values)).length > 0)
      return;
    saving.current = true;
    setIsSaving(true);
    setError(null);
    try {
      await authApi.changePassword(values);
      showToast({
        title: "Password changed",
        description: "Please sign in again with your new password.",
        variant: "success",
      });
      logout();
    } catch (failure: unknown) {
      setError(
        getApiErrorMessage(
          failure instanceof ApiRequestError ? failure : undefined,
          "Unable to change your password. Please try again.",
        ),
      );
    } finally {
      saving.current = false;
      setIsSaving(false);
    }
  }

  return {
    values,
    errors,
    touched,
    visible,
    error,
    isSaving,
    canSubmit: Object.keys(errors).length === 0 && !isSaving,
    matches:
      !errors.newPassword && values.confirmNewPassword === values.newPassword,
    change(field: keyof PasswordValues, value: string) {
      setValues((current) => ({ ...current, [field]: value }));
      setTouched((current) => ({ ...current, [field]: true }));
      setError(null);
    },
    blur(field: keyof PasswordValues) {
      setTouched((current) => ({ ...current, [field]: true }));
    },
    toggle(field: keyof PasswordValues) {
      setVisible((current) => ({ ...current, [field]: !current[field] }));
    },
    submit,
    close: () => {
      if (!saving.current) onClose();
    },
  };
}
