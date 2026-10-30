import { usePersonTicketHistory } from "../hooks/usePersonTicketHistory";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { formatCurrency, formatDateTime } from "@/utils/formatters";
import styles from "./PersonTicketHistory.module.css";

export default function PersonTicketHistory({ personId }: { personId: number }) {
  const history = usePersonTicketHistory(personId);
  return (
    <section className={styles.history} aria-label="Person citation history">
      <h3>Person citation history</h3>
      <p>Person {personId} · Across businesses and issuing officers. Warnings are excluded.</p>
      {history.isPending && <p role="status">Loading citation history…</p>}
      {history.isError && <div role="alert">
        <p>{getApiErrorMessage(history.error, "Unable to load person history.")}</p>
        <button type="button" disabled={history.isFetching} onClick={() => void history.refetch()}>Retry</button>
      </div>}
      {!history.isPending && !history.isError && history.items.length === 0 && <p>No citations linked to this person.</p>}
      <ol className={styles.records}>
        {history.items.map(ticket => <li key={ticket.ticketId}>
          <strong>Paper reference: {ticket.paperReference || "Unavailable (legacy record)"} · {ticket.businessSnapshot?.businessName || "Historical business details unavailable."}</strong>
          <p>System control: {ticket.controlNumber || "Unnumbered"}</p>
          <p>Issue place: {ticket.issuePlace || "Unavailable (legacy record)"}</p>
          <p>Recorded violator: {ticket.paperViolatorName || "Unconfirmed"}</p>
          <p>{ticket.ordinances.join("; ")}</p>
          <p>{formatDateTime(ticket.issuedAt)} · {ticket.status || "Unknown"} · Officer: {ticket.enforcerName}</p>
          <p>Assessed cash: {ticket.assessedCashFine == null ? "Not cash" : formatCurrency(ticket.assessedCashFine)} · Outstanding cash: {formatCurrency(ticket.outstandingCashFine)}</p>
        </li>)}
      </ol>
      {history.hasNextPage && <button type="button" disabled={history.isFetchingNextPage} onClick={() => void history.fetchNextPage()}>
        {history.isFetchingNextPage ? "Loading…" : "Load more citations"}
      </button>}
    </section>
  );
}
