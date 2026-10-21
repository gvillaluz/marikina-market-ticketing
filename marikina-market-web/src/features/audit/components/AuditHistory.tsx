import Table, { type Column } from "@/components/ui/Table/Table";
import Pagination from "@/components/ui/Pagination/Pagination";
import { Badge } from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import type { AuditLogsModel } from "../hooks/useAuditLogs";
import type { AuditLogRecord } from "../audit.types";
import { formatAuditTimestamp } from "../audit.utils";
import { AUDIT_MODULE_OPTIONS } from "../audit.constants";
import AuditFilters from "./AuditFilters";
import AuditActivityCell from "./AuditActivityCell";
import AuditActorCell from "./AuditActorCell";
import AuditResultBadge from "./AuditResultBadge";
import AuditViewButton from "./AuditViewButton";
import styles from "./AuditHistory.module.css";
import AuditRequestMessage from "./AuditRequestMessage";

export default function AuditHistory({ model }: { model: AuditLogsModel }) {
  const columns: Column<AuditLogRecord>[] = [
    {
      key: "timestamp",
      header: "Date & time",
      render: (record) => formatAuditTimestamp(record.timestamp),
    },
    {
      key: "action",
      header: "Activity",
      render: (record) => <AuditActivityCell record={record} />,
    },
    {
      key: "module",
      header: "Module",
      render: (record) => (
        <Badge tone="neutral" className={styles.module}>
          {AUDIT_MODULE_OPTIONS.find((option) => option.value === record.module)
            ?.label ?? record.module}
        </Badge>
      ),
    },
    {
      key: "userId",
      header: "Performed by",
      render: (record) => <AuditActorCell record={record} />,
    },
    {
      key: "result",
      header: "Result",
      render: (record) => <AuditResultBadge result={record.result} />,
    },
    {
      key: "view",
      header: "Action",
      render: (record) => (
        <AuditViewButton record={record} onView={model.view} />
      ),
    },
  ];
  return (
    <section className={styles.history} aria-labelledby="audit-history-title">
      <header className={styles.header}>
        <div className={styles.heading}>
          <h2 id="audit-history-title">Activity History</h2>
          <p>Review administrative, security, and record activity.</p>
        </div>
        <AuditFilters model={model} />
      </header>
      {model.error && (
        <AuditRequestMessage
          message={model.error}
          error
          onRetry={model.retry}
          busy={model.isFetching}
        />
      )}
      <div
        className={styles.tableRegion}
        role="region"
        aria-label="Audit log table"
        tabIndex={0}
        aria-busy={model.isFiltering}
      >
        <Table
          columns={columns}
          data={model.items}
          keyExtractor={(record) => String(record.id)}
          className={styles.tableWrapper}
          tableClassName={styles.table}
          loading={model.isFiltering}
          loadingMessage="Loading activities…"
          emptyMessage={
            model.error
              ? "Audit history unavailable."
              : model.hasFilters
                ? "No activities match these filters."
                : "No audit activities recorded yet."
          }
        />
      </div>
      <footer className={styles.footer}>
        <p role="status">{model.rangeLabel}</p>
        <div className={styles.footerActions}>
          {model.hasFilters && (
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className={styles.reset}
              onClick={model.resetFilters}
              disabled={model.isExporting}
            >
              Clear filters
            </Button>
          )}
          <fieldset
            disabled={model.isFetching || model.isExporting}
            aria-label="Audit log pages"
          >
            <Pagination
              compact
              showSinglePage
              page={model.page}
              totalPages={model.totalPages}
              canGoNext={!model.canNext}
              onChange={model.changePage}
              className={styles.pagination}
            />
          </fieldset>
        </div>
      </footer>
    </section>
  );
}
