import { CircleCheck, CircleX, Clock } from "lucide-react";
import type { RecommendationReview } from "@/api/types/recommendations.types";
import { reviewStatus } from "../recommendations.format";
import styles from "./StatusTag.module.css";

interface StatusTagProps {
  review: RecommendationReview | null;
}

const looks = {
  "Needs review": { Icon: Clock, style: styles.needsReview },
  Reviewed: { Icon: CircleCheck, style: styles.reviewed },
  Dismissed: { Icon: CircleX, style: styles.dismissed },
};

export default function StatusTag({ review }: StatusTagProps) {
  const status = reviewStatus(review);
  const { Icon, style } = looks[status];

  return (
    <span className={`${styles.tag} ${style}`}>
      <Icon size={14} aria-hidden="true" />
      {status}
    </span>
  );
}
