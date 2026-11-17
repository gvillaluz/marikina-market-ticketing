import { Check, LoaderCircle } from "lucide-react";
import styles from "./AuthSubmitButton.module.css";

interface AuthSubmitButtonProps {
  label: string;
  busyLabel?: string;
  busy?: boolean;
  done?: boolean;
  disabled?: boolean;
  className: string;
}

export default function AuthSubmitButton({
  label,
  busyLabel,
  busy = false,
  done = false,
  disabled = false,
  className,
}: AuthSubmitButtonProps) {
  const state = done ? "done" : busy ? "busy" : "idle";
  return (
    <button
      type="submit"
      className={`${className} ${styles.button}`}
      data-state={state}
      disabled={disabled || busy || done}
      aria-label={done ? "Done" : undefined}
    >
      <span key={state} className={styles.content}>
        {state === "done" && <Check size={18} aria-hidden="true" />}
        {state === "busy" && (
          <LoaderCircle
            className={styles.spinner}
            size={16}
            aria-hidden="true"
          />
        )}
        {state === "idle" && label}
        {state === "busy" && busyLabel}
      </span>
    </button>
  );
}
