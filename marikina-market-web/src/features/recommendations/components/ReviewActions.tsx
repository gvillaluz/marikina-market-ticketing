import Button from "@/components/ui/Button";
import type { RecommendationReview } from "@/api/types/recommendations.types";
import styles from "./ReviewActions.module.css";

interface ReviewActionsProps {
  review: RecommendationReview | null;
  isSaving: boolean;
  onReview: () => void;
  onDismiss: () => void;
}

export default function ReviewActions({
  review,
  isSaving,
  onReview,
  onDismiss,
}: ReviewActionsProps) {
  if (review?.decision === "Dismissed") return null;

  return (
    <div className={styles.actions}>
      {!review && (
        <Button
          variant="primary"
          size="sm"
          disabled={isSaving}
          onClick={onReview}
        >
          Mark as reviewed
        </Button>
      )}
      <Button
        variant="outline"
        size="sm"
        disabled={isSaving}
        onClick={onDismiss}
      >
        Dismiss
      </Button>
    </div>
  );
}
