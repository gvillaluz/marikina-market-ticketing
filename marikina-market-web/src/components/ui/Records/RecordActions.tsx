import { Eye, RefreshCw } from "lucide-react";
import styles from "./RecordActions.module.css";

export function RecordActions({
  onView,
  onChange,
  label = "record",
}: {
  onView: () => void;
  onChange?: () => void;
  label?: string;
}) {
  return (
    <div className={styles.actions}>
      <button type="button" onClick={onView} aria-label={`View ${label}`}>
        <Eye size={14} aria-hidden="true" />
        View
      </button>
      {onChange && (
        <button
          type="button"
          className={styles.change}
          onClick={onChange}
          aria-label={`Change ${label}`}
        >
          <RefreshCw size={14} aria-hidden="true" />
          Change
        </button>
      )}
    </div>
  );
}
