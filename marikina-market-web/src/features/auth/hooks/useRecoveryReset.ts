import { useEffect, useRef, useState, type FormEvent } from "react";
import { authApi } from "@/api/endpoints/auth.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useRecoveryReset(
  username: string,
  resetToken: string,
  onComplete: () => void,
) {
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const busy = useRef(false);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  return {
    newPassword,
    confirmPassword,
    showNewPassword,
    showConfirmPassword,
    loading,
    error,
    mismatch: Boolean(confirmPassword && newPassword !== confirmPassword),
    changePassword(value: string) {
      if (!busy.current) {
        setNewPassword(value);
        setError("");
      }
    },
    changeConfirmation(value: string) {
      if (!busy.current) {
        setConfirmPassword(value);
        setError("");
      }
    },
    togglePassword: () => setShowNewPassword((value) => !value),
    toggleConfirmation: () => setShowConfirmPassword((value) => !value),
    async submit(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (busy.current) return;
      setError("");
      if (newPassword.length < 8) {
        setError("Your password must be at least 8 characters long.");
        return;
      }
      if (!/[A-Za-z]/.test(newPassword) || !/\d/.test(newPassword)) {
        setError("Your password must include both letters and numbers.");
        return;
      }
      if (newPassword !== confirmPassword) {
        setError("Passwords do not match.");
        return;
      }
      if (!username.trim() || !resetToken.trim()) {
        setError("Your recovery session expired. Please start again.");
        return;
      }
      busy.current = true;
      setLoading(true);
      try {
        await authApi.resetPassword({ username, newPassword, resetToken });
        if (mounted.current) onComplete();
      } catch (failure) {
        if (mounted.current)
          setError(
            getApiErrorMessage(
              failure,
              "Could not reset your password. Please try again.",
            ),
          );
      } finally {
        busy.current = false;
        if (mounted.current) setLoading(false);
      }
    },
  };
}
