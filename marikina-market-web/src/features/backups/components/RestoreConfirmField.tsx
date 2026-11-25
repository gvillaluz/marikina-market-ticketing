import { Eye, EyeOff } from "lucide-react";
import controls from "@/styles/FormControls.module.css";
import styles from "./RestoreConfirmField.module.css";

interface RestoreConfirmFieldProps {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled: boolean;
  describedBy?: string;
  password?: { visible: boolean; onToggle: () => void };
}

export default function RestoreConfirmField({
  id,
  label,
  value,
  onChange,
  disabled,
  describedBy,
  password,
}: RestoreConfirmFieldProps) {
  return (
    <div className={styles.field}>
      <label htmlFor={id} className={controls.label}>
        {label}
      </label>
      <div className={controls.inputWrap}>
        <input
          id={id}
          className={`${controls.input} ${password ? styles.withToggle : ""}`}
          type={password && !password.visible ? "password" : "text"}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          disabled={disabled}
          autoComplete={password ? "current-password" : "off"}
          autoCapitalize="none"
          spellCheck={false}
          aria-describedby={describedBy}
        />
        {password && (
          <button
            type="button"
            className={styles.toggle}
            onClick={password.onToggle}
            disabled={disabled}
            aria-label={password.visible ? "Hide password" : "Show password"}
            aria-pressed={password.visible}
          >
            {password.visible ? (
              <Eye size={16} aria-hidden="true" />
            ) : (
              <EyeOff size={16} aria-hidden="true" />
            )}
          </button>
        )}
      </div>
    </div>
  );
}
