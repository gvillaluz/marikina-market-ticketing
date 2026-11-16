import type { SectionRecommendation } from "@/api/types/recommendations.types";
import {
  formatPeakWindow,
  recordCountText,
  recordWord,
  riskTone,
} from "../recommendations.format";
import styles from "./RecommendationTiles.module.css";

interface RecommendationTilesProps {
  recommendation: SectionRecommendation;
}

export default function RecommendationTiles({
  recommendation,
}: RecommendationTilesProps) {
  const { categoryRecordCount, sectionRecordCount } = recommendation;

  return (
    <dl className={`${styles.tiles} ${styles[riskTone(recommendation.riskLevel)]}`}>
      <div className={`${styles.tile} ${styles.found}`}>
        <dt className={styles.label}>Found in</dt>
        <dd className={styles.value}>
          {`${categoryRecordCount} of ${sectionRecordCount}`}
        </dd>
        <dd className={styles.caption}>
          {`${recordWord(sectionRecordCount)}, last 30 days`}
        </dd>
      </div>
      <div className={styles.tile}>
        <dt className={styles.label}>Peak time</dt>
        <dd className={styles.value}>
          {formatPeakWindow(recommendation.peakStartHour)}
        </dd>
        <dd className={styles.caption}>busiest 3 hours</dd>
      </div>
      <div className={styles.tile}>
        <dt className={styles.label}>Confidence</dt>
        <dd className={styles.value}>{recommendation.patternConfidence}</dd>
        <dd className={styles.caption}>
          {`based on ${recordCountText(sectionRecordCount)}`}
        </dd>
      </div>
    </dl>
  );
}
