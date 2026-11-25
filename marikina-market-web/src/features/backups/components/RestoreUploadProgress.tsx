import styles from "./RestoreUploadProgress.module.css";

interface RestoreUploadProgressProps {
  percent: number;
}

export default function RestoreUploadProgress({
  percent,
}: RestoreUploadProgressProps) {
  return (
    <div className={styles.progress}>
      <p id="restore-upload-progress" className={styles.label}>
        Sending the file… {percent}%
      </p>
      <progress
        className={styles.bar}
        max={100}
        value={percent}
        aria-labelledby="restore-upload-progress"
      />
    </div>
  );
}
