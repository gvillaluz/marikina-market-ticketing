import {
  Check,
  Clock3,
  LoaderCircle,
  Pause,
  TriangleAlert,
} from "lucide-react";
import type { BackupHealthModel } from "../hooks/useBackups";
import BackupMessage from "./BackupMessage";
import styles from "./BackupHealth.module.css";

interface BackupHealthProps {
  health: BackupHealthModel;
}

export default function BackupHealth({ health }: BackupHealthProps) {
  const state = health.view?.state;
  const Icon =
    state === "success"
      ? Check
      : state === "failed"
        ? TriangleAlert
        : state === "running"
          ? LoaderCircle
          : state === "disabled"
            ? Pause
            : Clock3;
  return (
    <section
      className={styles.card}
      aria-labelledby="backup-health-title"
      aria-busy={health.isFetching}
    >
      {health.isLoading ? (
        <BackupMessage message="Loading backup health…" />
      ) : !health.view ? (
        <BackupMessage
          message={health.error}
          error
          pending={health.isFetching}
          onRetry={health.retry}
        />
      ) : (
        <>
          {health.isError && (
            <BackupMessage
              message={health.error}
              error
              pending={health.isFetching}
              onRetry={health.retry}
            />
          )}
          <div className={`${styles.icon} ${state ? styles[state] : ""}`}>
            <Icon size={25} aria-hidden="true" />
          </div>
          <h2 className={styles.label} id="backup-health-title">
            Backup Health
          </h2>
          <div className={styles.details} role="status">
            <h3>{health.view.title}</h3>
            <p>{health.view.message}</p>
          </div>
          {health.lastSuccessfulLabel && state !== "success" && (
            <p className={styles.previous}>
              Last successful: {health.lastSuccessfulLabel}
            </p>
          )}
          <dl className={styles.stats}>
            <div>
              <dd>{health.sizeLabel}</dd>
              <dt>Backup size</dt>
            </div>
            <div>
              <dd>{health.retentionLabel}</dd>
              <dt>Retention</dt>
            </div>
          </dl>
        </>
      )}
    </section>
  );
}
