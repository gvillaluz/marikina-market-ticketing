import Table from "@/components/ui/Table";
import {
  RecordBadge,
  RecordActions,
  RecordsState,
} from "@/components/ui/Records";
import { formatDateTime } from "@/utils/formatters";
import type { InspectionSummary } from "@/api/types/ticket.types";
import styles from "./InspectionTable.module.css";

interface InspectionTableProps {
  rows: InspectionSummary[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  onView: (ticketId: number) => void;
}
export function InspectionTable({
  rows,
  isLoading,
  isError,
  errorMessage,
  onRetry,
  onView,
}: InspectionTableProps) {
  return (
    <div className={styles.list}>
      {isError ? (
        <RecordsState
          title="Unable to load inspections"
          message={errorMessage}
          onRetry={onRetry}
        />
      ) : (
        <Table
          responsive
          data={rows}
          keyExtractor={(row) => row.ticketId.toString()}
          loading={isLoading}
          emptyMessage="No inspection records match your search or filters."
          columns={[
            { key: "paperReference", header: "Paper reference", render: (row) => row.type === "Ticket" ? (row.paperReference || "Unavailable (legacy record)") : "—" },
            {
              key: "vendor",
              header: "Person",
              render: (row) =>
                row.type === "Ticket"
                  ? `Recorded violator: ${row.paperViolatorName || "Unconfirmed (legacy record)"}`
                  : `Registered owner: ${row.registeredOwnerName || `${row.vendorFirstName ?? ""} ${row.vendorLastName ?? ""}`.trim() || "—"}`,
            },
            {
              key: "enforcer",
              header: "Enforcer",
              render: (row) =>
                `${row.enforcerFirstName ?? ""} ${row.enforcerLastName ?? ""}`.trim() ||
                "\u2014",
            },
            {
              key: "tradeName",
              header: "Trade name",
              render: (row) => row.businessName || "\u2014",
            },
            {
              key: "section",
              header: "Market section",
              render: (row) => row.marketSectionName || "\u2014",
            },
            {
              key: "type",
              header: "Type",
              render: (row) => <RecordBadge value={row.type} />,
            },
            {
              key: "issuedAt",
              header: "Issued at",
              render: (row) => formatDateTime(row.issuedAt),
            },
            {
              key: "actions",
              header: "Actions",
              render: (row) => (
                <RecordActions
                  label={`inspection ${row.ticketId}`}
                  onView={() => onView(row.ticketId)}
                />
              ),
            },
          ]}
        />
      )}
    </div>
  );
}
