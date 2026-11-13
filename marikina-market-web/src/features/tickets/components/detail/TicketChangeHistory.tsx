import { History } from "lucide-react";
import { USER_ROLE_LABELS } from "@/api/types/common.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { formatDateTime } from "@/utils/formatters";
import { useTicketHistory } from "../../hooks/useTicketHistory";
import DetailCard from "./DetailCard";
import styles from "./TicketChangeHistory.module.css";

export default function TicketChangeHistory({ ticketId }: { ticketId: number }) {
  const history = useTicketHistory(ticketId);
  return (
    <DetailCard title="CHANGE HISTORY" icon={History} full>
      <p className={styles.subtitle}>Newest first.</p>
      {history.isPending ? (
        <p role="status" className={styles.message}>Loading change history…</p>
      ) : history.isError ? (
        <div role="alert" className={styles.error}>
          <p className={styles.message}>{getApiErrorMessage(history.error, "Unable to load the change history.")}</p>
          <button type="button" className={styles.retry} disabled={history.isFetching} onClick={() => void history.refetch()}>
            Try again
          </button>
        </div>
      ) : history.entries.length === 0 ? (
        <p className={styles.message}>No recorded changes for this ticket.</p>
      ) : (
        <div className={styles.scroll}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th scope="col">Action</th>
                <th scope="col">Details</th>
                <th scope="col">By</th>
                <th scope="col">When</th>
              </tr>
            </thead>
            <tbody>
              {history.entries.map((entry, index) => (
                <tr key={`${entry.occurredAt}-${index}`}>
                  <td className={styles.action}>{entry.action}</td>
                  <td>{entry.details}</td>
                  <td>{entry.role ? `${entry.performedBy} (${USER_ROLE_LABELS[entry.role]})` : entry.performedBy}</td>
                  <td className={styles.when}>{formatDateTime(entry.occurredAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </DetailCard>
  );
}
