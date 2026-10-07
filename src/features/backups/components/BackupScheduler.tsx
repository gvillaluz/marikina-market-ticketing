import { RefreshCw } from "lucide-react";
import { Dropdown } from "@/components/ui/Dropdown";
import type { BackupScheduleModel } from "../hooks/useBackupSchedule";
import BackupMessage from "./BackupMessage";
import styles from "./BackupScheduler.module.css";

interface BackupSchedulerProps {
  schedule: BackupScheduleModel;
}

export default function BackupScheduler({ schedule }: BackupSchedulerProps) {
  return (
    <section
      className={styles.card}
      aria-labelledby="backup-schedule-title"
      aria-busy={schedule.isFetching || schedule.isSaving}
    >
      <header className={styles.header}>
        <span className={styles.icon}>
          <RefreshCw size={19} aria-hidden="true" />
        </span>
        <div className={styles.heading}>
          <h2 id="backup-schedule-title">Automatic Backups</h2>
          <p>Schedule secure copies of all application data.</p>
        </div>
        <button
          type="button"
          className={styles.toggle}
          role="switch"
          aria-checked={schedule.fields?.enabled ?? false}
          aria-label="Enable automatic backups"
          disabled={schedule.disabled}
          onClick={() => schedule.change("enabled", !schedule.fields?.enabled)}
        >
          <span />
        </button>
      </header>
      {schedule.isLoading ? (
        <BackupMessage message="Loading backup schedule…" />
      ) : !schedule.fields ? (
        <BackupMessage
          message={schedule.loadError}
          error
          pending={schedule.isFetching}
          onRetry={schedule.retry}
        />
      ) : (
        <form
          className={styles.form}
          onSubmit={(event) => {
            event.preventDefault();
            schedule.submit();
          }}
        >
          {schedule.isError && (
            <BackupMessage
              message={schedule.loadError}
              error
              pending={schedule.isFetching}
              onRetry={schedule.retry}
            />
          )}
          <div className={styles.fields}>
            <div className={styles.field}>
              <label htmlFor="backup-frequency">Frequency</label>
              <Dropdown
                triggerId="backup-frequency"
                ariaLabel="Frequency"
                triggerLabel={schedule.fields.frequency}
                value={schedule.fields.frequency}
                disabled={schedule.disabled}
                fullWidth
                options={schedule.frequencyOptions}
                onChange={(value) => schedule.change("frequency", value)}
              />
            </div>
            {schedule.fields.frequency === "Weekly" && (
              <div className={styles.field}>
                <label htmlFor="backup-weekday">Day of week</label>
                <Dropdown
                  triggerId="backup-weekday"
                  ariaLabel="Day of week"
                  triggerLabel={schedule.weekdayLabel}
                  value={schedule.weekdayValue}
                  disabled={schedule.disabled}
                  fullWidth
                  options={schedule.weekdayOptions}
                  onChange={schedule.changeWeekday}
                />
              </div>
            )}
            <label className={styles.field}>
              Backup time
              <input
                type="time"
                value={schedule.fields.time}
                disabled={schedule.disabled}
                required
                onChange={(event) =>
                  schedule.change("time", event.target.value)
                }
              />
            </label>
            <div className={styles.field}>
              <label htmlFor="backup-retention">Retention period</label>
              <Dropdown
                triggerId="backup-retention"
                ariaLabel="Retention period"
                triggerLabel={schedule.retentionLabel}
                value={schedule.retentionValue}
                disabled={schedule.disabled}
                fullWidth
                options={schedule.retentionOptions}
                onChange={schedule.changeRetention}
              />
            </div>
          </div>
          <div className={styles.actions}>
            <span className={styles.timezone}>{schedule.timeZoneDisplay}</span>
            <button
              type="submit"
              className={styles.save}
              disabled={schedule.disabled}
            >
              {schedule.isSaving ? "Saving…" : "Save Schedule"}
            </button>
          </div>
          {schedule.error && <BackupMessage message={schedule.error} error />}
          {schedule.saved && <BackupMessage message="Backup schedule saved." />}
        </form>
      )}
    </section>
  );
}
