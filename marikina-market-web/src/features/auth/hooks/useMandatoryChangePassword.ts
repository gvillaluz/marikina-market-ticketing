import { useRef, useState, type FormEvent } from "react";
import { useAuth } from "@/context/AuthContext";
import { authApi } from "@/api/endpoints/auth.api";
import { useToast } from "@/components/ui/Toast/useToast";
import { validatePasswordForm } from "@/features/profile";
import type { PasswordValues } from "@/features/profile/profile.validation";
import { getApiErrorMessage } from "@/utils/apiErrors";

type Field = keyof PasswordValues;
type FieldErrors = Partial<Record<Field, string>>;

const EMPTY_VALUES: PasswordValues = {
  currentPassword: "",
  newPassword: "",
  confirmNewPassword: "",
};
const NONE_SHOWN: Record<Field, boolean> = {
  currentPassword: false,
  newPassword: false,
  confirmNewPassword: false,
};

export function useMandatoryChangePassword() {
  const [values, setValues] = useState<PasswordValues>(EMPTY_VALUES);
  const [shown, setShown] = useState(NONE_SHOWN);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const busy = useRef(false);
  const { logout } = useAuth();
  const { showToast } = useToast();

  return {
    values,
    shown,
    fieldErrors,
    error,
    loading,
    change(field: Field, value: string) {
      if (busy.current) return;
      setValues((current) => ({ ...current, [field]: value }));
      setFieldErrors((current) => ({ ...current, [field]: undefined }));
      setError("");
    },
    toggleShown(field: Field) {
      setShown((current) => ({ ...current, [field]: !current[field] }));
    },
    backToSignIn: logout,
    async submit(
      event: FormEvent<HTMLFormElement>,
    ): Promise<Field | undefined> {
      event.preventDefault();
      if (busy.current) return;
      setError("");
      const problems = validatePasswordForm(values);
      setFieldErrors(problems);
      const [firstWrong] = Object.keys(problems) as Field[];
      if (firstWrong) return firstWrong;
      busy.current = true;
      setLoading(true);
      try {
        await authApi.mandatoryChangePassword(values);
        showToast({
          title: "Password changed",
          description: "Please sign in again with your new password.",
          variant: "success",
        });
        logout();
      } catch (failure) {
        setError(
          getApiErrorMessage(
            failure,
            "Failed to change password. Please try again.",
          ),
        );
      } finally {
        busy.current = false;
        setLoading(false);
      }
    },
  };
}
