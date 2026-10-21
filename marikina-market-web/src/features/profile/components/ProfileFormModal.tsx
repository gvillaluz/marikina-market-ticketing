import type { ReactNode } from "react";
import Modal from "@/components/ui/Modal";
import ProfileModalFooter from "./ProfileModalFooter";
import styles from "./ProfileFormModal.module.css";

interface ProfileFormModalProps {
  title: string;
  icon?: ReactNode;
  description: string;
  formId: string;
  submitLabel: string;
  size: "sm" | "lg";
  isSaving: boolean;
  canSubmit: boolean;
  error: string | null;
  onClose: () => void;
  onSubmit: () => Promise<void>;
  children: ReactNode;
}

export default function ProfileFormModal({
  title,
  icon,
  description,
  formId,
  submitLabel,
  size,
  isSaving,
  canSubmit,
  error,
  onClose,
  onSubmit,
  children,
}: ProfileFormModalProps) {
  return (
    <Modal
      open
      title={
        <span className={styles.heading}>
          {icon && <span className={styles.icon}>{icon}</span>}
          {title}
        </span>
      }
      subtitle={description}
      size={size}
      onClose={onClose}
      closeDisabled={isSaving}
      className={styles.modal}
      headerClassName={styles.header}
      footerClassName={styles.footer}
      footer={
        <ProfileModalFooter
          formId={formId}
          submitLabel={submitLabel}
          isSaving={isSaving}
          canSubmit={canSubmit}
          onClose={onClose}
        />
      }
    >
      <form
        id={formId}
        className={`${styles.form} ${size === "lg" ? styles.profile : ""}`}
        onSubmit={(event) => {
          event.preventDefault();
          void onSubmit();
        }}
        noValidate
        aria-busy={isSaving}
      >
        {children}
        {error && (
          <p className={styles.error} role="alert">
            {error}
          </p>
        )}
      </form>
    </Modal>
  );
}
