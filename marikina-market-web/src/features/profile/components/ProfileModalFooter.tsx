import { Check } from "lucide-react";
import Button from "@/components/ui/Button/Button";
import styles from "./ProfileModalFooter.module.css";

interface ProfileModalFooterProps {
  formId: string;
  submitLabel: string;
  isSaving: boolean;
  canSubmit: boolean;
  onClose: () => void;
}

export default function ProfileModalFooter({
  formId,
  submitLabel,
  isSaving,
  canSubmit,
  onClose,
}: ProfileModalFooterProps) {
  return (
    <div className={styles.actions}>
      <Button
        type="button"
        variant="outline"
        className={`${styles.button} ${styles.cancel}`}
        disabled={isSaving}
        onClick={onClose}
      >
        Cancel
      </Button>
      <Button
        type="submit"
        form={formId}
        className={styles.button}
        icon={<Check size={16} aria-hidden="true" />}
        loading={isSaving}
        disabled={!canSubmit}
      >
        {isSaving ? "Saving…" : submitLabel}
      </Button>
    </div>
  );
}
