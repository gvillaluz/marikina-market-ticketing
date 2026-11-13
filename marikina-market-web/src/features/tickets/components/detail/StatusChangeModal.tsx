import { FC } from "react";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button/Button";
import { RecordStatus } from "@/api/types/common.types";
import { formatControlNumberLabel } from "@/utils/formatters";
import StatusOptionCard from "./StatusOptionCard";
import styles from "./StatusChangeModal.module.css";

const STATUS_OPTIONS: { value: RecordStatus; title: string; description: string }[] = [
  { value: "Pending", title: "Pending", description: "Ticket remains open and pending." },
  { value: "Paid", title: "Paid", description: "Fine has been fully settled." },
  { value: "Contested", title: "Contested", description: "Vendor disputed the ticket, under review." },
  { value: "Waived", title: "Waived", description: "Fine dismissed, no payment required." },
  { value: "Cleared", title: "Cleared", description: "Resolved via community service or blood donation." },
  { value: "Overdue", title: "Overdue", description: "The settlement due date has passed." },
  { value: "InProgress", title: "In Progress", description: "Settlement is in progress." },
];

const statusTitle = (status: RecordStatus | undefined) =>
  STATUS_OPTIONS.find((option) => option.value === status)?.title ?? status ?? "";

interface StatusChangeModalProps {
  open: boolean;
  controlNumber: string | null | undefined;
  currentStatus: RecordStatus | undefined;
  selectedStatus: RecordStatus | undefined;
  availableStatuses: RecordStatus[];
  canUpdate: boolean;
  isPending: boolean;
  onSelect: (status: RecordStatus) => void;
  onConfirm: () => void;
  onClose: () => void;
}

const StatusChangeModal: FC<StatusChangeModalProps> = ({
  open,
  controlNumber,
  currentStatus,
  selectedStatus,
  availableStatuses,
  canUpdate,
  isPending,
  onSelect,
  onConfirm,
  onClose,
}) => (
  <Modal
    open={open}
    onClose={onClose}
    closeDisabled={isPending}
    title="Change status"
    subtitle={`Ticket ${formatControlNumberLabel(controlNumber)}`}
    size="sm"
    footer={
      <>
        <Button type="button" variant="outline" onClick={onClose} disabled={isPending}>
          Cancel
        </Button>
        <Button type="button" variant="primary" loading={isPending} disabled={!canUpdate} onClick={onConfirm}>
          Confirm
        </Button>
      </>
    }
  >
    <div className={styles.content}>
      <div className={styles.options}>
        {STATUS_OPTIONS.filter((option) => availableStatuses.includes(option.value)).map((option) => (
          <StatusOptionCard
            key={option.value}
            title={option.title}
            description={option.description}
            selected={selectedStatus === option.value}
            onClick={() => onSelect(option.value)}
          />
        ))}
      </div>
      <p className={styles.summary}>
        {canUpdate
          ? `${statusTitle(currentStatus)} → ${statusTitle(selectedStatus)}. This will be recorded in the audit log.`
          : "Select a new status."}
      </p>
    </div>
  </Modal>
);

export default StatusChangeModal;
