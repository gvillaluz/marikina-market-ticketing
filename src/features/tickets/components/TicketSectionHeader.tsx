import { Icon, LucideIcon } from "lucide-react";
import styles from './TicketSectionHeader.module.css';

type SectionHeaderProps = {
    title: string;
    icon: LucideIcon
}

function TicketSectionHeader({ title, icon: Icon }: SectionHeaderProps) {
    return (
        <div className={styles.header}>
            <Icon className={styles.headerIcon} size={13} strokeWidth={3} />
            <span className={styles.title}>{title}</span>
        </div>
    );
}

export default TicketSectionHeader;