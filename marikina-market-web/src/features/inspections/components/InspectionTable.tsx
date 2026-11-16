import SearchHighlight from "@/components/ui/SearchHighlight";
import Table from "@/components/ui/Table";
import {
  RecordBadge,
  RecordActions,
  RecordDateTime,
  RecordsState,
} from "@/components/ui/Records";
import type { InspectionSummary } from "@/api/types/ticket.types";
import { INSPECTION_COLUMNS } from "../inspections.utils";
import styles from "./InspectionTable.module.css";

// The columns the inspection search looks at; the search text is highlighted in these.
const SEARCHED_COLUMNS = new Set([
  "controlNumber",
  "violator",
  "enforcer",
  "businessName",
  "registeredOwner",
]);

interface InspectionTableProps {
  rows: InspectionSummary[];
  search: string;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  onView: (ticketId: number) => void;
}
export function InspectionTable({
  rows,
  search,
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
            ...INSPECTION_COLUMNS.map((column) => ({
              key: column.key,
              header: column.header,
              render: (row: InspectionSummary) =>
                column.key === "type" ? (
                  <RecordBadge value={column.value(row)} />
                ) : column.key === "issuedAt" ? (
                  <RecordDateTime value={row.issuedAt} />
                ) : SEARCHED_COLUMNS.has(column.key) ? (
                  <SearchHighlight text={column.value(row)} search={search} />
                ) : (
                  column.value(row)
                ),
            })),
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
