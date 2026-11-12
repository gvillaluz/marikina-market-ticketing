import type { RecommendationRun } from "@/api/types/recommendations.types";
import {
  formatManilaDate,
  formatManilaDateTime,
} from "../recommendations.format";
import styles from "./RunSummary.module.css";

interface RunSummaryProps {
  run: RecommendationRun;
}

export default function RunSummary({ run }: RunSummaryProps) {
  return (
    <dl className={styles.summary}>
      <div className={styles.item}>
        <dt>Last updated:</dt> <dd>{formatManilaDateTime(run.finishedAt)}</dd>
      </div>
      <div className={styles.item}>
        <dt>Period:</dt>{" "}
        <dd>
          {`${formatManilaDate(run.windowStart)} – ${formatManilaDate(run.windowEnd)}`}
        </dd>
      </div>
      <div className={styles.item}>
        <dt>Records read:</dt> <dd>{run.recordCount}</dd>
      </div>
    </dl>
  );
}
