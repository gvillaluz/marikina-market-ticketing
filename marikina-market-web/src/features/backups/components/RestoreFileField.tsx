import controls from "@/styles/FormControls.module.css";
import styles from "./RestoreFileField.module.css";

interface RestoreFileFieldProps {
  id: string;
  error: string;
  disabled: boolean;
  onChange: (file: File | null) => void;
}

// The browser's own file chooser, so it works with the keyboard and screen readers as people expect.
export default function RestoreFileField({
  id,
  error,
  disabled,
  onChange,
}: RestoreFileFieldProps) {
  const helpId = `${id}-help`;
  const errorId = `${id}-error`;
  return (
    <div className={styles.field}>
      <label htmlFor={id} className={controls.label}>
        Backup file
      </label>
      <input
        id={id}
        className={`${controls.input} ${styles.input}`}
        type="file"
        accept=".mmbak"
        disabled={disabled}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${helpId} ${errorId}` : helpId}
        onChange={(event) => onChange(event.target.files?.[0] ?? null)}
      />
      <p id={helpId} className={styles.help}>
        A .mmbak file downloaded from this page, up to 256 MB.
      </p>
      {error && (
        <p id={errorId} className={styles.error} role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
