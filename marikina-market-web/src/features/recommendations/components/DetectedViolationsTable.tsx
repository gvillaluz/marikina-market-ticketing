import type { DetectedViolation } from "@/api/types/recommendations.types";
import {
  RecordActions,
  RecordBadge,
  RecordsState,
} from "@/components/ui/Records";
import SearchHighlight from "@/components/ui/SearchHighlight";
import Table from "@/components/ui/Table";
import { formatManilaDate } from "../recommendations.format";
import { violationName } from "../recommendations.text";
import styles from "./DetectedViolationsTable.module.css";

interface DetectedViolationsTableProps {
  rows: DetectedViolation[];
  search: string;
  emptyMessage: string;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  onView: (ticketId: number) => void;
}

export default function DetectedViolationsTable({
  rows,
  search,
  emptyMessage,
  isLoading,
  isError,
  errorMessage,
  onRetry,
  onView,
}: DetectedViolationsTableProps) {
  if (isError)
    return (
      <RecordsState
        title="Unable to load detected violations"
        message={errorMessage}
        onRetry={onRetry}
      />
    );

  return (
    <Table
      responsive
      data={rows}
      keyExtractor={(row) => row.ticketId.toString()}
      loading={isLoading}
      emptyMessage={emptyMessage}
      onRowClick={(row) => onView(row.ticketId)}
      columns={[
        {
          key: "controlNumber",
          header: "Control no.",
          render: (row) => (
            <span className={styles.number}>
              {row.controlNumber ? (
                <SearchHighlight text={row.controlNumber} search={search} />
              ) : (
                "No control number"
              )}
            </span>
          ),
        },
        {
          key: "type",
          header: "Type",
          render: (row) => <RecordBadge value={row.type} />,
        },
        {
          key: "issuedAt",
          header: "Date",
          render: (row) => (
            <span className={styles.date}>
              {formatManilaDate(row.issuedAt)}
            </span>
          ),
        },
        { key: "marketSectionName", header: "Street" },
        {
          key: "violations",
          header: "Violation",
          render: (row) => row.categoryCodes.map(violationName).join(", "),
        },
        {
          key: "description",
          header: "Description",
          render: (row) => (
            <span className={styles.description} title={row.description}>
              <SearchHighlight text={row.description} search={search} />
            </span>
          ),
        },
        {
          key: "actions",
          header: "Actions",
          render: (row) => (
            <RecordActions
              label={`${row.type.toLowerCase()} ${row.controlNumber ?? row.ticketId}`}
              onView={() => onView(row.ticketId)}
            />
          ),
        },
      ]}
    />
  );
}
