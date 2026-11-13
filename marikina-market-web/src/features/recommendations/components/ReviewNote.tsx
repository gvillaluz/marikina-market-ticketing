import type { RecommendationReview } from "@/api/types/recommendations.types";
import { formatManilaDateTime } from "../recommendations.format";
import styles from "./ReviewNote.module.css";

interface ReviewNoteProps {
  review: RecommendationReview | null;
}

export default function ReviewNote({ review }: ReviewNoteProps) {
  if (!review) return null;

  return (
    <p className={styles.note}>
      {`${review.decision} by ${review.reviewedByName} on `}
      <span className={styles.date}>
        {formatManilaDateTime(review.reviewedAt)}
      </span>
    </p>
  );
}
