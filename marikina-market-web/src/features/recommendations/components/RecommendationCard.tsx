import type { SectionRecommendation } from "@/api/types/recommendations.types";
import {
  formatManilaDateTime,
  formatPeakWindow,
  recordCountText,
  riskTone,
} from "../recommendations.format";
import HourlyBars from "./HourlyBars";
import ReviewActions from "./ReviewActions";
import ReviewNote from "./ReviewNote";
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
  const tone = riskTone(recommendation.riskLevel);

  return (
    <article className={`${styles.card} ${styles[tone]}`}>
      <header className={styles.header}>
        <h2 className={styles.title}>{recommendation.marketSectionName}</h2>
        <span className={styles.badge}>{recommendation.riskLevel} risk</span>
      </header>

      <section className={styles.part}>
        <h3 className={styles.label}>Prominent violation</h3>
        <p className={styles.text}>
          <strong>
            {`${recommendation.categoryNameFilipino} (${recommendation.categoryNameEnglish})`}
          </strong>
          {` found in ${recommendation.categoryRecordCount} of ${recordCountText(recommendation.sectionRecordCount)} in the last 30 days.`}
        </p>
      </section>

      <section className={styles.part}>
        <h3 className={styles.label}>Recommended action</h3>
        <p className={styles.text}>{recommendation.recommendedAction}</p>
      </section>

      <section className={styles.part}>
        <p className={styles.peak}>
          {`Peak time: ${formatPeakWindow(recommendation.peakStartHour)}`}
        </p>
        <HourlyBars
          hourlyCounts={recommendation.hourlyCounts}
          peakStartHour={recommendation.peakStartHour}
          tone={tone}
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

      <footer className={styles.footer}>
        <span>
          {`Pattern confidence: ${recommendation.patternConfidence} — based on ${recordCountText(recommendation.sectionRecordCount)}`}
        </span>
        <span>
          {`Last flagged: ${formatManilaDateTime(recommendation.lastFlaggedAt)}`}
        </span>
      </footer>
    </article>
  );
}
