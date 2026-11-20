import type { ReactNode } from "react";
import { FileSpreadsheet, Printer } from "lucide-react";
import Button from "@/components/ui/Button";
import { RecordsState } from "@/components/ui/Records";
import type { ReportDocument } from "../../hooks/useReportDocument";
import EnforcerReportSkeleton from "./EnforcerReportSkeleton";
import styles from "./EnforcerReportPreview.module.css";

// The report panel: Print and CSV buttons, then loading, failure, or the paper given as children.
export default function EnforcerReportPreview({
  model,
  children,
}: {
  model: ReportDocument<unknown>;
  children: ReactNode;
}) {
  const disabled = !model.report;
  return (
    <section
      className={styles.panel}
      aria-labelledby="enforcer-report-preview-title"
      aria-busy={model.loading}
    >
      <div className={styles.header}>
        <h2 id="enforcer-report-preview-title">Report preview</h2>
        <div className={styles.actions}>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            onClick={model.print}
            icon={<Printer size={14} aria-hidden="true" />}
          >
            Print
          </Button>
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={disabled}
            onClick={model.exportCsv}
            icon={<FileSpreadsheet size={14} aria-hidden="true" />}
          >
            Export CSV
          </Button>
        </div>
      </div>
      <div className={styles.body}>
        {model.loading ? (
          <EnforcerReportSkeleton />
        ) : model.error ? (
          <RecordsState
            title="Report not loaded"
            message={model.error}
            onRetry={model.retry}
          />
        ) : model.report ? (
          children
        ) : (
          <RecordsState
            title="No report to show"
            message="Fix the dates above to see the report."
          />
        )}
      </div>
    </section>
  );
}
