import { FC } from "react";
import Table from "@/components/ui/Table";
import BusinessCell from "@/components/ui/BusinessCell";
import Button from "@/components/ui/Button";
import { RecordBadge } from "@/components/ui/Records";
import { Eye } from "lucide-react";
import { formatDateTime } from "@/utils/formatters";
import styles from "./EnforcerInspectionList.module.css";
import { InspectionHistorySummary } from "@/api/types/enforcer.types";

const UNAVAILABLE = "Historical business details unavailable.";

interface EnforcerInspectionListProps {
  records: InspectionHistorySummary[];
  loading?: boolean;
  onView: (id: number) => void;
}

// The same rules as the Inspections page: a ticket shows its business as it was when issued
// and the name written on it; a warning shows the business as it is now and the confirmed person.
const EnforcerInspectionList: FC<EnforcerInspectionListProps> = ({
  records,
  loading,
  onView,
}) => {
  return (
    <Table
      loading={loading}
      data={records}
      keyExtractor={(record) => record.ticketId.toString()}
      emptyMessage="No inspection records found."
      columns={[
        {
          key: "issuedAt",
          header: "Date & Time",
          render: (record) => formatDateTime(record.issuedAt),
        },
        {
          key: "violator",
          header: "Violator",
          render: (record) =>
            (record.type === "Ticket"
              ? record.paperViolatorName
              : record.personFullName) || "Unconfirmed (legacy record)",
        },
        {
          key: "businessName",
          header: "Business",
          render: (record) => (
            <BusinessCell
              vendorId={record.vendorId}
              name={
                record.type === "Ticket"
                  ? record.businessSnapshot?.businessName || UNAVAILABLE
                  : record.businessName || "—"
              }
              owner={
                record.type === "Ticket"
                  ? record.businessSnapshot?.registeredOwnerName || UNAVAILABLE
                  : record.registeredOwnerName || "—"
              }
            />
          ),
        },
        {
          key: "section",
          header: "Market street",
          render: (record) =>
            record.vendorId !== null && record.type === "Ticket"
              ? record.businessSnapshot?.marketSectionName || UNAVAILABLE
              : record.marketSectionName || "—",
        },
        {
          key: "type",
          header: "Type",
          render: (record) => record.type,
          align: "center",
        },
        {
          key: "status",
          header: "Status",
          render: (record) =>
            record.type === "Warning" || !record.status ? (
              "—"
            ) : (
              <RecordBadge value={record.status} />
            ),
          align: "center",
        },
        {
          key: "actions",
          header: "Action",
          render: (record) => (
            <div className={styles.actions}>
              <Button
                icon={<Eye size={14} strokeWidth={3} aria-hidden="true" />}
                className={styles.actionBtn}
                size="sm"
                variant="ghost"
                onClick={() => onView(record.ticketId)}
              >
                View
              </Button>
            </div>
          ),
          align: "center",
        },
      ]}
    />
  );
};

export default EnforcerInspectionList;
