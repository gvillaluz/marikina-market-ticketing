import { RotateCcw } from "lucide-react";
import { useRestorePauseCheck } from "@/hooks/useRestorePauseCheck";
import { useRestorePauseStore } from "@/store/store";
import styles from "./RestorePauseBanner.module.css";

// Shown to everyone while a backup restore has paused the system.
export default function RestorePauseBanner() {
  const paused = useRestorePauseStore((state) => state.paused);
  useRestorePauseCheck(paused);
  if (!paused) return null;
  return (
    <div className={styles.banner} role="status">
      <RotateCcw className={styles.icon} size={16} aria-hidden="true" />
      <p>The system is being restored. Try again in a few minutes.</p>
    </div>
  );
}
