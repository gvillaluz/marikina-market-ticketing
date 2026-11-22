import BusinessCell from "@/components/ui/BusinessCell";
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
const SEARCHED_COLUMNS = new Set(["violator", "enforcer"]);
// On screen the owner sits under the business and the control number is left out;
// Export and Print keep both as their own columns.
const TABLE_COLUMNS = INSPECTION_COLUMNS.filter(
  (column) =>
    column.key !== "registeredOwner" && column.key !== "controlNumber",
);
const OWNER_COLUMN = INSPECTION_COLUMNS.find(
  (column) => column.key === "registeredOwner",
)!;

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
            ...TABLE_COLUMNS.map((column) => ({
              key: column.key,
              header:
                column.key === "businessName" ? "Business" : column.header,
              render: (row: InspectionSummary) =>
                column.key === "businessName" ? (
                  <BusinessCell
                    vendorId={row.vendorId}
                    name={column.value(row)}
                    owner={OWNER_COLUMN.value(row)}
                    search={search}
                  />
                ) : column.key === "type" ? (
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
