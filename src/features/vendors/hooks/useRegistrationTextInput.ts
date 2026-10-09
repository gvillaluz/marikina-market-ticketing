import { useId, useState } from "react";

export function useRegistrationTextInput(type: string | undefined) {
  const inputId = useId();
  const [showPassword, setShowPassword] = useState(false);
  return {
    inputId,
    errorId: `${inputId}-error`,
    isPassword: type === "password",
    showPassword,
    inputType: type === "password" && showPassword ? "text" : type,
    togglePassword: () => setShowPassword((value) => !value),
  };
}
