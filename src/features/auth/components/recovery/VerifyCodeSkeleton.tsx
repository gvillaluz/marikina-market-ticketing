import { LoaderCircle } from "lucide-react";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import styles from "./VerifyCodeSkeleton.module.css";

export default function VerifyCodeSkeleton() {
  return (
    <div
      className={styles.form}
      role="status"
      aria-label="Sending verification code"
      aria-busy="true"
    >
      <div className={styles.inputs} aria-hidden="true">
        {Array.from({ length: 6 }, (_, index) => (
          <SkeletonBlock
            key={index}
            height="var(--recovery-code-height)"
            radius="var(--radius-sm)"
          />
        ))}
      </div>
      <div className={styles.status}>
        <LoaderCircle className={styles.spinner} size={16} aria-hidden="true" />
        <span>Sending verification code…</span>
      </div>
      <SkeletonBlock
        height="var(--recovery-control-height)"
        radius="var(--radius-sm)"
      />
    </div>
  );
}
