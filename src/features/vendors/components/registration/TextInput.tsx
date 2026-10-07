import type { InputHTMLAttributes } from "react";
import { useId } from "react";
import styles from "./FormField.module.css";

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
  ...inputProps
}: TextInputProps) {
  const inputId = useId();
  const errorId = `${inputId}-error`;

  return (
    <div className={`${styles.field} ${className}`}>
      <label className={styles.label} htmlFor={inputId}>
        {label}
        {required && <span className={styles.required}> *</span>}
      </label>
      <input
        {...inputProps}
        id={inputId}
        required={required}
        className={`${styles.input} ${error ? styles.invalid : ""}`}
        aria-invalid={Boolean(error)}
        aria-describedby={error ? errorId : undefined}
      />
      {error && (
        <span id={errorId} className={styles.error}>
          {error}
        </span>
      )}
    </div>
  );
}
