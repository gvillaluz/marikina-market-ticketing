import { Download } from "lucide-react";
import styles from "./PrintConfigModal.module.css";
import { Modal } from "../../../components/ui/Modal";
import { Button } from "../../../components/ui/Button";
import { PRINT_COLUMN_OPTIONS } from "../../../utils/constants";
import type { PrintConfigPayload } from "../../../api/types/ticket.types";
import type { PrintConfigFormState } from "../hooks/usePrintConfigForm";
import { getApiErrorMessage } from "@/utils/apiErrors";

interface PrintConfigModalProps {
  isOpen: boolean;
  onClose: () => void;
  form: PrintConfigFormState;
  title?: string;
}

const RECORD_TYPES: PrintConfigPayload["types"] = ["warning", "ticket"];
const COLUMN_ORDER: PrintConfigPayload["columns"] = [
  "controlNumber",
  "type",
  "issuedAt",
  "vendor",
  "status",
  "section",
  "severity",
];

export function PrintConfigModal({
  isOpen,
  onClose,
  form,
  title = "Export Inspection Records",
}: PrintConfigModalProps) {
  const {
    fields,
    setFields,
    toggleType,
    toggleColumn,
    handleGenerate,
    isPending,
    isError,
    error,
    validationError,
  } = form;

  return (
    <Modal open={isOpen} title={title} onClose={onClose} size="md">
      <div className={styles.modalContent}>
        <p className={styles.description}>
          Choose the records and fields to include. The export file type is
          provided by the export service.
        </p>

        {(validationError || isError) && (
          <p className={styles.errorText} role="alert">
            {validationError ||
              getApiErrorMessage(error, "Unable to generate the export. Please try again.")}
          </p>
        )}

        <fieldset className={styles.section}>
          <legend className={styles.sectionTitle}>Record type</legend>
          <div className={`${styles.checkGrid} ${styles.typePanel}`}>
            {RECORD_TYPES.map((value) => (
              <label className={styles.checkItem} key={value}>
                <input
                  type="checkbox"
                  checked={fields.types.includes(value)}
                  onChange={() => toggleType(value)}
                />
                {value === "warning" ? "Warning" : "Ticket"}
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset className={styles.section}>
          <legend className={styles.sectionTitle}>Columns to include</legend>
          <div className={`${styles.checkGrid} ${styles.columnsPanel}`}>
            {COLUMN_ORDER.map((value) => {
              const column = PRINT_COLUMN_OPTIONS.find(
                (option) => option.value === value,
              );
              if (!column) return null;
              return (
                <label className={styles.checkItem} key={column.value}>
                  <input
                    type="checkbox"
                    checked={fields.columns.includes(column.value)}
                    onChange={() => toggleColumn(column.value)}
                  />
                  {column.label}
                </label>
              );
            })}
          </div>
        </fieldset>

        <fieldset className={styles.section}>
          <legend className={styles.sectionTitle}>Date range (optional)</legend>
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
                onChange={(event) => setFields.setEndDate(event.target.value)}
              />
            </div>
          </div>
        </fieldset>

        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose} disabled={isPending}>
            Cancel
          </Button>
          <Button
            className={styles.exportDataButton}
            icon={<Download size={15} strokeWidth={1.8} />}
            onClick={handleGenerate}
            loading={isPending}
          >
            Download export
          </Button>
        </div>
      </div>
    </Modal>
  );
}
