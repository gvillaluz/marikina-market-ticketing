import { Download } from "lucide-react";
import styles from "./PrintConfigModal.module.css";
import { Modal } from "../../../components/ui/Modal";
import { Button } from "../../../components/ui/Button";
import {
  usePrintConfigForm,
  type ExportFormField,
  type PrintConfigOptions,
} from "../hooks/usePrintConfigForm";

interface PrintConfigModalProps<T> {
  isOpen: boolean;
  onClose: () => void;
  options: PrintConfigOptions<T>;
  title?: string;
}

const ERROR_IDS: Record<ExportFormField, string> = {
  types: "export-types-error",
  columns: "export-columns-error",
  dates: "export-dates-error",
};

export function PrintConfigModal<T extends { issuedAt: string | Date }>({
  isOpen,
  onClose,
  options,
  title = "Export Inspection Records",
}: PrintConfigModalProps<T>) {
  const {
    recordTypes,
    columns,
    fields,
    setFields,
    toggleType,
    toggleColumn,
    handleGenerate,
    isPending,
    fieldError,
    notice,
  } = usePrintConfigForm(options);

  const errorFor = (field: ExportFormField) =>
    fieldError?.field === field ? (
      <p id={ERROR_IDS[field]} className={styles.fieldError} role="alert">
        {fieldError.message}
      </p>
    ) : null;
  const describedBy = (field: ExportFormField) =>
    fieldError?.field === field ? ERROR_IDS[field] : undefined;

  return (
    <Modal open={isOpen} title={title} onClose={onClose} size="md">
      <div className={styles.modalContent}>
        <p className={styles.description}>
          Choose the records and columns to include. The spreadsheet file
          follows only these choices, not the page's search or filters.
        </p>

        {notice && (
          <p
            className={
              notice.kind === "error" ? styles.errorText : styles.emptyText
            }
            role={notice.kind === "error" ? "alert" : "status"}
          >
            {notice.message}
          </p>
        )}

        {recordTypes && (
          <fieldset
            className={styles.section}
            aria-describedby={describedBy("types")}
          >
            <legend className={styles.sectionTitle}>Record type</legend>
            <div className={`${styles.checkGrid} ${styles.typePanel}`}>
              {recordTypes.map((value) => (
                <label className={styles.checkItem} key={value}>
                  <input
                    type="checkbox"
                    checked={fields.types.includes(value)}
                    onChange={() => toggleType(value)}
                  />
                  {value}
                </label>
              ))}
            </div>
            {errorFor("types")}
          </fieldset>
        )}

        <fieldset
          className={styles.section}
          aria-describedby={describedBy("columns")}
        >
          <legend className={styles.sectionTitle}>Columns to include</legend>
          <div className={`${styles.checkGrid} ${styles.columnsPanel}`}>
            {columns.map((column) => (
              <label className={styles.checkItem} key={column.key}>
                <input
                  type="checkbox"
                  checked={fields.columnKeys.includes(column.key)}
                  onChange={() => toggleColumn(column.key)}
                />
                {column.header}
              </label>
            ))}
          </div>
          {errorFor("columns")}
        </fieldset>

        <fieldset className={styles.section}>
          <legend className={styles.sectionTitle}>Date issued (optional)</legend>
          <div className={styles.dateGrid}>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="export-start-date">
                Start date
              </label>
              <input
                id="export-start-date"
                type="date"
                className={styles.input}
                value={fields.startDate}
                aria-describedby={describedBy("dates")}
                onChange={(event) =>
                  setFields.setStartDate(event.target.value)
                }
              />
            </div>
            <div className={styles.field}>
              <label className={styles.label} htmlFor="export-end-date">
                End date
              </label>
              <input
                id="export-end-date"
                type="date"
                className={styles.input}
                value={fields.endDate}
                aria-describedby={describedBy("dates")}
                onChange={(event) => setFields.setEndDate(event.target.value)}
              />
            </div>
          </div>
          {errorFor("dates")}
        </fieldset>

        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose} disabled={isPending}>
            Cancel
          </Button>
          <Button
            className={styles.exportDataButton}
            icon={<Download size={15} strokeWidth={1.8} />}
            onClick={() => void handleGenerate()}
            loading={isPending}
          >
            Download spreadsheet
          </Button>
        </div>
      </div>
    </Modal>
  );
}
