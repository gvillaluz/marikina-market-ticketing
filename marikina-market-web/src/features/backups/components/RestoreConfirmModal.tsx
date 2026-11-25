import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import type { BackupRestoreModel } from "../hooks/useBackupRestore";
import RestoreConfirmDetails from "./RestoreConfirmDetails";

interface RestoreConfirmModalProps {
  restore: BackupRestoreModel;
}

export default function RestoreConfirmModal({
  restore,
}: RestoreConfirmModalProps) {
  if (!restore.target) return null;
  return (
    <Modal
      open
      size="sm"
      title="Restore this backup?"
      subtitle={`Backup from ${restore.target.dateLabel} (Philippine Time)`}
      onClose={restore.cancel}
      closeDisabled={restore.isStarting}
      footer={
        <>
          <Button
            variant="outline"
            disabled={restore.isStarting}
            onClick={restore.cancel}
          >
            Cancel
          </Button>
          <Button
            variant="danger"
            disabled={!restore.canStart}
            loading={restore.isStarting}
            onClick={restore.start}
          >
            {restore.isStarting ? "Starting…" : "Restore backup"}
          </Button>
        </>
      }
    >
      <RestoreConfirmDetails
        dateLabel={restore.target.dateLabel}
        confirmation={restore.confirmation}
        password={restore.password}
        passwordVisible={restore.passwordVisible}
        hint={restore.hint}
        error={restore.startError}
        disabled={restore.isStarting}
        onConfirmationChange={restore.setConfirmation}
        onPasswordChange={restore.setPassword}
        onTogglePassword={restore.togglePassword}
      />
    </Modal>
  );
}
