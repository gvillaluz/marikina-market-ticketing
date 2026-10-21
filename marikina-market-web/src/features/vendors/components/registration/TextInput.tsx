import type { InputHTMLAttributes } from "react";
import { Eye, EyeOff } from "lucide-react";
import Button from "@/components/ui/Button";
import { useRegistrationTextInput } from "../../hooks/useRegistrationTextInput";
import styles from "./TextInput.module.css";

interface TextInputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
  required?: boolean;
}

export default function TextInput({
  label,
  error,
  required,
  className = "",
  type,
  ...inputProps
}: TextInputProps) {
  const {
    inputId,
    errorId,
    isPassword,
    inputType,
    showPassword,
    togglePassword,
  } = useRegistrationTextInput(type);

  return (
    <div className={`${styles.field} ${className}`}>
      <label className={styles.label} htmlFor={inputId}>
        {label}
        {required && <span className={styles.required}> *</span>}
      </label>
      <div className={styles.inputWrapper}>
        <input
          {...inputProps}
          id={inputId}
          type={inputType}
          required={required}
          className={`${styles.input} ${isPassword ? styles.password : ""}`}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? errorId : undefined}
        />
        {isPassword && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className={styles.toggle}
            onClick={togglePassword}
            disabled={inputProps.disabled}
            aria-label={`${showPassword ? "Hide" : "Show"} ${label.toLowerCase()}`}
            aria-pressed={showPassword}
          >
            {showPassword ? (
              <EyeOff size={16} aria-hidden="true" />
            ) : (
              <Eye size={16} aria-hidden="true" />
            )}
          </Button>
        )}
      </div>
      {error && (
        <span id={errorId} className={styles.error}>
          {error}
        </span>
      )}
    </div>
  );
}
