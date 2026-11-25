import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import type { BackupRestoreModel } from "../hooks/useBackupRestore";
import RestoreConfirmDetails from "./RestoreConfirmDetails";
import RestoreFileField from "./RestoreFileField";
import RestoreUploadProgress from "./RestoreUploadProgress";

interface RestoreConfirmModalProps {
  restore: BackupRestoreModel;
}

export default function RestoreConfirmModal({
  restore,
}: RestoreConfirmModalProps) {
  const { target, windowText } = restore;
  if (!target || !windowText) return null;
  return (
    <Modal
      open
      size="sm"
      title={windowText.title}
      subtitle={windowText.source}
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
            {restore.isStarting ? windowText.pending : windowText.confirm}
          </Button>
        </>
      }
    >
      <RestoreConfirmDetails
        dateLabel={target.kind === "backup" ? target.dateLabel : null}
        fileField={
          target.kind === "file" && (
            <RestoreFileField
              id="restore-file"
              error={restore.fileError}
              disabled={restore.isStarting}
              onChange={restore.setFile}
            />
          )
        }
        uploadProgress={
          restore.uploadPercent !== null && (
            <RestoreUploadProgress percent={restore.uploadPercent} />
          )
        }
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
