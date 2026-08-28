import { AlertCircle } from 'lucide-react';
import TicketSectionHeader from './TicketSectionHeader';
import TicketInfoRow from './TicketInfoRow';
import styles from './TicketPenaltyDetailsSection.module.css';
import { TicketDetail } from '@/api/types/ticket.types';
import { formatCurrency, formatDateTime } from '@/utils/formatters';

function TicketPenaltyDetailsSection({ detail }: { detail?: TicketDetail }) {
    return <>
        <TicketSectionHeader title={"PENALTY DETAILS"} icon={AlertCircle} />
        <section className={styles.penaltySection}>
            <TicketInfoRow
                label="SEVERITY:"
                value={<span className={styles.severityBadge}>{detail?.severity}</span>}
            />
            <TicketInfoRow label="PENALTY TYPE:" value="Cash Fee" />
            <TicketInfoRow label="DUE DATE:" value={formatDateTime(detail?.dueDate || '')} />

            <div className={styles.fineBox}>
                <div className={styles.fineHeader}>
                    <span className={styles.fineLabel}>Total Fine Due:</span>
                    <span className={styles.fineValue}>{formatCurrency(detail?.totalFineAmount || 0)}</span>
                </div>
                <p className={styles.fineNote}>
                    Please settle the fine on or before the due date to avoid additional penalties.
                </p>
            </div>
        </section>
    </>
}

export default TicketPenaltyDetailsSection;