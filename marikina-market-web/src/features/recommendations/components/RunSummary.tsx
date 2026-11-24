import { Link } from "react-router-dom";
import type { RecommendationRun } from "@/api/types/recommendations.types";
import { ROUTES } from "@/routes/routePaths";
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
      <div className={`${styles.item} ${styles.detected}`}>
        <dt>Detected violations:</dt> <dd>{run.detectedRecordCount}</dd>
        <dd>
          <Link className={styles.viewList} to={ROUTES.detectedViolations}>
            View list
          </Link>
        </dd>
      </div>
    </dl>
  );
}
