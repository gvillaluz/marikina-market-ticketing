import styles from "./BackupMessage.module.css";

interface BackupMessageProps {
  message: string;
  error?: boolean;
  pending?: boolean;
  onRetry?: () => void;
}

export default function BackupMessage({
  message,
  error = false,
  pending = false,
  onRetry,
}: BackupMessageProps) {
  return (
    <div
      className={`${styles.message} ${error ? styles.error : ""}`}
      role={error ? "alert" : "status"}
    >
      <p>{message}</p>
      {onRetry && (
        <button
          type="button"
          className={styles.retry}
          disabled={pending}
          onClick={onRetry}
        >
          {pending ? "Retrying…" : "Try again"}
        </button>
      )}
    </div>
  );
}
