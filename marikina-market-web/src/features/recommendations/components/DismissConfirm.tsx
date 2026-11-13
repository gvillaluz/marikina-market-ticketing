import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import type { SectionRecommendation } from "@/api/types/recommendations.types";
import styles from "./DismissConfirm.module.css";

interface DismissConfirmProps {
  recommendation: SectionRecommendation | null;
  isSaving: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function DismissConfirm({
  recommendation,
  isSaving,
  onConfirm,
  onCancel,
}: DismissConfirmProps) {
  if (!recommendation) return null;

  return (
    <Modal
      open
      size="sm"
      title="Dismiss recommendation"
      onClose={onCancel}
      closeDisabled={isSaving}
      footer={
        <>
          <Button variant="outline" disabled={isSaving} onClick={onCancel}>
            Cancel
          </Button>
          <Button variant="danger" disabled={isSaving} onClick={onConfirm}>
            {isSaving ? "Dismissing…" : "Dismiss"}
          </Button>
        </>
      }
    >
      <p className={styles.body}>
        Are you sure you want to dismiss the recommendation for{" "}
        <strong>{recommendation.marketSectionName}</strong>:{" "}
        <strong>
          {`${recommendation.categoryNameFilipino} (${recommendation.categoryNameEnglish})`}
        </strong>
        ? This cannot be undone.
      </p>
    </Modal>
  );
}
