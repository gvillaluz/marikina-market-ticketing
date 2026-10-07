import { AlertCircle } from 'lucide-react';
import TicketSectionHeader from './TicketSectionHeader';
import TicketInfoRow from './TicketInfoRow';
import styles from './TicketPenaltyDetailsSection.module.css';
import { TicketDetail } from '@/api/types/ticket.types';
import { formatCurrency, formatDateTime } from '@/utils/formatters';
import { getTicketTotalFineAmount } from '@/features/tickets/tickets.utils';

function TicketPenaltyDetailsSection({ detail }: { detail?: TicketDetail }) {
    const severity = (detail?.severity || '').toLowerCase();
    const totalFine = getTicketTotalFineAmount(detail);

    return <>
        <TicketSectionHeader title={"PENALTY DETAILS"} icon={AlertCircle} />
        <section className={styles.penaltySection}>
            <TicketInfoRow
                label="SEVERITY:"
                value={<span className={`${styles.severityBadge} ${styles[severity]}`}>{detail?.severity}</span>}
            />
            <TicketInfoRow label="PENALTY TYPE:" value="Cash Fine" />
            <TicketInfoRow label="DUE DATE:" value={formatDateTime(detail?.dueDate || '')} />

            <div className={styles.fineBox}>
                <div className={styles.fineHeader}>
                    <span className={styles.fineLabel}>Total Fine Due:</span>
                    <span className={styles.fineValue}>{totalFine == null ? "—" : formatCurrency(totalFine)}</span>
                </div>
            </div>
            <p className={styles.fineNote}>
                Please settle the fine on or before the due date to avoid additional penalties.
            </p>
        </section>
    </>
}

export default TicketPenaltyDetailsSection;