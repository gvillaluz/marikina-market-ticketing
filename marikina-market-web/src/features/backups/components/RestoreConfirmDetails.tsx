import { TriangleAlert } from "lucide-react";
import RestoreConfirmField from "./RestoreConfirmField";
import styles from "./RestoreConfirmDetails.module.css";

interface RestoreConfirmDetailsProps {
  dateLabel: string;
  confirmation: string;
  password: string;
  passwordVisible: boolean;
  hint: string;
  error: string;
  disabled: boolean;
  onConfirmationChange: (value: string) => void;
  onPasswordChange: (value: string) => void;
  onTogglePassword: () => void;
}

export default function RestoreConfirmDetails({
  dateLabel,
  confirmation,
  password,
  passwordVisible,
  hint,
  error,
  disabled,
  onConfirmationChange,
  onPasswordChange,
  onTogglePassword,
}: RestoreConfirmDetailsProps) {
  return (
    <div className={styles.details}>
      <p className={styles.warning}>
        <TriangleAlert size={16} aria-hidden="true" />
        <span>
          Everything recorded after <strong>{dateLabel}</strong> will be lost
          for everyone.
        </span>
      </p>
      <ul className={styles.facts}>
        <li>
          Kept from today: the audit log, the backup list and the backup
          schedule.
        </li>
        <li>A safety backup of today&apos;s data is made first.</li>
        <li>Everyone is paused while it runs, then signed out.</li>
      </ul>
      <RestoreConfirmField
        id="restore-confirmation"
        label="Type RESTORE to confirm"
        value={confirmation}
        onChange={onConfirmationChange}
        disabled={disabled}
        describedBy="restore-confirm-hint"
      />
      <RestoreConfirmField
        id="restore-password"
        label="Your password"
        value={password}
        onChange={onPasswordChange}
        disabled={disabled}
        describedBy="restore-confirm-hint"
        password={{ visible: passwordVisible, onToggle: onTogglePassword }}
      />
      <p id="restore-confirm-hint" className={styles.hint} aria-live="polite">
        {hint}
      </p>
      {error && (
        <p className={styles.error} role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
