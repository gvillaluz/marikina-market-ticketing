import Button from "@/components/ui/Button/Button";
import styles from "./AuditRequestMessage.module.css";

interface AuditRequestMessageProps {
  message: string;
  onRetry?: () => void;
  busy?: boolean;
  error?: boolean;
  className?: string;
}

export default function AuditRequestMessage({
  message,
  onRetry,
  busy = false,
  error = false,
  className = "",
}: AuditRequestMessageProps) {
  return (
    <div
      className={`${styles.message} ${error ? styles.error : ""} ${className}`}
      role={error ? "alert" : "status"}
    >
      <p>{message}</p>
      {onRetry && (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className={styles.retry}
          disabled={busy}
          onClick={onRetry}
        >
          {busy ? "Retrying…" : "Try again"}
        </Button>
      )}
    </div>
  );
}
