import type { AdminPendingTicketSettlement } from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import { formatControlNumber, formatCurrency } from "@/utils/formatters";
import styles from "../AdminVendorCompliancePanel.module.css";

export default function SettlementCard({
  settlement,
}: {
  settlement: AdminPendingTicketSettlement;
}) {
  const dueDate = new Date(settlement.dueDate);
  const days = Number.isNaN(dueDate.getTime())
    ? null
    : Math.ceil((dueDate.getTime() - Date.now()) / 86400000);
  const dueLabel =
    days === null
      ? "Pending"
      : days < 0
        ? "Overdue"
        : days === 0
          ? "Due today"
          : `${days} days left`;
  const penalty =
    typeof settlement.penaltyType === "string"
      ? settlement.penaltyType.replace(/([a-z])([A-Z])/g, "$1 $2")
      : String(settlement.penaltyType ?? "Other");

  return (
    <Card
      className={`${styles.settlementCard} ${dueLabel === "Overdue" ? styles.overdueCard : ""}`}
    >
      <div className={styles.settlementTop}>
        <strong>
          {settlement.businessId} ·{" "}
          {formatControlNumber(
            settlement.controlNumber,
            `Ticket #${settlement.ticketId}`,
          )}
        </strong>
        <span className={styles.dueLabel}>{dueLabel}</span>
      </div>
      <span className={styles.settlementVendor}>{settlement.vendorName}</span>
      <span className={styles.settlementAmount}>
        {penalty}
        {settlement.totalPaymentAmount != null
          ? ` · ${formatCurrency(settlement.totalPaymentAmount)}`
          : ""}
      </span>
    </Card>
  );
}
