import styles from './WrittenWarningModal.module.css';
import { Modal } from '../../../components/ui/Modal';
import { Button } from '../../../components/ui/Button';
import Loader from '../../../components/feedback/Loader/Loader';import { formatDateTime, formatDate } from '../../../utils/formatters';
import { useInspectionDetail } from '../hooks/useInspectionDetail';
import type { InspectionRecord, WarningRecord } from '../../../api/types/ticket.types';
import marikinaSeal from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';
import { TriangleAlert, UserRound } from 'lucide-react';

interface WrittenWarningModalProps {
  isOpen: boolean;
  recordId: string | null;
  initialRecord?: InspectionRecord | null;
  onClose: () => void;
}

export function WrittenWarningModal({ isOpen, recordId, initialRecord, onClose }: WrittenWarningModalProps) {
  const { data, isLoading, isError } = useInspectionDetail(recordId, 'warning');
  const record = (data ?? initialRecord) as WarningRecord | undefined;
  const backendRecord = record as WarningRecord & Record<string, unknown> | undefined;
  const value = (primary: unknown, fallback?: unknown) => String(primary ?? fallback ?? '—');
  const vendorName = backendRecord && value(record?.violatorName, `${backendRecord.vendor_first_name ?? ''} ${backendRecord.vendor_last_name ?? ''}`.trim());
  const enforcerName = backendRecord && value(record?.issuedByName, `${backendRecord.enforcer_first_name ?? ''} ${backendRecord.enforcer_last_name ?? ''}`.trim());

  return (
    <Modal
      open={isOpen}
      title="Written Warning Record"
      subtitle="Here is the record of the collected written warning. You can review the details below."
      onClose={onClose}
    >
      {isLoading && <Loader label="Loading warning record…" />}
      {isError && <p className={styles.errorText}>Unable to load this warning record.</p>}

      {record && (
        <>
          <div className={styles.document}>
          <div className={styles.header}>
            <div className={styles.warningHeading}>
              <img className={styles.logo} src={marikinaSeal} alt="Marikina City seal" />
              <div>
                <p className={styles.city}>City of Marikina</p>
                <p className={styles.office}>Marikina Public Market Office</p>
                <p className={styles.docTitle}>WRITTEN WARNING</p>
              </div>
            </div>
          </div>

          <p className={styles.sectionTitle}><UserRound size={13} /> Violator Details</p>
          <div className={styles.detailGrid}>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Stall/Unit No.</span>
              <span className={styles.detailValue}>{value(record?.stallNo, backendRecord?.stall_number)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Trade Name</span>
              <span className={styles.detailValue}>{value(record?.tradeName, backendRecord?.business_name)}</span>
            </div>
            <div className={styles.detailItem}>
              <span className={styles.detailLabel}>Name</span>
              <span className={styles.detailValue}>{vendorName}</span>
            </div>
          </div>

          <p className={styles.sectionTitle}><TriangleAlert size={13} /> Violation Details</p>
          <div className={styles.ordinanceBox}>
            <p className={styles.ordinanceTitle}>
              Ord. No. {value(record.ordinanceNumber, backendRecord?.ordinance_number)}, Series of {value(record.ordinanceSeries, backendRecord?.ordinance_series)}
            </p>
            <p className={styles.ordinanceSubtitle}>{value(record.ordinanceCategory, backendRecord?.market_section_name)}</p>
          </div>

          <div className={styles.detailGrid}>
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
              <span className={styles.detailValue}>{value(record.violationCommitted, backendRecord?.violation_type ?? 'Written warning')}</span>
            </div>
          </div>
          <p className={styles.description}>{value(record.description, backendRecord?.description)}</p>

          <div className={styles.issuedGrid}>
            <div>
              <span className={styles.issuedLabel}>Issued By</span>
              <p className={styles.issuedValue}>{enforcerName}</p>
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
        </>
      )}

      <div className={styles.footer}>
        <Button variant="secondary" onClick={onClose}>Close</Button>
      </div>
    </Modal>
  );
}
