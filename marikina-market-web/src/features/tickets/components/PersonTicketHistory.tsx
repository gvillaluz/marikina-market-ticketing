import { RecordsState } from "@/components/ui/Records";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { usePersonTicketHistory } from "../hooks/usePersonTicketHistory";
import PersonTicketHistoryItem from "./PersonTicketHistoryItem";
import PersonTicketHistorySkeleton from "./PersonTicketHistorySkeleton";
import styles from "./PersonTicketHistory.module.css";

export default function PersonTicketHistory({ personId }: { personId: number }) {
  const history = usePersonTicketHistory(personId);
  return (
    <section className={styles.history} aria-label="Person citation history">
      <header className={styles.header}>
        <h3>Person citation history</h3>
        <p>Across businesses and issuing officers. Warnings are excluded.</p>
      </header>
      {history.isPending && <PersonTicketHistorySkeleton />}
      {history.isError && <RecordsState
        title="Citation history unavailable"
        message={getApiErrorMessage(history.error, "Unable to load person history.")}
        onRetry={history.isFetching ? undefined : () => void history.refetch()}
      />}
      {!history.isPending && !history.isError && history.items.length === 0 && <RecordsState
        title="No citations yet"
        message="No citations linked to this person."
      />}
      {history.items.length > 0 && <ol className={styles.records}>
        {history.items.map(ticket => <PersonTicketHistoryItem key={ticket.ticketId} ticket={ticket} />)}
      </ol>}
      {history.hasNextPage && <button type="button" className={styles.more} disabled={history.isFetchingNextPage} onClick={() => void history.fetchNextPage()}>
        {history.isFetchingNextPage ? "Loading…" : "Load more citations"}
      </button>}
    </section>
  );
}
