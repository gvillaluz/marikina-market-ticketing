import styles from "./AccountMessage.module.css";

interface AccountMessageProps {
  message: string;
  onRetry?: () => void;
}

export default function AccountMessage({
  message,
  onRetry,
}: AccountMessageProps) {
  return (
    <div className={styles.message} role={onRetry ? "alert" : "status"}>
      <p>{message}</p>
      {onRetry && (
        <button type="button" onClick={onRetry}>
          Retry
        </button>
      )}
    </div>
  );
}
