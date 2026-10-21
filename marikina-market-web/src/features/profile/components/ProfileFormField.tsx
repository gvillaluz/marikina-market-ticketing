import { Eye, EyeOff, CircleCheck } from "lucide-react";
import styles from "./ProfileFormField.module.css";

interface ProfileFormFieldProps {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  onBlur: () => void;
  type?: "text" | "email" | "tel" | "date" | "password";
  required?: boolean;
  disabled?: boolean;
  error?: string;
  hint?: string;
  success?: string;
  autoComplete?: string;
  max?: string;
  visible?: boolean;
  onToggle?: () => void;
}

export default function ProfileFormField({
  id,
  label,
  value,
  onChange,
  onBlur,
  type = "text",
  required = true,
  disabled,
  error,
  hint,
  success,
  autoComplete,
  max,
  visible,
  onToggle,
}: ProfileFormFieldProps) {
  const message = error || success || hint;
  return (
    <div className={styles.field}>
      <label htmlFor={id} className={styles.label}>
        {label}
        {!required && <span className={styles.optional}> (optional)</span>}
      </label>
      <div className={styles.control}>
        <input
          id={id}
          className={`${styles.input} ${onToggle ? styles.password : ""} ${error ? styles.invalid : success ? styles.valid : ""}`}
          type={type === "password" && visible ? "text" : type}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          onBlur={onBlur}
          required={required}
          disabled={disabled}
          autoComplete={autoComplete}
          max={max}
          min={type === "date" ? "0001-01-01" : undefined}
          aria-invalid={Boolean(error)}
          aria-describedby={message ? `${id}-message` : undefined}
          spellCheck={type === "password" ? false : undefined}
          autoCapitalize={
            type === "password" || type === "email" ? "none" : undefined
          }
        />
        {onToggle && (
          <button
            type="button"
            className={styles.visibility}
            onClick={onToggle}
            disabled={disabled}
            aria-label={`${visible ? "Hide" : "Show"} ${label.toLowerCase()}`}
            aria-pressed={Boolean(visible)}
          >
            {visible ? (
              <Eye size={16} aria-hidden="true" />
            ) : (
              <EyeOff size={16} aria-hidden="true" />
            )}
          </button>
        )}
      </div>
      {message && (
        <p
          id={`${id}-message`}
          className={`${styles.message} ${error ? styles.error : success ? styles.success : ""}`}
          aria-live="polite"
        >
          {success && !error && <CircleCheck size={14} aria-hidden="true" />}
          {message}
        </p>
      )}
    </div>
  );
}
