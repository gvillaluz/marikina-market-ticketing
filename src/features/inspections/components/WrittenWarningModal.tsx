import styles from './WrittenWarningModal.module.css';
import { Modal } from '../../../components/ui/Modal';
import { Button } from '../../../components/ui/Button';
import Loader from '../../../components/feedback/Loader/Loader';import { formatDateTime, formatDate } from '../../../utils/formatters';
import { useInspectionDetail } from '../hooks/useInspectionDetail';

interface WrittenWarningModalProps {
  isOpen: boolean;
  recordId: string | null;
  onClose: () => void;
}

export function WrittenWarningModal({ isOpen, recordId, onClose }: WrittenWarningModalProps) {
  const { data, isLoading, isError } = useInspectionDetail(recordId, 'warning');
  const record = data && data.type === 'warning' ? data : null;

  return (
    <Modal open={isOpen} title="Written Warning Record" onClose={onClose}>
      {isLoading && <Loader label="Loading warning record…" />}
      {isError && <p className={styles.errorText}>Unable to load this warning record.</p>}

      {record && (
        <>
          <div className={styles.header}>
            <div className={styles.seal} aria-hidden="true">MK</div>
            <p className={styles.city}>City of Marikina</p>
            <p className={styles.office}>Marikina Public Market Office</p>
            <p className={styles.docTitle}>⚠ WRITTEN WARNING</p>
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
          </div>

          <p className={styles.sectionTitle}>Violation Details</p>
          <div className={styles.ordinanceBox}>
            <p className={styles.ordinanceTitle}>
              Ord. No. {record.ordinanceNumber}, Series of {record.ordinanceSeries}
            </p>
            <p className={styles.ordinanceSubtitle}>{record.ordinanceCategory}</p>
          </div>

          <div className={styles.detailGrid}>
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
        </>
      )}

      <div className={styles.footer}>
        <Button variant="secondary" onClick={onClose}>Close</Button>
      </div>
    </Modal>
  );
}
