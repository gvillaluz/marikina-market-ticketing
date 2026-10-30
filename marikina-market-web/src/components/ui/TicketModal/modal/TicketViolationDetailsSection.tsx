import { FileWarning } from "lucide-react";
import TicketSectionHeader from "./TicketSectionHeader";
import TicketDetailRow from "../../../../features/tickets/components/TicketDetailRow";
import OrdinanceCard from "./OrdinanceCard";
import styles from "./TicketViolationDetailsSection.module.css";
import TicketInfoRow from "./TicketInfoRow";
import { TicketDetail } from "@/api/types/ticket.types";
import {
  formatCurrency,
  formatDateTime,
  formatOrdinal,
} from "@/utils/formatters";

function TicketViolationDetailsSection({ detail }: { detail?: TicketDetail }) {
  return (
    <>
      <TicketSectionHeader title={"VIOLATION DETAILS"} icon={FileWarning} />
      <section className={styles.detailsSection}>
        {detail?.type === "Ticket" && <>
          <TicketInfoRow label="PAPER REFERENCE" value={detail.paperReference || "Unavailable (legacy record)"} />
          <TicketInfoRow label="ISSUE PLACE" value={detail.issuePlace || "Unavailable (legacy record)"} />
        </>}
        {detail?.type === "Warning" && <>
          <TicketInfoRow label="WARNING REFERENCE" value={detail.controlNumber || "Unavailable (legacy record)"} />
          <TicketInfoRow label="ISSUE PLACE" value={detail.issuePlace || "Unavailable (legacy record)"} />
        </>}
        <div className={styles.ordinanceList}>
          {detail?.violations.map((violation, i) => (
            detail.type === "Warning" ? <TicketInfoRow key={i}
              label={`Ord No. ${violation.ordinanceNo}, Series of ${violation.series}`}
              value={violation.ordinanceCode} /> :
              <OrdinanceCard
                key={i}
                title={`Ord No. ${violation.ordinanceNo}, Series of ${violation.series}`}
                subtitle={violation.ordinanceCode}
                offense={formatOrdinal(violation.offenseCount)}
                price={
                  detail.type === "Ticket" && violation.penaltyAmount
                    ? formatCurrency(violation.penaltyAmount)
                    : undefined
                }
              />
          ))}
        </div>

        <TicketInfoRow
          label="DATE & TIME"
          value={`${formatDateTime(detail?.issuedAt || "")}`}
        />
        <TicketInfoRow label="MARKET SECTION" value={(detail?.type === "Ticket" ? detail.businessSnapshot?.marketSectionName : detail?.marketSectionName)} />
        <TicketInfoRow
          label="VIOLATION COMMITTED"
          value={detail?.categories.join(", ")}
        />

        <div className={styles.descriptionBlock}>
          <span className={styles.descriptionLabel}>DESCRIPTION</span>
          <div className={styles.descriptionBox}>{detail?.description}</div>
        </div>
      </section>
    </>
  );
}

export default TicketViolationDetailsSection;
