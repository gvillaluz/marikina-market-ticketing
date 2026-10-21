import { useId, type ChangeEvent } from "react";
import { Dropdown } from "@/components/ui/Dropdown";
import styles from "./OrdinanceField.module.css";

interface OrdinanceFieldProps {
  label: string;
  ariaLabel?: string;
  value: string;
  onChange: (value: string) => void;
  onBlur: () => void;
  error?: string;
  disabled: boolean;
  placeholder?: string;
  options?: readonly { value: string; label: string }[];
  multiline?: boolean;
  monetary?: boolean;
}

export default function OrdinanceField({
  label,
  ariaLabel,
  value,
  onChange,
  onBlur,
  error,
  disabled,
  placeholder,
  options,
  multiline,
  monetary,
}: OrdinanceFieldProps) {
  const id = useId();
  const inputProps = {
    id,
    value,
    disabled,
    required: true,
    onBlur,
    "aria-label": ariaLabel,
    "aria-invalid": Boolean(error),
    "aria-describedby": error ? `${id}-error` : undefined,
    className: `${styles.control} ${error ? styles.invalid : ""}`,
    onChange: (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      onChange(event.target.value),
  };
  return (
    <div className={styles.field}>
      <label htmlFor={id} className={styles.label}>
        {label}
      </label>
      {options ? (
        <Dropdown
          triggerId={id}
          ariaLabel={ariaLabel ?? label}
          triggerLabel={
            options.find((option) => option.value === value)?.label ??
            placeholder ??
            "Select an option"
          }
          value={value}
          options={options}
          onChange={onChange}
          onBlur={onBlur}
          disabled={disabled}
          invalid={Boolean(error)}
          describedBy={error ? `${id}-error` : undefined}
          fullWidth
          className={styles.dropdown}
        />
      ) : multiline ? (
        <textarea
          {...inputProps}
          className={`${inputProps.className} ${styles.description}`}
          placeholder={placeholder}
          rows={3}
        />
      ) : (
        <input
          {...inputProps}
          type={monetary ? "number" : "text"}
          inputMode={monetary ? "decimal" : undefined}
          min={monetary ? "0" : undefined}
          step={monetary ? "0.01" : undefined}
          placeholder={placeholder}
        />
      )}
      {error && (
        <span id={`${id}-error`} className={styles.error}>
          {error}
        </span>
      )}
    </div>
  );
}
