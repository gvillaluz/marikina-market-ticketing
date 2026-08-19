import styles from './TicketRecordModal.module.css';
import { Modal } from '../../../components/ui/Modal';
import { Button } from '../../../components/ui/Button';
import { Badge } from '../../../components/ui/Badge';
import { Loader } from '../../../components/feedback/Loader';
import { formatDateTime, formatDate, formatCurrency } from '../../../utils/formatters';
import { useInspectionDetail } from '../hooks/useInspectionDetail';
import type { BadgeTone } from '../../../components/ui/Badge';

interface TicketRecordModalProps {
  isOpen: boolean;
  recordId: string | null;
  onClose: () => void;
}

function offenseTone(level: string): BadgeTone {
  return level.startsWith('1') ? 'success' : 'warning';
}

function statusTone(status: string): BadgeTone {
  if (status === 'PENDING') return 'ticket';
  if (status === 'CLEARED' || status === 'SETTLED') return 'success';
  return 'neutral';
}

function severityTone(severity: string): BadgeTone {
  if (severity === 'grave') return 'ticket';
  if (severity === 'major') return 'warning';
  return 'success';
}

export function TicketRecordModal({ isOpen, recordId, onClose }: TicketRecordModalProps) {
  const { data, isLoading, isError } = useInspectionDetail(recordId, 'ticket');
  const record = data && data.type === 'ticket' ? data : null;

  return (
    <Modal
      open={isOpen}
      title="Ticket Record"
      subtitle="Here is the record of the collected violation ticket."
      onClose={onClose}
      size="lg"
      footer={<Button variant="secondary" onClick={onClose}>Close</Button>}
    >
      {isLoading && <Loader label="Loading ticket record…" />}
      {isError && <p className={styles.errorText}>Unable to load this ticket record.</p>}

      {record && (
        <>
          <div className={styles.header}>
            <div className={styles.officeBlock}>
              <div className={styles.seal} aria-hidden="true">MK</div>
              <div>
                <p className={styles.city}>City of Marikina</p>
                <p className={styles.office}>Marikina Public Market Office</p>
              </div>
            </div>
            <div className={styles.titleBlock}>
              <p className={styles.docTitle}>VIOLATION TICKET</p>
              <p className={styles.controlNumber}>CONTROL NO. {record.controlNumber}</p>
              <Badge tone={statusTone(record.status)}>{record.status}</Badge>
            </div>
          </div>

          <p className={styles.sectionTitle}>Violator Details</p>
          <div className={styles.detailGrid}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Stall/Unit No.</span>
              <span className={styles.detailValue}>{record.stallNo}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Trade Name</span>
              <span className={styles.detailValue}>{record.tradeName}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Name</span>
              <span className={styles.detailValue}>{record.violatorName}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Address</span>
              <span className={styles.detailValue}>{record.address}</span>
            </div>
          </div>

          <p className={styles.sectionTitle}>Violation Details</p>
          {record.violations.map((violation) => (
            <div className={styles.violationRow} key={violation.id}>
              <div>
                <p className={styles.violationName}>{violation.ordinanceName}</p>
                <p className={styles.violationDesc}>{violation.description}</p>
              </div>
              <div className={styles.violationRight}>
                <Badge tone={offenseTone(violation.offenseLevel)}>{violation.offenseLevel}</Badge>
                <span className={styles.amount}>{formatCurrency(violation.amount)}</span>
              </div>
            </div>
          ))}

          <div className={styles.detailGrid} style={{ marginTop: 12 }}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Date & Time</span>
              <span className={styles.detailValue}>{formatDateTime(record.dateTime)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Location</span>
              <span className={styles.detailValue}>{record.location}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Violation Committed</span>
              <span className={styles.detailValue}>{record.violationCommitted}</span>
            </div>
          </div>
          <p className={styles.description}>{record.description}</p>

          <p className={styles.sectionTitle}>Penalty Details</p>
          <div className={styles.penaltyGrid}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Severity</span>
              <Badge tone={severityTone(record.penalty.severity)}>
                {record.penalty.severity.toUpperCase()}
              </Badge>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Penalty Type</span>
              <span className={styles.detailValue}>{record.penalty.penaltyType}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Due Date</span>
              <span className={styles.detailValue}>{formatDate(record.penalty.dueDate)}</span>
            </div>
          </div>

          <div className={styles.totalBar}>
            <span className={styles.totalLabel}>Total Fine Due</span>
            <span className={styles.totalAmount}>{formatCurrency(record.penalty.totalFineDue)}</span>
            <span className={styles.dueNote}>
              Please settle this amount on or before {formatDate(record.penalty.dueDate)}.
            </span>
          </div>

          <div className={styles.issuedGrid}>
            <div>
              <span className={styles.issuedLabel}>Issued By</span>
              <p className={styles.issuedValue}>{record.issuedByName}</p>
              <p className={styles.issuedValue}>{record.issuedByTitle}</p>
              <p className={styles.issuedValue}>{record.issuedByOffice}</p>
            </div>
            <div>
              <span className={styles.issuedLabel}>Issued To</span>
              <p className={styles.issuedValue}>Market Vendor</p>
              <p className={styles.issuedValue}>{formatDate(record.issuedToDate)}</p>
            </div>
          </div>

          <p className={styles.sectionTitle}>Photo Evidence Record</p>
          {record.photoEvidenceUrl ? (
            <img className={styles.photo} src={record.photoEvidenceUrl} alt="Photo evidence of the violation" />
          ) : (
            <div className={styles.photoPlaceholder}>No photo evidence available</div>
          )}
        </>
      )}
    </Modal>
  );
}