import { Download, FileSpreadsheet, FileText } from "lucide-react";
import Button from "@/components/ui/Button";
import { RecordsState } from "@/components/ui/Records";
import type { ReportsModel } from "../hooks/useReports";
import { useReportExport } from "../hooks/useReportExport";
import ReportPaper from "./ReportPaper";
import ReportNotice from "./ReportNotice";
import styles from "./ReportPreview.module.css";

export default function ReportPreview({ reports }: { reports: ReportsModel }) {
  const exports = useReportExport(reports.report);
  const disabled =
    !reports.report ||
    reports.loading ||
    reports.generating ||
    exports.busy !== null;
  return (
    <section
      ref={reports.previewRef}
      className={styles.panel}
      aria-labelledby="report-preview-title"
      aria-busy={reports.loading || reports.generating}
    >
      <div className={styles.header}>
        <div>
          <h2 id="report-preview-title">Report Preview</h2>
          <p>Your generated report will appear here.</p>
        </div>
        <div className={styles.actions}>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            loading={exports.busy === "pdf"}
            onClick={() => void exports.download("pdf")}
            icon={<Download size={14} aria-hidden="true" />}
          >
            Download PDF
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            loading={exports.busy === "csv"}
            onClick={() => void exports.download("csv")}
            icon={<FileSpreadsheet size={14} aria-hidden="true" />}
          >
            Export CSV
          </Button>
        </div>
      </div>
      {exports.error && (
        <div className={styles.notice}>
          <ReportNotice message={exports.error} />
        </div>
      )}
      {reports.loading ? (
        <div className={styles.state} role="status">
          <FileText size={26} aria-hidden="true" />
          <h3>Loading report…</h3>
          <p>Preparing your report summary.</p>
        </div>
      ) : reports.error ? (
        <RecordsState
          title="Report unavailable"
          message={reports.error}
          onRetry={reports.retry}
        />
      ) : reports.report ? (
        <div className={styles.document}>
          <ReportPaper report={reports.report} paperRef={exports.paperRef} />
        </div>
      ) : (
        <div className={styles.state} role="status">
          <span className={styles.icon}>
            <FileText size={25} aria-hidden="true" />
          </span>
          <h3>Report Preview</h3>
          <p>
            Select one date to preview, or generate a report for your date
            range.
          </p>
        </div>
      )}
    </section>
  );
}
