import Table from "@/components/ui/Table";
import {
  RecordBadge,
  RecordActions,
  RecordsState,
} from "@/components/ui/Records";
import type { InspectionSummary } from "@/api/types/ticket.types";
import { INSPECTION_COLUMNS } from "../inspections.utils";
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
            ...INSPECTION_COLUMNS.map((column) => ({
              key: column.key,
              header: column.header,
              render: (row: InspectionSummary) =>
                column.key === "type" ? (
                  <RecordBadge value={column.value(row)} />
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
