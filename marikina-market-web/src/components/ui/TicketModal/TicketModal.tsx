import { useTicketModal } from "@/features/tickets";
import TicketSettlementSection from "./modal/TicketSettlementSection";
import Modal from "@/components/ui/Modal";
import styles from "./TicketModal.module.css";
import brandLogo from "../../../assets/icons/Marikina_City_Seal.svg (1).webp";
import TicketViolationInfoSection from "./modal/TicketViolatorInfoSection";
import TicketViolationDetailsSection from "./modal/TicketViolationDetailsSection";
import TicketPenaltyDetailsSection from "./modal/TicketPenaltyDetailsSection";
import TicketSignatureSection from "./modal/TicketSignatureSection";
import TicketPhotoEvidenceSection from "./modal/TicketPhotoEvidenceSection";
import TicketExportPanel from "./modal/TicketExportPanel";

import { createPortal } from "react-dom";

import TicketModalSkeleton from "./modal/TicketModalSkeleton";
import Button from "@/components/ui/Button";
import { RefreshCw } from "lucide-react";

import { getApiErrorMessage } from "@/utils/apiErrors";

interface TicketModalProps {
  isOpen: boolean;
  ticketId: number;
  onClose: () => void;
}

export function TicketModal({ isOpen, ticketId, onClose }: TicketModalProps) {
  const {
    ticket,
    isLoading,
    isError,
    error,
    refetch,
    ticketPaperRef,
    busyAction,
    exportError,
    isTicket,
    handleExportPNG,
    handleExportPDF,
    startPrint,
  } = useTicketModal(ticketId, isOpen);

  return createPortal(
    <Modal
      open={isOpen}
      title="Inspection Record"
      subtitle="Review the record details, evidence, and available export options."
      onClose={onClose}
      size="xlg"
    >
      <div className={styles.layout}>
        <div className={styles.leftColumn}>
          <div
            ref={ticketPaperRef}
            className={styles.ticketPaper}
            data-ticket-paper
          >
            {isLoading ? (
              <TicketModalSkeleton />
            ) : isError ? (
              <div className={styles.ticketError} role="alert">
                <span>
                  {getApiErrorMessage(
                    error,
                    "Unable to load this inspection record.",
                  )}
                </span>
                <Button
                  size="sm"
                  variant="outline"
                  icon={<RefreshCw size={14} />}
                  onClick={() => void refetch()}
                >
                  Try again
                </Button>
              </div>
            ) : !ticket ? (
              <div className={styles.ticketError} role="status">
                Ticket details are not available.
              </div>
            ) : (
              <>
                <div className={styles.ticketHeader}>
                  <h4>City of Marikina</h4>
                  <p>Marikina City Public Market</p>
                </div>
                <div className={styles.ticketTop}>
                  <div className={styles.brand}>
                    <img
                      className={styles.logo}
                      src={brandLogo}
                      alt="Marikina City Public Market Seal"
                    />
                    <span className={styles.violationLabel}>
                      {isTicket ? "VIOLATION TICKET" : "WRITTEN WARNING TICKET"}
                    </span>
                  </div>
                  {isTicket && (
                    <div className={styles.controlNo}>
                      <span className={styles.controlLabel}>CONTROL NO.</span>
                      <span className={styles.controlValue}>
                        {ticket?.controlNumber || "N/A"}
                      </span>
                    </div>
                  )}
                </div>

                <hr className={styles.divider} />

                <TicketViolationInfoSection detail={ticket} />
                <TicketViolationDetailsSection detail={ticket} />

                {ticket?.type == "Ticket" && (
                  <TicketPenaltyDetailsSection detail={ticket} />
                )}

                <TicketSignatureSection
                  enforcerName={`${ticket?.enforcerLastName}, ${ticket?.enforcerFirstName}`}
                  vendorName={`${ticket?.lastName}, ${ticket?.firstName}`}
                />
              </>
            )}
          </div>

          {!isLoading && !isError && isTicket && (
            <TicketPhotoEvidenceSection
              images={ticket?.ticketEvidences || []}
            />
          )}
          {!isLoading && !isError && ticket && (
            <TicketSettlementSection key={ticket.ticketId} ticket={ticket} />
          )}
        </div>

        <TicketExportPanel
          onExportPNG={handleExportPNG}
          onExportPDF={handleExportPDF}
          onPrint={startPrint}
          disabled={isLoading || isError || !ticket}
          busyAction={busyAction}
          error={exportError}
        />
      </div>
    </Modal>,
    document.body,
  );
}
