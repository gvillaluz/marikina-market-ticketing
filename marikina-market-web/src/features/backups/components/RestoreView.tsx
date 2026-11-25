import Button from "@/components/ui/Button";
import type { RestoreView as RestoreViewModel } from "../backups.utils";
import RestoreCounts from "./RestoreCounts";
import RestoreSteps from "./RestoreSteps";
import styles from "./RestoreView.module.css";

interface RestoreViewProps {
  view: RestoreViewModel;
  onSignIn: () => void;
  onBack: () => void;
}

// Takes the place of the Backups page while a restore runs and after it ends.
export default function RestoreView({
  view,
  onSignIn,
  onBack,
}: RestoreViewProps) {
  return (
    <section className={styles.card} aria-labelledby="restore-view-title">
      <header className={styles.header}>
        <h2 id="restore-view-title">{view.title}</h2>
        <p>{view.sourceLabel}</p>
      </header>
      <div className={styles.body}>
        <div className={styles.live} role="status">
          <p className={`${styles.message} ${styles[view.tone]}`}>
            {view.message}
          </p>
          {view.statusLine && (
            <p className={styles.status}>{view.statusLine}</p>
          )}
          {view.note && <p className={styles.note}>{view.note}</p>}
        </div>
        <RestoreSteps steps={view.steps} />
        {view.counts.length > 0 && <RestoreCounts counts={view.counts} />}
      </div>
      {view.action && (
        <footer className={styles.footer}>
          {view.action === "signIn" ? (
            <Button onClick={onSignIn}>Sign in again</Button>
          ) : (
            <Button variant="outline" onClick={onBack}>
              Back to backups
            </Button>
          )}
        </footer>
      )}
    </section>
  );
}
