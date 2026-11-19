import { RefreshCw } from "lucide-react";
import type { AdminCommunityServiceLog } from "@/api/types/admin-vendor.types";
import Modal from "@/components/ui/Modal";
import TicketCommunityServiceSection from "@/components/ui/TicketModal/modal/TicketCommunityServiceSection";
import { useTicketDetails, useTicketSettlement } from "@/features/tickets";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { formatControlNumber, UNREGISTERED_VENDOR } from "@/utils/formatters";
import styles from "./AdminCommunityServiceLogs.module.css";

interface CommunityServiceLogModalProps {
  log: AdminCommunityServiceLog | null;
  onClose: () => void;
}

export default function CommunityServiceLogModal({
  log,
  onClose,
}: CommunityServiceLogModalProps) {
  const { ticket, isLoading, isError, error, refetch } = useTicketDetails(
    log?.ticketId ?? 0,
    log !== null,
  );
  const settlement = useTicketSettlement(ticket);
  const subtitle = log
    ? [
        `Control number ${formatControlNumber(log.controlNumber)}`,
        log.businessAccountNumber &&
          `Business Account Number ${log.businessAccountNumber}`,
      ]
        .filter(Boolean)
        .join(" · ")
    : undefined;

  return (
    <Modal
      open={log !== null}
      onClose={onClose}
      size="lg"
      title={log?.vendorName ?? UNREGISTERED_VENDOR}
      subtitle={subtitle}
    >
      <div className={styles.modalContent}>
        {isError ? (
          <div className={styles.errorState} role="alert">
            <span>
              {getApiErrorMessage(error, "Unable to load community service logs.")}
            </span>
            <button type="button" onClick={() => refetch()}>
              <RefreshCw size={13} aria-hidden="true" />
              Try again
            </button>
          </div>
        ) : isLoading || !ticket ? (
          <p className={styles.modalLoading} role="status">
            Loading community service logs...
          </p>
        ) : (
          <TicketCommunityServiceSection settlement={settlement} />
        )}
      </div>
    </Modal>
  );
}
