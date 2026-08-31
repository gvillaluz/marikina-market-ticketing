import { FileWarning } from 'lucide-react';
import TicketSectionHeader from './TicketSectionHeader';
import TicketDetailRow from '../TicketDetailRow';
import OrdinanceCard from './OrdinanceCard';
import styles from './TicketViolationDetailsSection.module.css';
import TicketInfoRow from './TicketInfoRow';
import { TicketDetail } from '@/api/types/ticket.types';
import { formatCurrency, formatDateTime, formatOrdinal } from '@/utils/formatters';

function TicketViolationDetailsSection({ detail }: { detail?: TicketDetail }) {
    return <>
        <TicketSectionHeader title={"VIOLATION DETAILS"} icon={FileWarning} />
        <section className={styles.detailsSection}>
            <div className={styles.ordinanceList}>
                {detail?.violations.map((violation, i) => (
                    <OrdinanceCard
                        key={i}
                        title={violation.ordinanceNo}
                        subtitle={violation.ordinanceCode}
                        offense={formatOrdinal(violation.offenseCount)}
                        price={formatCurrency(violation.penaltyAmount || 0)}
                    />
                ))}
            </div>

            <TicketInfoRow label="DATE & TIME" value={`${formatDateTime(detail?.issuedAt || '')}`} />
            <TicketInfoRow label="LOCATION" value={detail?.marketSectionName} />
            <TicketInfoRow label="VIOLATION COMMITTED" value={detail?.categories} />

            <div className={styles.descriptionBlock}>
                <span className={styles.descriptionLabel}>DESCRIPTION</span>
                <div className={styles.descriptionBox}>
                    {detail?.description}
                </div>
            </div>
        </section>
    </>
}

export default TicketViolationDetailsSection;