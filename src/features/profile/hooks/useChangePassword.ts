import { useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { authApi } from "@/api/endpoints/auth.api";
import { useAuth } from "@/context/AuthContext";
import { useAuthStore } from "@/store/store";
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
  const { user, clearMustChangePassword } = useAuth();
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const errors = validatePasswordForm(values);

  async function submit() {
    if (saving.current || Object.keys(validatePasswordForm(values)).length > 0)
      return;
    saving.current = true;
    setIsSaving(true);
    setError(null);
    try {
      await authApi.mandatoryChangePassword(values);
      if (!user || useAuthStore.getState().user?.userId !== user.userId) return;
      clearMustChangePassword();
      void queryClient.invalidateQueries({
        queryKey: ["profile", user?.userId],
      });
      showToast({ title: "Password updated", variant: "success" });
      onClose();
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
      values.newPassword.length >= 6 &&
      values.confirmNewPassword === values.newPassword,
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
