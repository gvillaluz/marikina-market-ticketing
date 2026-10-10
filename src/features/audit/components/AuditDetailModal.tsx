import Modal from "@/components/ui/Modal/Modal";
import Button from "@/components/ui/Button/Button";
import type { AuditLogsModel } from "../hooks/useAuditLogs";
import AuditDetailContent from "./AuditDetailContent";
import AuditRequestMessage from "./AuditRequestMessage";
import styles from "./AuditDetailModal.module.css";

export default function AuditDetailModal({
  model,
}: {
  model: AuditLogsModel["detail"];
}) {
  if (model.selectedId === null) return null;
  return (
    <Modal
      open
      title="Audit log details"
      subtitle={`Audit record #${model.selectedId}`}
      onClose={model.close}
      size="md"
      className={styles.modal}
      headerClassName={styles.header}
      footerClassName={styles.footer}
      footer={
        <Button
          type="button"
          variant="outline"
          size="sm"
          className={styles.close}
          onClick={model.close}
        >
          Close
        </Button>
      }
    >
      {model.isLoading ? (
        <AuditRequestMessage message="Loading audit details…" />
      ) : model.error ? (
        <AuditRequestMessage
          message={model.error}
          error
          onRetry={model.retry}
          busy={model.isFetching}
        />
      ) : model.record ? (
        <AuditDetailContent record={model.record} />
      ) : (
        <AuditRequestMessage message="No audit details are available." />
      )}
    </Modal>
  );
}
