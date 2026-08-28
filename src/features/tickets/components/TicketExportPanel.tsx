import { FileImage, FileText, Printer, ChevronRight } from 'lucide-react';
import styles from './TicketExportPanel.module.css';

type ExportOption = {
    icon: typeof FileImage;
    title: string;
    subtitle: string;
    active?: boolean;
}

const EXPORT_OPTIONS: ExportOption[] = [
    {
        icon: FileImage,
        title: 'Export as PNG',
        subtitle: 'Save this image as PNG image file.',
        active: true,
    },
    {
        icon: FileText,
        title: 'Export as PDF',
        subtitle: 'Save this image as PDF document.',
    },
    {
        icon: Printer,
        title: 'Print',
        subtitle: 'Print this ticket directly.',
    },
];

function TicketExportPanel() {
    return (
        <div className={styles.panel}>
            <h5 className={styles.title}>Export Ticket</h5>
            <p className={styles.subtitle}>Choose an option to save or share this ticket.</p>

            <div className={styles.optionList}>
                {EXPORT_OPTIONS.map((option) => (
                    <button
                        key={option.title}
                        type="button"
                        className={`${styles.optionCard} ${option.active ? styles.optionCardActive : ''}`}
                    >
                        <option.icon className={styles.optionIcon} size={18} strokeWidth={2} />
                        <div className={styles.optionText}>
                            <span className={styles.optionTitle}>{option.title}</span>
                            <span className={styles.optionSubtitle}>{option.subtitle}</span>
                        </div>
                        <ChevronRight className={styles.chevron} size={16} />
                    </button>
                ))}
            </div>
        </div>
    );
}

export default TicketExportPanel;