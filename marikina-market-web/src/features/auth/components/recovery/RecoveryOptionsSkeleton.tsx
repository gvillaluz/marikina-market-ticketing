import RecoveryOptionSkeleton from "./RecoveryOptionSkeleton";
import styles from "./RecoveryOptionsSkeleton.module.css";

export default function RecoveryOptionsSkeleton() {
  return (
    <div role="status" aria-label="Finding your account" aria-busy="true">
      <p className={styles.description}>Finding your account…</p>
      <div className={styles.options}>
        {Array.from({ length: 3 }, (_, index) => (
          <RecoveryOptionSkeleton key={index} />
        ))}
      </div>
    </div>
  );
}
