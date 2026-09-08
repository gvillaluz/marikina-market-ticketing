import { User } from 'lucide-react';
import TicketInfoRow from './TicketInfoRow';
import TicketSectionHeader from './TicketSectionHeader';
import styles from './TicketViolatorInfoSection.module.css';
import { TicketDetail } from '@/api/types/ticket.types';

function TicketViolationInfoSection({ detail }: { detail?: TicketDetail }) {
    return <>
        <TicketSectionHeader title={"VIOLATOR DETAILS"} icon={User} />
        <section className={styles.infoSection}>
            <TicketInfoRow label='STALL/UNIT NO:' value={detail?.stallNumber} />
            <TicketInfoRow label='TRADE NAME:' value={detail?.businessName} />
            <TicketInfoRow label='NAME:' value={`${detail?.lastName}, ${detail?.firstName}`} />
            <TicketInfoRow label='ADDRESS:' value={detail?.address} />   
        </section>
    </>
}

export default TicketViolationInfoSection;