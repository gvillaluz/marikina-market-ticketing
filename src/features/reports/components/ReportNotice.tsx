import styles from "./ReportNotice.module.css";
export default function ReportNotice({ message }: { message: string }) {
  return (
    <p className={styles.notice} role="alert">
      {message}
    </p>
  );
}
