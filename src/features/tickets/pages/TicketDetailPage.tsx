import { FC, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { User, ClipboardList, FileWarning, AlertCircle, ImageIcon, ListChecks, HelpCircle, Settings } from 'lucide-react';
import TicketDetailHeader from '../components/detail/TicketDetailHeader';
import DetailCard from '../components/detail/DetailCard';
import InfoField from '../components/detail/InfoField';
import StatusPill from '../components/detail/StatusPill';
import EvidenceThumbnail from '../components/detail/EvidenceThumbnail';
import FineSummaryBox from '../components/detail/FineSummaryBox';
import StatusOptionCard from '../components/detail/StatusOptionCard';
import TicketDetailFooter from '../components/detail/TicketDetailFooter';
import styles from './TicketDetailPage.module.css';
import { RecordStatus, Severity } from '@/api/types/common.types';
import InfoRowField from '../components/detail/InfoRowField';
import { daysLeft, formatCurrency, formatDate, formatDateTime } from '@/utils/formatters';
import TicketDetailSkeleton from '../components/detail/TicketDetailSkeleton';
import TicketDetailError from '../components/detail/TicketDetailError';
import { useTicketDetails } from '../hooks/useTicketDetails';
import EvidenceSection from '../components/detail/EvidenceSection';
import { useUpdateStatus } from '../hooks/useUpdateStatus';
import { TicketModal } from '../components/TicketModal';
import Modal from '@/components/ui/Modal';


const STATUS_OPTIONS = [
  { value: 'Pending', title: 'Pending', description: 'Ticket remains open and pending.' },
  { value: 'Paid', title: 'Paid', description: 'Fine has been fully settled.' },
  { value: 'Contested', title: 'Contested', description: 'Vendor disputed the ticket, under review.' },
  { value: 'Waived', title: 'Waived', description: 'Fine dismissed, no payment required.' },
  { value: 'Cleared', title: 'Cleared', description: 'Resolved via community service or blotter donation.' },
];

const TicketDetailPage: FC = () => {
  const { id } = useParams();
  const { ticket } = useTicketDetails(Number.parseInt(id || ''));
  const [selectedStatus, setSelectedStatus] = useState<RecordStatus>(ticket?.status || 'Pending');
  const [isOpen, setIsOpen] = useState(false);
  const [openConfirmModal, setOpenConfirmModal] = useState(false);
  const { mutate: updateStatus } = useUpdateStatus(Number(id));

  const isLoading = false;
  const error: string | null = null;

  const handleRetry = () => {
    // TODO: call refetch() from the real data-fetching hook once it exists.
  };

  if (isLoading) {
    return (
      <div className={styles.page}>
        <TicketDetailSkeleton />
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.page}>
        <TicketDetailError message={error} onRetry={handleRetry} />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <div className={styles.breadcrumb}>
        <Link to="/tickets" className={styles.breadcrumbLink}>Tickets</Link>
        <span className={styles.breadcrumbSeparator}>›</span>
        <span className={styles.breadcrumbCurrent}>Ticket #{ticket?.controlNumber}</span>
      </div>

      <TicketDetailHeader
        controlNo={ticket?.controlNumber || ''}
        status={ticket?.status ?? 'Paid'}
        lastUpdated={formatDateTime(ticket?.updatedAt || '')}
      />

      <div className={styles.grid}>
        <DetailCard title="ENFORCER & VENDOR DETAILS" icon={User}>
          <div className={styles.fieldGrid}>
            <InfoField label="ENFORCER / INSPECTOR" value={`${ticket?.enforcerLastName}, ${ticket?.enforcerFirstName}`} />
            <InfoField label="VENDOR NAME" value={`${ticket?.lastName}, ${ticket?.firstName}`} />
            <InfoField label="STALL LOCATION" value={`${ticket?.marketSectionName}, ${ticket?.stallNumber}`} />
          </div>
        </DetailCard>

        <DetailCard title="TICKET PARAMETERS" icon={ClipboardList}>
          <div className={styles.fieldGrid}>
            <InfoField label="DATE ISSUED" value={formatDateTime(ticket?.issuedAt || '')} />
            <InfoField
              label="SEVERITY LEVEL"
              value={<StatusPill variant={ticket?.severity?.toString() || ''}>{ticket?.severity}</StatusPill>}
            />
            <InfoField label="PENALTY TYPE" value={ticket?.penaltyType} />
          </div>
        </DetailCard>

        <div className={styles.splitRow}>
          <DetailCard title="VIOLATION & INSPECTION DESCRIPTION" icon={FileWarning} showDivider>
            <div className={styles.stack}>
              {ticket?.violations.map((violation, i) => (
                <InfoField key={i} label="VIOLATION TYPE / ORDINANCE" value={`${violation.ordinanceNo} (${violation.ordinanceCode})`} />
              ))}
              <div className={styles.descriptionBlock}>
                <span className={styles.descriptionLabel}>DESCRIPTION</span>
                <div className={styles.descriptionBox}>
                  {ticket?.description}
                </div>
              </div>
              <div>
                <span className={styles.fieldLabel}>PHOTOGRAPHIC EVIDENCE</span>
                {ticket?.ticketEvidences.length === 0 
                  ? <EvidenceThumbnail caption="No additional media" />
                  : <EvidenceSection images={ticket?.ticketEvidences.map((evidence) => `https://localhost:5001/${evidence}`) || []} />}
              </div>
            </div>
          </DetailCard>

          <DetailCard title="PENALTY & SETTLEMENT STATUS" icon={AlertCircle} showDivider>
            <div className={styles.stack}>
              <InfoField label="PENALTY TYPE" value={ticket?.penaltyType} />
              <FineSummaryBox amount={formatCurrency(ticket?.totalFineAmount || 0)} />
              <div className={styles.fieldFlex}>
                <InfoRowField
                  label="DUE DATE"
                  value={
                    <span className={styles.dueDate}>{`${formatDateTime(ticket?.dueDate || '')} (${daysLeft(ticket?.dueDate || '')})`}</span>
                  }
                />
              </div>
              <div className={styles.noteBox}>
                <HelpCircle className={styles.helpIcon} />
                <span>Settlement must be paid at the Marikina City Treasury Office during municipal business hours.</span>
              </div>
            </div>
          </DetailCard>
        </div>

        <DetailCard title="VENDOR SETTLEMENT VERIFICATION" icon={ImageIcon} full>
          <p className={styles.cardSubtitle}>
            Photo evidence submitted by the vendor as notification of penalty settlement and basis for record update.
          </p>
          {ticket?.ticketReceipts.length === 0 
                  ? <EvidenceThumbnail caption="Media not provided" />
                  : <EvidenceSection images={ticket?.ticketReceipts.map((receipt) => `https://localhost:5001/${receipt}`) || []} />}
        </DetailCard>

        <DetailCard title="UPDATE TICKET STATUS" icon={ListChecks} full dashedBorder>
          <p className={styles.cardSubtitle}>Select the most appropriate status for this ticket.</p>
          <div className={styles.statusOptions}>
            {STATUS_OPTIONS.map((option) => (
              <StatusOptionCard
                key={option.value}
                title={option.title}
                description={option.description}
                selected={selectedStatus === option.value}
                onClick={() => setSelectedStatus(option.value as RecordStatus)}
              />
            ))}
          </div>
        </DetailCard>
      </div>

      <TicketDetailFooter
        onViewFullRecord={() => setIsOpen(true)}
        onChangeStatus={() => setOpenConfirmModal(true)}
      />

      {(isOpen && ticket != null) && <TicketModal isOpen={isOpen} ticketId={ticket?.ticketId} onClose={() => setIsOpen(false)} />}

      {openConfirmModal && 
        <Modal 
          open={openConfirmModal} 
          onClose={() => setOpenConfirmModal(false)}
          footer={
            <>
              <button className={styles.modalCancel} onClick={() => setOpenConfirmModal(false)}>
                Cancel
              </button>
              <button className={styles.modalConfirm} onClick={() => {
                updateStatus({ newStatus: selectedStatus, version: ticket?.version ?? 0 });
                setOpenConfirmModal(false);

                // TODO: add error handling and user feedback
              }}>
                Confirm Update
              </button>
            </>
          }
          size='sm'
        >
          <div className={styles.modalContent}>
            <div className={styles.iconContainer}>
              <Settings size={24} className={styles.settingsIcon} color='#000000' />
            </div>
            <h2 className={styles.modalTitle}>Confirm Status Update</h2>
            <p>
              Are you sure you want to update the status for Ticket <strong>{`#${ticket?.controlNumber}`}</strong>? This action will be recorded in the audit log.
            </p>
          </div>
        </Modal>}

        
    </div>
  );
};

export default TicketDetailPage;