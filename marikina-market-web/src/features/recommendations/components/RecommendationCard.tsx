import type { SectionRecommendation } from "@/api/types/recommendations.types";
import { riskTone } from "../recommendations.format";
import {
  prominentViolationText,
  recommendedActionText,
} from "../recommendations.text";
import HourlyBars from "./HourlyBars";
import RecommendationTiles from "./RecommendationTiles";
import ReviewActions from "./ReviewActions";
import ReviewNote from "./ReviewNote";
import RiskBadge from "./RiskBadge";
import styles from "./RecommendationCard.module.css";

interface RecommendationCardProps {
  recommendation: SectionRecommendation;
  isSaving: boolean;
  onReview: (id: number) => void;
  onDismiss: (recommendation: SectionRecommendation) => void;
}

export default function RecommendationCard({
  recommendation,
  isSaving,
  onReview,
  onDismiss,
}: RecommendationCardProps) {
  return (
    <article className={styles.card}>
      <header className={styles.header}>
        <h2 className={styles.title}>{recommendation.marketSectionName}</h2>
        <RiskBadge riskLevel={recommendation.riskLevel} />
      </header>

      <RecommendationTiles recommendation={recommendation} />

      <div className={styles.essays}>
        <section className={styles.part}>
          <h3 className={styles.label}>Prominent violation</h3>
          <p className={styles.text}>
            <strong>
              {`${recommendation.categoryNameFilipino} (${recommendation.categoryNameEnglish})`}
            </strong>{" "}
            {prominentViolationText(recommendation)}
          </p>
        </section>

        <section className={`${styles.part} ${styles.action}`}>
          <h3 className={styles.label}>Recommended action</h3>
          <p className={styles.text}>{recommendedActionText(recommendation)}</p>
        </section>
      </div>

      <section className={styles.part}>
        <h3 className={styles.label}>Records by hour</h3>
        <HourlyBars
          hourlyCounts={recommendation.hourlyCounts}
          peakStartHour={recommendation.peakStartHour}
          tone={riskTone(recommendation.riskLevel)}
        />
      </section>

      <div className={styles.review}>
        <ReviewNote review={recommendation.review} />
        <ReviewActions
          review={recommendation.review}
          isSaving={isSaving}
          onReview={() => onReview(recommendation.id)}
          onDismiss={() => onDismiss(recommendation)}
        />
      </div>
    </article>
  );
}
