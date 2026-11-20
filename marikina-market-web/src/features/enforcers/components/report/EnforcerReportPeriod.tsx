import Button from "@/components/ui/Button";
import type { ReportDocument } from "../../hooks/useReportDocument";
import {
  REPORT_PERIOD_PRESETS,
  isPresetPeriod,
} from "../../enforcerReport.utils";
import styles from "./EnforcerReportPeriod.module.css";

const MESSAGE_ID = "enforcer-report-period-message";

export default function EnforcerReportPeriod({
  model,
}: {
  model: ReportDocument<unknown>;
}) {
  const describedBy = model.validation ? MESSAGE_ID : undefined;
  return (
    <section
      className={styles.panel}
      aria-labelledby="enforcer-report-period-title"
    >
      <div className={styles.header}>
        <h2 id="enforcer-report-period-title">Reporting period</h2>
        <div className={styles.presets} role="group" aria-label="Quick periods">
          {REPORT_PERIOD_PRESETS.map((preset) => {
            const chosen = isPresetPeriod(
              preset.value,
              model.period,
              model.today,
            );
            return (
              <Button
                key={preset.value}
                type="button"
                variant="outline"
                size="sm"
                className={chosen ? styles.chosen : ""}
                aria-pressed={chosen}
                onClick={() => model.choosePreset(preset.value)}
              >
                {preset.label}
              </Button>
            );
          })}
        </div>
      </div>
      <div className={styles.fields}>
        <label className={styles.field} htmlFor="enforcer-report-from">
          From
          <input
            id="enforcer-report-from"
            type="date"
            value={model.period.from}
            max={model.today}
            onChange={(event) => model.changeFrom(event.target.value)}
            aria-invalid={Boolean(model.validation)}
            aria-describedby={describedBy}
            required
          />
        </label>
        <label className={styles.field} htmlFor="enforcer-report-to">
          To
          <input
            id="enforcer-report-to"
            type="date"
            value={model.period.to}
            min={model.period.from || undefined}
            max={model.today}
            onChange={(event) => model.changeTo(event.target.value)}
            aria-invalid={Boolean(model.validation)}
            aria-describedby={describedBy}
            required
          />
        </label>
      </div>
      {model.validation && (
        <p id={MESSAGE_ID} className={styles.message} role="alert">
          {model.validation}
        </p>
      )}
    </section>
  );
}
