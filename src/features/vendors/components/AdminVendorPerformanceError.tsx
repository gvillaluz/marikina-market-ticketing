import { AlertTriangle, RefreshCw } from "lucide-react";
import Button from "@/components/ui/Button";
import styles from "./AdminVendorPerformanceError.module.css";

interface AdminVendorPerformanceErrorProps {
  title: string;
  message: string;
  onRetry: () => void;
}

export default function AdminVendorPerformanceError({
  title,
  message,
  onRetry,
}: AdminVendorPerformanceErrorProps) {
  return (
    <section className={`${styles.errorCard} motion-enter`} role="alert">
      <span className={styles.errorIcon}><AlertTriangle size={20} /></span>
      <h2>{title}</h2>
      <p>{message}</p>
      <Button
        variant="outline"
        size="sm"
        icon={<RefreshCw size={14} aria-hidden="true" />}
        onClick={onRetry}
      >
        Try again
      </Button>
    </section>
  );
}
