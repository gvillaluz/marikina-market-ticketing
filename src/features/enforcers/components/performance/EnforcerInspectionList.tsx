import { FC } from "react";
import Table from "@/components/ui/Table";
import Button from "@/components/ui/Button";
import { Eye } from "lucide-react";
import { formatDateTime } from "@/utils/formatters";
import styles from "./EnforcerInspectionList.module.css";

interface InspectionRecord {
  id: number;
  controlNumber: string;
  issuedAt: string;
  vendorFirstName: string;
  vendorLastName: string;
  stallNo: string;
  marketSectionName: string;
  type: string;
  status: string;
}

interface EnforcerInspectionListProps {
  records: InspectionRecord[];
  loading?: boolean;
  onView: (id: number) => void;
}

const EnforcerInspectionList: FC<EnforcerInspectionListProps> = ({
  records,
  loading,
  onView,
}) => {
  return (
    <Table
      loading={loading}
      data={records}
      keyExtractor={(record) => record.id.toString()}
      emptyMessage="No inspection records found."
      columns={[
        {
          key: "controlNumber",
          header: "Control #",
          render: (record) => `#${record.controlNumber}`,
        },
        {
          key: "issuedAt",
          header: "Date & Time",
          render: (record) => formatDateTime(record.issuedAt),
        },
        {
          key: "vendor",
          header: "Vendor Name",
          render: (record) =>
            `${record.vendorLastName}, ${record.vendorFirstName}`.trim() || "—",
        },
        {
          key: "stallNo",
          header: "Stall No.",
          render: (record) => record.stallNo || "—",
        },
        {
          key: "section",
          header: "Section",
          render: (record) => record.marketSectionName || "—",
        },
        {
          key: "type",
          header: "Type",
          render: (record) => record.type || "—",
          align: "center",
        },
        {
          key: "status",
          header: "Status",
          render: (record) => {
            const status = (record.status || "").toLowerCase();
            return (
              <div className={`${styles.status} ${styles[status] || ""}`}>
                <span className={styles.span}>{record.status || "—"}</span>
              </div>
            );
          },
          align: "center",
        },
        {
          key: "actions",
          header: "Action",
          render: (record) => (
            <div className={styles.actions}>
              <Button
                icon={<Eye size={14} strokeWidth={3} aria-hidden="true" />}
                className={`${styles.actionBtn} ${styles.view}`}
                size="sm"
                variant="ghost"
                onClick={() => onView(record.id)}
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
