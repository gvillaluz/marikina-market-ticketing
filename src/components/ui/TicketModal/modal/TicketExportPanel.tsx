import { FileImage, FileText, Printer, ChevronRight } from 'lucide-react';
import styles from './TicketExportPanel.module.css';
import { useState } from 'react';

type ExportOption = {
  id: 'png' | 'pdf' | 'print';
  icon: typeof FileImage;
  title: string;
  subtitle: string;
};

const EXPORT_OPTIONS: ExportOption[] = [
    {
        id: 'png',
        icon: FileImage,
        title: 'Export as PNG',
        subtitle: 'Save this image as PNG image file.',
    },
    {
        id: 'pdf',
        icon: FileText,
        title: 'Export as PDF',
        subtitle: 'Save this image as PDF document.',
    },
    {
        id: 'print',
        icon: Printer,
        title: 'Print',
        subtitle: 'Print this ticket directly.',
    },
];

interface TicketExportPanelProps {
  onExportPNG: () => void;
  onExportPDF: () => void;
  onPrint: () => void;
}

function TicketExportPanel({ onExportPNG, onExportPDF, onPrint }: TicketExportPanelProps) {
    const [active, setActive] = useState<number | null>(null);

    const handleAction = (id: 'png' | 'pdf' | 'print') => {
        if (id === 'png') onExportPNG();
        if (id === 'pdf') onExportPDF();
        if (id === 'print') onPrint();
    };

    return (
        <div className={styles.panel}>
            <h5 className={styles.title}>Export Ticket</h5>
            <p className={styles.subtitle}>Choose an option to save or share this ticket.</p>

            <div className={styles.optionList}>
                {EXPORT_OPTIONS.map((option, i) => (
                    <button
                        key={option.title}
                        type="button"
                        className={`${styles.optionCard} ${active === i ? styles.optionCardActive : ''}`}
                        onClick={() => {
                            setActive(i)
                            handleAction(option.id)
                        }}
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