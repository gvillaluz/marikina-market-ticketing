import { FilePlus2 } from "lucide-react";
import Button from "@/components/ui/Button";
import { Dropdown } from "@/components/ui/Dropdown";
import type { ReportsModel } from "../hooks/useReports";
import { REPORT_TYPES } from "../reports.utils";
import ReportNotice from "./ReportNotice";
import styles from "./ReportGenerator.module.css";

export default function ReportGenerator({
  reports,
}: {
  reports: ReportsModel;
}) {
  const message = reports.validation || reports.generationError;
  return (
    <section className={styles.panel} aria-labelledby="report-generator-title">
      <div className={styles.header}>
        <div>
          <p className={styles.label}>Generate report</p>
          <h2 id="report-generator-title">Choose a reporting period</h2>
        </div>
        <div className={styles.presets} aria-label="Reporting period presets">
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={reports.generating}
            onClick={() => reports.preset("month")}
          >
            This month
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={reports.generating}
            onClick={() => reports.preset("quarter")}
          >
            Last quarter
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={reports.generating}
            onClick={() => reports.preset("year")}
          >
            This year
          </Button>
        </div>
      </div>
      <form
        className={styles.form}
        onSubmit={(event) => {
          event.preventDefault();
          reports.generate();
        }}
        noValidate
      >
        <label className={styles.field} htmlFor="report-from">
          From
          <input
            id="report-from"
            type="date"
            value={reports.input.from}
            max={reports.today}
            disabled={reports.generating}
            onChange={(event) => reports.updateFrom(event.target.value)}
            aria-invalid={Boolean(reports.validation)}
            aria-describedby={message ? "report-form-message" : undefined}
            required
          />
        </label>
        <label className={styles.field} htmlFor="report-to">
          To
          <input
            id="report-to"
            type="date"
            value={reports.input.to}
            min={reports.input.from || undefined}
            max={reports.today}
            disabled={reports.generating}
            onChange={(event) => reports.updateTo(event.target.value)}
            aria-invalid={Boolean(reports.validation)}
            aria-describedby={message ? "report-form-message" : undefined}
            required
          />
        </label>
        <div className={styles.field}>
          <label htmlFor="report-type">Report Type</label>
          <Dropdown
            triggerId="report-type"
            ariaLabel="Report Type"
            triggerLabel={reports.input.type}
            value={reports.input.type}
            disabled={reports.generating}
            onChange={reports.updateType}
            options={REPORT_TYPES.map((type) => ({ value: type, label: type }))}
            className={styles.dropdown}
            fullWidth
          />
        </div>
        <Button
          type="submit"
          size="sm"
          className={styles.generate}
          loading={reports.generating}
          icon={<FilePlus2 size={16} aria-hidden="true" />}
        >
          {reports.generating ? "Generating…" : "Generate Report"}
        </Button>
      </form>
      {message && (
        <div id="report-form-message" className={styles.message}>
          <ReportNotice message={message} />
        </div>
      )}
    </section>
  );
}
