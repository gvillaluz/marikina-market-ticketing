import Breadcrumb from "@/components/ui/Breadcrumb";
import { FC } from "react";
import { useParams } from "react-router-dom";
import {
  User,
  ClipboardList,
  FileWarning,
  AlertCircle,
  ImageIcon,
  HelpCircle,
} from "lucide-react";
import TicketDetailHeader from "../components/detail/TicketDetailHeader";
import DetailCard from "../components/detail/DetailCard";
import InfoField from "../components/detail/InfoField";
import StatusPill from "../components/detail/StatusPill";
import EvidenceThumbnail from "../components/detail/EvidenceThumbnail";
import FineSummaryBox from "../components/detail/FineSummaryBox";
import StatusChangeModal from "../components/detail/StatusChangeModal";
import ControlNumber from "../components/detail/ControlNumber";
import ViolationItem from "../components/detail/ViolationItem";
import TicketDetailFooter from "../components/detail/TicketDetailFooter";
import styles from "./TicketDetailPage.module.css";
import InfoRowField from "../components/detail/InfoRowField";
import {
  daysLeft,
  formatCurrency,
  formatDate,
  formatControlNumberLabel,
  formatDateTime,
  UNREGISTERED_VENDOR,
} from "@/utils/formatters";
import TicketDetailSkeleton from "../components/detail/TicketDetailSkeleton";
import TicketDetailError from "../components/detail/TicketDetailError";
import { useTicketDetails } from "../hooks/useTicketDetails";
import { formatPenaltyType, getTicketTotalFineAmount } from "../tickets.utils";
import EvidenceSection from "../components/detail/EvidenceSection";
import TicketPhotoEvidenceSection from "@/components/ui/TicketModal/modal/TicketPhotoEvidenceSection";
import { useUpdateStatus } from "../hooks/useUpdateStatus";
import { TicketModal } from "../../../components/ui/TicketModal/TicketModal";
import { useTicketStatusSelection } from "../hooks/useTicketStatusSelection";
import { useDisclosure } from "../hooks/useDisclosure";
import { getApiErrorMessage } from "@/utils/apiErrors";
import PersonTicketHistory from "../components/PersonTicketHistory";
import TicketChangeHistory from "../components/detail/TicketChangeHistory";

const TicketDetailPage: FC = () => {
  const { id } = useParams();
  const { ticket, refetch, isLoading, isError, error } = useTicketDetails(
    Number(id),
  );
  const {
    selectedStatus,
    setSelectedStatus,
    availableStatuses,
    canUpdateStatus,
    receiptUrls,
    resetSelection,
  } = useTicketStatusSelection(ticket);
  const { mutateAsync: updateStatus, isPending } = useUpdateStatus(Number(id));
  const totalFineAmount = getTicketTotalFineAmount(ticket);

  const recordModal = useDisclosure();
  const statusModal = useDisclosure();

  const handleRetry = () => refetch();

  const closeStatusModal = () => {
    statusModal.close();
    resetSelection();
  };

  const confirmStatusChange = async () => {
    if (!canUpdateStatus || selectedStatus === undefined || !ticket) return;
    try {
      await updateStatus({ newStatus: selectedStatus, version: ticket.version });
      statusModal.close();
    } catch {
      // stays open, error toast already shown via onError in the hook
    }
  };

  if (isLoading) {
    return (
      <div className={styles.page}>
        <TicketDetailSkeleton />
      </div>
    );
  }

  if (isError || !ticket) {
    return (
      <div className={styles.page}>
        <TicketDetailError
          message={
            !Number.isSafeInteger(Number(id)) || Number(id) <= 0
              ? "Invalid ticket ID."
              : getApiErrorMessage(error, "Unable to load this ticket.")
          }
          onRetry={handleRetry}
        />
      </div>
    );
  }

  const isTicket = ticket.type === "Ticket";

  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "Tickets", to: "/tickets" },
          { label: formatControlNumberLabel(ticket?.controlNumber) },
        ]}
      />

      <TicketDetailHeader
        controlNo={ticket?.controlNumber}
        status={isTicket ? ticket.status : undefined}
        lastUpdated={formatDateTime(ticket?.updatedAt || "")}
      />

      {ticket.personId && <PersonTicketHistory personId={ticket.personId} />}
      <div className={styles.grid}>
        <DetailCard title="ENFORCER & VENDOR DETAILS" icon={User}>
          <div className={styles.fieldGrid}>
            <InfoField
              label="ENFORCER / INSPECTOR"
              value={`${ticket?.enforcerLastName}, ${ticket?.enforcerFirstName}`}
            />
            {ticket.vendorId === null ? (
              <InfoField label="VENDOR" value={UNREGISTERED_VENDOR} />
            ) : (
              <>
                <InfoField
                  label="REGISTERED OWNER"
                  value={ticket.businessSnapshot?.registeredOwnerName || "Historical business details unavailable."}
                />
                <InfoField label="BUSINESS ACCOUNT NUMBER" value={ticket.businessSnapshot?.businessAccountNumber || "Unavailable"} />
                <InfoField label="BUSINESS NAME" value={ticket.businessSnapshot?.businessName || "Unavailable"} />
                <InfoField label="BUSINESS TYPE" value={ticket.businessSnapshot?.businessType || "Unavailable"} />
                <InfoField label="BUSINESS ADDRESS" value={ticket.businessSnapshot?.businessAddress || "Unavailable"} />
              </>
            )}
            <InfoField label="RECORDED VIOLATOR" value={ticket.paperViolatorName || "Unconfirmed (legacy record)"} />
            <InfoField label="CONFIRMED PERSON" value={ticket.personId ? `${ticket.personFullName || "Person"} · Person ${ticket.personId}` : "Unconfirmed (legacy record)"} />
            {ticket.vendorId === null ? (
              <InfoField label="MARKET SECTION" value={ticket.marketSectionName} />
            ) : (
              <InfoField
                label="STALL LOCATION"
                value={ticket.businessSnapshot ? [ticket.businessSnapshot.marketSectionName, ticket.businessSnapshot.stallNumber].filter(Boolean).join(", ") : "Historical business details unavailable."}
              />
            )}
          </div>
        </DetailCard>

        <DetailCard title="TICKET PARAMETERS" icon={ClipboardList}>
          <div className={styles.fieldGrid}>
            <InfoField label="CONTROL NUMBER" value={<ControlNumber value={ticket.controlNumber} />} />
            <InfoField label="ISSUE PLACE" value={ticket.issuePlace || "Unavailable (legacy record)"} />
            <InfoField
              label="DATE ISSUED"
              value={formatDateTime(ticket?.issuedAt || "")}
            />
            <InfoField
              label="SEVERITY LEVEL"
              value={
                <StatusPill variant={ticket?.severity?.toString() || ""}>
                  {ticket?.severity}
                </StatusPill>
              }
            />
            <InfoField label="PENALTY TYPE" value={ticket?.penaltyType} />
          </div>
        </DetailCard>

        <div className={styles.splitRow}>
          <DetailCard
            title="VIOLATION & INSPECTION DESCRIPTION"
            icon={FileWarning}
            showDivider
          >
            <div className={styles.stack}>
              {ticket?.violations.map((violation, i) => (
                <ViolationItem
                  key={i}
                  ordinanceNo={violation.ordinanceNo}
                  series={violation.series}
                  section={violation.section}
                  specificCategory={violation.specificCategory}
                />
              ))}
              <div className={styles.descriptionBlock}>
                <span className={styles.descriptionLabel}>DESCRIPTION</span>
                <div className={styles.descriptionBox}>
                  {ticket?.description}
                </div>
              </div>
              <div>
                <span className={styles.fieldLabel}>PHOTOGRAPHIC EVIDENCE</span>
                {ticket?.ticketEvidences.length === 0 ? (
                  <EvidenceThumbnail caption="No additional media" />
                ) : (
                  <TicketPhotoEvidenceSection images={ticket?.ticketEvidences || []} evidenceItems={ticket?.evidenceItems} isTicket={ticket?.type === "Ticket"} />
                )}
              </div>
            </div>
          </DetailCard>

          <div className={styles.sideColumn}>
            <DetailCard
              title="PENALTY & SETTLEMENT STATUS"
              icon={AlertCircle}
              showDivider
            >
              <div className={styles.stack}>
                <InfoField
                  label="PENALTY TYPE"
                  value={formatPenaltyType(ticket?.penaltyType)}
                />
                {ticket.penaltyType === "CashFine" && (
                  <FineSummaryBox
                    amount={
                      totalFineAmount == null
                        ? "—"
                        : formatCurrency(totalFineAmount)
                    }
                  />
                )}
                {ticket.dueDate && (
                  <div className={styles.fieldFlex}>
                    <InfoRowField
                      label="DUE DATE"
                      value={
                        <span
                          className={styles.dueDate}
                        >{`${formatDateTime(ticket.dueDate)} (${daysLeft(ticket.dueDate)})`}</span>
                      }
                    />
                  </div>
                )}
                {ticket.penaltyType === "CashFine" && (
                  <div className={styles.noteBox}>
                    <HelpCircle className={styles.helpIcon} />
                    <span>
                      Settlement must be paid at the Marikina City Treasury Office
                      during municipal business hours.
                    </span>
                  </div>
                )}
              </div>
            </DetailCard>

            <DetailCard
              title="SETTLEMENT VERIFICATION"
              icon={ImageIcon}
              showDivider
            >
              <p className={styles.cardSubtitle}>
                Proof of settlement submitted by the enforcer, used as the basis
                for updating the record.
              </p>
              {receiptUrls.length === 0 ? (
                <p className={styles.noProof}>No proof submitted yet.</p>
              ) : (
                <EvidenceSection images={receiptUrls} />
              )}
            </DetailCard>
          </div>
        </div>

        <TicketChangeHistory ticketId={ticket.ticketId} />
      </div>

      <TicketDetailFooter
        onViewFullRecord={recordModal.open}
        onChangeStatus={statusModal.open}
        canChangeStatus={isTicket}
      />

      {recordModal.isOpen && ticket != null && (
        <TicketModal
          isOpen={recordModal.isOpen}
          ticketId={ticket?.ticketId ?? 0}
          onClose={recordModal.close}
        />
      )}

      <StatusChangeModal
        open={statusModal.isOpen}
        controlNumber={ticket.controlNumber}
        currentStatus={ticket.status}
        selectedStatus={selectedStatus}
        availableStatuses={availableStatuses}
        canUpdate={canUpdateStatus}
        isPending={isPending}
        onSelect={setSelectedStatus}
        onConfirm={() => void confirmStatusChange()}
        onClose={closeStatusModal}
      />
    </div>
  );
};

export default TicketDetailPage;
