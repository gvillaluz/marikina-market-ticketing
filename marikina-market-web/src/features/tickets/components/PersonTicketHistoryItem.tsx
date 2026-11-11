import { RecordBadge } from "@/components/ui/Records";
import type { PersonTicketHistoryItem as PersonTicketHistoryRecord } from "@/api/types/ticket.types";
import { formatControlNumber, formatCurrency, formatDateTime, UNREGISTERED_VENDOR } from "@/utils/formatters";
import styles from "./PersonTicketHistoryItem.module.css";

export default function PersonTicketHistoryItem({ ticket }: { ticket: PersonTicketHistoryRecord }) {
  const business = ticket.businessName === null
    ? UNREGISTERED_VENDOR
    : ticket.businessSnapshot?.businessName || "Historical business details unavailable.";
  return (
    <li className={styles.card}>
      <div className={styles.top}>
        <div className={styles.heading}>
          <span className={styles.label}>Control number</span>
          <strong className={styles.number}>{formatControlNumber(ticket.paperReference)}</strong>
        </div>
        <span className={styles.status}><RecordBadge value={ticket.status || "Unknown"} /></span>
      </div>
      <p className={styles.business}>{business}</p>
      {ticket.ordinances.length > 0 && <p className={styles.ordinances}>{ticket.ordinances.join("; ")}</p>}
      <dl className={styles.details}>
        <div><dt>Issued</dt><dd>{formatDateTime(ticket.issuedAt)}</dd></div>
        <div><dt>Officer</dt><dd>{ticket.enforcerName}</dd></div>
        <div><dt>Issue place</dt><dd>{ticket.issuePlace || "Unavailable (legacy record)"}</dd></div>
        <div><dt>Recorded violator</dt><dd>{ticket.paperViolatorName || "Unconfirmed"}</dd></div>
      </dl>
      <dl className={styles.amounts}>
        <div><dt>Assessed cash</dt><dd>{ticket.assessedCashFine == null ? "Not cash" : formatCurrency(ticket.assessedCashFine)}</dd></div>
        <div>
          <dt>Outstanding cash</dt>
          <dd className={ticket.outstandingCashFine > 0 ? styles.owed : undefined}>{formatCurrency(ticket.outstandingCashFine)}</dd>
        </div>
      </dl>
    </li>
  );
}
