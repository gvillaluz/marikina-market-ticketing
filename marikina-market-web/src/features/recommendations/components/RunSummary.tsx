import { useNavigate } from "react-router-dom";
import type { RecommendationRun } from "@/api/types/recommendations.types";
import Button from "@/components/ui/Button";
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
  const navigate = useNavigate();

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
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => navigate(ROUTES.detectedViolations)}
          >
            View list
          </Button>
        </dd>
      </div>
    </dl>
  );
}
