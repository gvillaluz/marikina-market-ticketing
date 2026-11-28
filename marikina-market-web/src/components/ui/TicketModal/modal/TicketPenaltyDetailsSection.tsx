import { AlertCircle } from "lucide-react";
import TicketSectionHeader from "./TicketSectionHeader";
import TicketInfoRow from "./TicketInfoRow";
import styles from "./TicketPenaltyDetailsSection.module.css";
import { TicketDetail } from "@/api/types/ticket.types";
import { SeverityLevelBadge } from "@/components/ui/SeverityLevelBadge/SeverityLevelBadge";
import { formatCurrency, formatDateTime } from "@/utils/formatters";
import {
  getTicketTotalFineAmount,
  formatPenaltyType,
} from "@/features/tickets";

function TicketPenaltyDetailsSection({ detail }: { detail?: TicketDetail }) {
  const totalFine = getTicketTotalFineAmount(detail);

  return (
    <>
      <TicketSectionHeader title={"PENALTY DETAILS"} icon={AlertCircle} />
      <section className={styles.penaltySection}>
        <TicketInfoRow
          label="SEVERITY:"
          value={<SeverityLevelBadge level={detail?.severityLevel} />}
        />
        <TicketInfoRow
          label="PENALTY TYPE:"
          value={formatPenaltyType(detail?.penaltyType)}
        />
        <TicketInfoRow
          label="DUE DATE:"
          value={formatDateTime(detail?.dueDate || "")}
        />

        {detail?.penaltyType === "CashFine" && (
          <>
            <div className={styles.fineBox}>
              <div className={styles.fineHeader}>
                <span className={styles.fineLabel}>Total Fine Due:</span>
                <span className={styles.fineValue}>
                  {totalFine == null ? "—" : formatCurrency(totalFine)}
                </span>
              </div>
            </div>
            <p className={styles.fineNote}>
              Please settle the fine on or before the due date to avoid
              additional penalties.
            </p>
          </>
        )}
      </section>
    </>
  );
}

export default TicketPenaltyDetailsSection;
