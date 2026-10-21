import { CircleAlert, FolderSearch } from "lucide-react";
import styles from "./RecordsState.module.css";

interface RecordsStateProps {
  title: string;
  message: string;
  onRetry?: () => void;
}
export function RecordsState({ title, message, onRetry }: RecordsStateProps) {
  return (
    <div
      className={`${styles.state} ${onRetry ? styles.error : ""}`}
      role={onRetry ? "alert" : "status"}
    >
      {onRetry ? (
        <CircleAlert size={24} aria-hidden="true" />
      ) : (
        <FolderSearch size={24} aria-hidden="true" />
      )}
      <h3>{title}</h3>
      <p>{message}</p>
      {onRetry && (
        <button type="button" onClick={onRetry}>
          Try again
        </button>
      )}
    </div>
  );
}
