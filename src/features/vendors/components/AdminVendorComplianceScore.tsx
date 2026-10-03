import type { CSSProperties } from "react";
import Card from "@/components/ui/Card";
import { formatDate } from "@/utils/formatters";
import type { AdminVendorComplianceScore as ComplianceScore } from "@/api/types/admin-vendor.types";
import { useCountUp } from "../hooks/useCountUp";
import styles from "./AdminVendorComplianceScore.module.css";

interface AdminVendorComplianceScoreProps {
  score: ComplianceScore;
}

function scoreTone(score: number): string {
  if (score >= 85) return styles.highScore;
  if (score >= 70) return styles.goodScore;
  if (score >= 50) return styles.mediumScore;
  return styles.lowScore;
}

function levelTone(level: string): string {
  const normalized = level.toLowerCase();
  if (normalized.includes("low") || normalized.includes("good")) {
    return styles.levelLow;
  }
  if (normalized.includes("moderate") || normalized.includes("medium")) {
    return styles.levelModerate;
  }
  return styles.levelHigh;
}

export default function AdminVendorComplianceScore({
  score,
}: AdminVendorComplianceScoreProps) {
  const value = Math.min(100, Math.max(0, score.complianceScore));
  const animatedScore = useCountUp(value);
  const animatedDays = useCountUp(score.daysSinceLastTicket ?? 0);
  const animatedPaymentHistory = useCountUp(score.penaltyPaymentHistory);

  return (
    <Card className={`${styles.scoreCard} motion-enter`}>
      <h2 className={styles.cardTitle}>COMPLIANCE SCORE</h2>
      <div className={styles.scoreContent}>
        <div
          className={`${styles.scoreRing} ${scoreTone(score.complianceScore)}`}
          role="progressbar"
          aria-label="Vendor compliance score"
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={animatedScore}
          style={{ "--vendor-score-target": `${value * 3.6}deg` } as CSSProperties}
        >
          <div className={styles.scoreInner}>
            <strong>{animatedScore}</strong>
            <span>/100</span>
          </div>
        </div>

        <div className={styles.metrics}>
          <div>
            <span>Violation Frequency</span>
            <strong className={levelTone(score.violationFrequencyLevel)}>
              {score.violationFrequencyLevel}
            </strong>
          </div>
          <div>
            <span>Recency</span>
            <strong className={styles.metricGood}>
              {score.daysSinceLastTicket == null
                ? "No record"
                : `${animatedDays} day${animatedDays === 1 ? "" : "s"}`}
            </strong>
          </div>
          <div>
            <span>Category Severity</span>
            <strong className={levelTone(score.categorySeverityLevel)}>
              {score.categorySeverityLevel}
            </strong>
          </div>
          <div>
            <span>Penalty Payment History</span>
            <strong className={styles.metricGood}>
              {`${animatedPaymentHistory}%`}
            </strong>
          </div>
        </div>
      </div>

      <div className={styles.scoreFooter}>
        <strong className={levelTone(score.standing)}>{score.standing}</strong>
        <span>Last updated {formatDate(score.calculatedAt)}</span>
      </div>
    </Card>
  );
}
