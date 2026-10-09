import type { AuthAccess } from "@/api/types/common.types";
import { useRef, useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import { resolveLoginIdentifier } from "../auth.utils";
import type { LoginFormValues } from "./useLogin";

interface LoginFieldErrors {
  username?: string;
  password?: string;
}

export function useLoginForm(
  access: AuthAccess | undefined,
  submit: (values: LoginFormValues) => Promise<void>,
  loading: boolean,
) {
  const navigate = useNavigate();
  const location = useLocation();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<LoginFieldErrors>({});
  const busy = useRef(false);
  const usernameRef = useRef<HTMLInputElement | null>(null);
  const passwordRef = useRef<HTMLInputElement | null>(null);
  const state: unknown = location.state;
  const passwordReset = Boolean(
    state &&
      typeof state === "object" &&
      (state as Record<string, unknown>).passwordReset === true,
  );
  return {
    username,
    password,
    showPassword,
    fieldErrors,
    passwordReset,
    usernameRef,
    passwordRef,
    changeUsername(value: string) {
      if (!loading && !busy.current) {
        setUsername(value.slice(0, 200).replace(/[\u0000-\u001f\u007f]/g, ""));
        setFieldErrors((errors) => ({ ...errors, username: undefined }));
      }
    },
    changePassword(value: string) {
      if (!loading && !busy.current) {
        setPassword(value);
        setFieldErrors((errors) => ({ ...errors, password: undefined }));
      }
    },
    togglePassword: () => setShowPassword((value) => !value),
    forgotPassword() {
      if (loading || busy.current) return;
      navigate(
        `${ROUTES.forgotPassword(access === "staff" ? "staff" : "vendor")}/${username.trim() ? "options" : "find-account"}`,
        { state: { username: username.trim() } },
      );
    },
    async handleSubmit(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (loading || busy.current) return;
      const errors: LoginFieldErrors = {};
      if (!username.trim()) errors.username = "Enter your username.";
      else if (access !== "staff" && !resolveLoginIdentifier(username))
        errors.username = "Enter your username or email.";
      if (!password.trim()) errors.password = "Enter your password.";
      else if (password.length < 8 || password.length > 128)
        errors.password = "Password must be 8–128 characters.";
      setFieldErrors(errors);
      if (Object.keys(errors).length) {
        (errors.username ? usernameRef : passwordRef).current?.focus();
        return;
      }
      busy.current = true;
      try {
        await submit({ username, password });
      } finally {
        busy.current = false;
      }
    },
  };
}
