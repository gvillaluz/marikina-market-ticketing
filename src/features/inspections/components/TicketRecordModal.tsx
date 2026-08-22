import styles from './TicketRecordModal.module.css';
import { Modal } from '../../../components/ui/Modal';
import { Button } from '../../../components/ui/Button';
import { Badge } from '../../../components/ui/Badge';
import { Loader } from '../../../components/feedback/Loader';
import { formatDateTime, formatDate, formatCurrency } from '../../../utils/formatters';
import { useInspectionDetail } from '../hooks/useInspectionDetail';
import type { BadgeTone } from '../../../components/ui/Badge';
import type { TicketRecord } from '../../../api/types/ticket.types';
import type { InspectionRecord } from '../../../api/types/ticket.types';
import { BadgeDollarSign, Camera, TriangleAlert, UserRound } from 'lucide-react';
import marikinaSeal from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';

interface TicketRecordModalProps {
  isOpen: boolean;
  recordId: string | null;
  initialRecord?: InspectionRecord | null;
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

export function TicketRecordModal ({ isOpen, recordId, initialRecord, onClose }: TicketRecordModalProps) {
  const { data, isLoading, isError } = useInspectionDetail(recordId, 'ticket');
  const record = (data ?? initialRecord) as TicketRecord | undefined;
  const backendRecord = record as TicketRecord & Record<string, unknown> | undefined;
  const value = (primary: unknown, fallback?: unknown) => String(primary ?? fallback ?? '—');
  const penalty = record?.penalty;
  const violations = record?.violations ?? [];

  return (
    <Modal
      open={isOpen}
      title="Ticket Record"
      subtitle="Here is the record of the collected violation ticket."
      onClose={onClose}
      size="md"
      footer={<Button variant="secondary" onClick={onClose}>Close</Button>}
    >
      {isLoading && <Loader label="Loading ticket record…" />}
      {isError && <p className={styles.errorText}>Unable to load this ticket record.</p>}

      {record && (
        <>
          <div className={styles.document}>
          <div className={styles.header}>
            <div className={styles.officeBlock}>
              <img className={styles.logo} src={marikinaSeal} alt="City of Marikina seal" />
              <p className={styles.city}>City of Marikina</p>
              <p className={styles.office}>Marikina Public Market Office</p>
            </div>
          </div>
          <div className={styles.ticketMeta}>
            <p className={styles.docTitle}>VIOLATION TICKET</p>
            <div className={styles.titleBlock}>
              <p className={styles.controlNumber}>CONTROL NO. {value(record.controlNumber, backendRecord?.ticket_id)}</p>
              <Badge tone={statusTone(value(record.status, backendRecord?.status))}>{value(record.status, backendRecord?.status)}</Badge>
            </div>
          </div>

          <p className={styles.sectionTitle}><UserRound size={13} /> Violator Details</p>
          <div className={styles.detailGrid}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Stall/Unit No.</span>
              <span className={styles.detailValue}>{value(record.stallNo, backendRecord?.stall_number)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Trade Name</span>
              <span className={styles.detailValue}>{value(record.tradeName, backendRecord?.business_name)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Name</span>
              <span className={styles.detailValue}>{value(record.violatorName, `${backendRecord?.vendor_first_name ?? ''} ${backendRecord?.vendor_last_name ?? ''}`.trim())}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Address</span>
              <span className={styles.detailValue}>{value(record.address, backendRecord?.vendor_address)}</span>
            </div>
          </div>

          <p className={styles.sectionTitle}><TriangleAlert size={13} /> Violation Details</p>
          {violations.map((violation) => (
            <div className={styles.violationRow} key={violation.id}>
              <div>
                <p className={styles.violationName}>{value(violation.ordinanceName, backendRecord?.ordinance_name)}</p>
                <p className={styles.violationDesc}>{value(violation.description, backendRecord?.violation_description)}</p>
              </div>
              <div className={styles.violationRight}>
                <Badge tone={offenseTone(violation.offenseLevel)}>{violation.offenseLevel}</Badge>
                <span className={styles.amount}>{formatCurrency(violation.amount ?? Number(backendRecord?.fine_amount ?? 0))}</span>
              </div>
            </div>
          ))}

          <div className={styles.detailGrid} style={{ marginTop: 12 }}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Date & Time</span>
              <span className={styles.detailValue}>{formatDateTime(value(record.dateTime, backendRecord?.issued_at))}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Location</span>
              <span className={styles.detailValue}>{value(record.location, backendRecord?.market_section_name)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Violation Committed</span>
              <span className={styles.detailValue}>{value(record.violationCommitted, backendRecord?.violation_type)}</span>
            </div>
          </div>
          <p className={styles.description}>{value(record.description, backendRecord?.description)}</p>

          <p className={styles.sectionTitle}><BadgeDollarSign size={13} /> Penalty Details</p>
          <div className={styles.penaltyGrid}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Severity</span>
              <Badge tone={severityTone(value(penalty?.severity, backendRecord?.severity))}>
                {value(penalty?.severity, backendRecord?.severity).toUpperCase()}
              </Badge>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Penalty Type</span>
              <span className={styles.detailValue}>{value(penalty?.penaltyType, backendRecord?.penalty_type)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Due Date</span>
              <span className={styles.detailValue}>{formatDate(value(penalty?.dueDate, backendRecord?.due_date))}</span>
            </div>
          </div>

          <div className={styles.totalBar}>
            <span className={styles.totalLabel}>Total Fine Due</span>
            <span className={styles.totalAmount}>{formatCurrency(penalty?.totalFineDue ?? Number(backendRecord?.fine_amount ?? 0))}</span>
            <span className={styles.dueNote}>
              Please settle this amount on or before {formatDate(value(penalty?.dueDate, backendRecord?.due_date))}.
            </span>
          </div>

          <div className={styles.issuedGrid}>
            <div>
              <span className={styles.issuedLabel}>Issued By</span>
              <p className={styles.issuedValue}>{value(record.issuedByName, `${backendRecord?.enforcer_first_name ?? ''} ${backendRecord?.enforcer_last_name ?? ''}`.trim())}</p>
              <p className={styles.issuedValue}>{value(record.issuedByTitle, backendRecord?.enforcer_position)}</p>
              <p className={styles.issuedValue}>{value(record.issuedByOffice, 'Marikina Public Market Office')}</p>
            </div>
            <div>
              <span className={styles.issuedLabel}>Issued To</span>
              <p className={styles.issuedValue}>Market Vendor</p>
              <p className={styles.issuedValue}>{formatDate(value(record.issuedToDate, backendRecord?.issued_at))}</p>
            </div>
          </div>
          </div>
          <div className={styles.photoCard}>
            <p className={styles.sectionTitle}><Camera size={13} /> Photo Evidence Record</p>
            <p className={styles.photoNote}>The image below shows the photo evidence attached to this violation ticket.</p>
            {record.photoEvidenceUrl ? (
              <img className={styles.photo} src={record.photoEvidenceUrl} alt="Photo evidence of the violation" />
            ) : (
              <div className={styles.photoPlaceholder}>No photo evidence available</div>
            )}
          </div>
        </>
      )}
    </Modal>
  );
}