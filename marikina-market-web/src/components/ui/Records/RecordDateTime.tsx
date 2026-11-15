import { formatDate, formatTime } from "@/utils/formatters";
import styles from "./RecordDateTime.module.css";

export function RecordDateTime({ value }: { value: string | Date }) {
  return (
    <span className={styles.dateTime}>
      <span>{formatDate(value)}</span>
      <span>{formatTime(value)}</span>
    </span>
  );
}
