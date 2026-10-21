import { FileImage, FileText, Printer, ChevronRight } from 'lucide-react';
import styles from './TicketExportPanel.module.css';

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
  disabled: boolean;
  busyAction: ExportOption["id"] | null;
  error: string | null;
}

function TicketExportPanel({
  onExportPNG,
  onExportPDF,
  onPrint,
  disabled,
  busyAction,
  error,
}: TicketExportPanelProps) {
    const handleAction = (id: 'png' | 'pdf' | 'print') => {
        if (id === 'png') onExportPNG();
        if (id === 'pdf') onExportPDF();
        if (id === 'print') onPrint();
    };

    return (
        <aside className={styles.panel} aria-label="Ticket export actions">
            <h5 className={styles.title}>Export Ticket</h5>
            <p className={styles.subtitle}>Save a copy of this record or send it to your printer.</p>

            {error && <p className={styles.error} role="alert">{error}</p>}

            <div className={styles.optionList}>
                {EXPORT_OPTIONS.map((option) => {
                    const isBusy = busyAction === option.id;
                    return (
                    <button
                        key={option.title}
                        type="button"
                        className={styles.optionCard}
                        onClick={() => handleAction(option.id)}
                        disabled={disabled || busyAction !== null}
                        aria-busy={isBusy}
                    >
                        {isBusy
                          ? <span className={styles.spinner} aria-hidden="true" />
                          : <option.icon className={styles.optionIcon} size={18} strokeWidth={2} />}
                        <div className={styles.optionText}>
                            <span className={styles.optionTitle}>{isBusy ? "Preparing..." : option.title}</span>
                            <span className={styles.optionSubtitle}>{option.subtitle}</span>
                        </div>
                        <ChevronRight className={styles.chevron} size={16} />
                    </button>
                    );
                })}
            </div>
        </aside>
    );
}

export default TicketExportPanel;