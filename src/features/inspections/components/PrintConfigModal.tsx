import { useState } from 'react';
import { Download, FileSpreadsheet, FileText } from 'lucide-react';
import styles from './PrintConfigModal.module.css';
import { Modal } from '../../../components/ui/Modal';
import { Button } from '../../../components/ui/Button';
import { PRINT_COLUMN_OPTIONS } from '../../../utils/constants';
import { usePrintExport } from '../hooks/usePrintExport';
import type { PrintConfigPayload } from '../../../api/types/ticket.types';

interface PrintConfigModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const RECORD_TYPES: Array<'warning' | 'ticket'> = ['warning', 'ticket'];
const COLUMN_ORDER: PrintConfigPayload['columns'] = [
  'controlNumber',
  'type',
  'issuedAt',
  'vendor',
  'status',
  'section',
  'severity',
];
const EXPORT_FORMATS = [
  { value: 'csv', label: 'CSV', icon: FileText },
  { value: 'xlsx', label: 'Excel (XLSX)', icon: FileSpreadsheet },
  { value: 'pdf', label: 'PDF', icon: FileText },
] as const;

export function PrintConfigModal({ isOpen, onClose }: PrintConfigModalProps) {
  const [types, setTypes] = useState<Array<'warning' | 'ticket'>>(['warning']);
  const [columns, setColumns] = useState<PrintConfigPayload['columns']>(
    PRINT_COLUMN_OPTIONS.filter((column) => column.value !== 'severity').map((c) => c.value)
  );
  const [format, setFormat] = useState<(typeof EXPORT_FORMATS)[number]['value']>('csv');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const { mutate, isPending, isError } = usePrintExport();

  const toggleType = (value: 'warning' | 'ticket') => {
    setTypes((prev) =>
      prev.includes(value) ? prev.filter((t) => t !== value) : [...prev, value]
    );
  };

  const toggleColumn = (value: PrintConfigPayload['columns'][number]) => {
    setColumns((prev) =>
      prev.includes(value) ? prev.filter((c) => c !== value) : [...prev, value]
    );
  };

  const handleGenerate = () => {
    mutate({ types, columns, startDate, endDate });
  };

  return (
    <Modal open={isOpen} title="Export Configuration" onClose={onClose} size="md">
      {isError && <p className={styles.errorText}>Unable to generate the print view. Please try again.</p>}

      <div className={styles.section}>
        <p className={styles.sectionTitle}>Select Type</p>
        <div className={`${styles.checkGrid} ${styles.typePanel}`}>
          {RECORD_TYPES.map((value) => (
            <label className={styles.checkItem} key={value}>
              <input
                type="checkbox"
                checked={types.includes(value)}
                onChange={() => toggleType(value)}
              />
              {value === 'warning' ? 'Warning' : 'Ticket'}
            </label>
          ))}
        </div>
      </div>

      <div className={styles.section}>
        <p className={styles.sectionTitle}>Select Columns to Print</p>
        <div className={`${styles.checkGrid} ${styles.columnsPanel}`}>
          {COLUMN_ORDER.map((value) => {
            const column = PRINT_COLUMN_OPTIONS.find((option) => option.value === value);
            if (!column) return null;
            return (
            <label className={styles.checkItem} key={column.value}>
              <input
                type="checkbox"
                checked={columns.includes(column.value)}
                onChange={() => toggleColumn(column.value)}
              />
              {column.label}
            </label>
            );
          })}
        </div>
      </div>

      <div className={styles.section}>
        <p className={styles.sectionTitle}>Export Format</p>
        <div className={styles.formatGrid} role="radiogroup" aria-label="Export format">
          {EXPORT_FORMATS.map(({ value, label, icon: Icon }) => (
            <button
              type="button"
              key={value}
              className={`${styles.formatCard} ${format === value ? styles.selectedFormat : ''}`}
              onClick={() => setFormat(value)}
              role="radio"
              aria-checked={format === value}
            >
              <span className={styles.radio} aria-hidden="true" />
              <Icon
                className={value === 'pdf' ? styles.pdfIcon : value === 'xlsx' ? styles.excelIcon : styles.csvIcon}
                size={22}
                strokeWidth={1.8}
              />
              <span>{label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className={styles.section}>
        <p className={styles.sectionTitle}>Date Range Filter</p>
        <div className={styles.dateGrid}>
          <div className={styles.field}>
            <label className={styles.label} htmlFor="startDate">Start Date</label>
            <input
              id="startDate"
              type="date"
              className={styles.input}
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div className={styles.field}>
            <label className={styles.label} htmlFor="endDate">End Date</label>
            <input
              id="endDate"
              type="date"
              className={styles.input}
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className={styles.footer}>
        <Button variant="outline" onClick={onClose}>Cancel</Button>
        <Button
          className={styles.exportDataButton}
          icon={<Download size={15} strokeWidth={1.8} />}
          onClick={handleGenerate}
          loading={isPending}
        >
          Export Data
        </Button>
      </div>
    </Modal>
  );
}
