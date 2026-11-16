import type { SectionRecommendation } from "@/api/types/recommendations.types";
import { recordCountText } from "../recommendations.format";
import RiskBadge from "./RiskBadge";
import StatusTag from "./StatusTag";
import styles from "./SectionListItem.module.css";

interface SectionListItemProps {
  recommendation: SectionRecommendation;
  isSelected: boolean;
  onSelect: () => void;
}

export default function SectionListItem({
  recommendation,
  isSelected,
  onSelect,
}: SectionListItemProps) {
  return (
    <button
      type="button"
      className={`${styles.row} ${isSelected ? styles.selected : ""}`}
      aria-current={isSelected ? "true" : undefined}
      onClick={onSelect}
    >
      <span className={styles.name}>{recommendation.marketSectionName}</span>
      <span className={styles.meta}>
        {`${recommendation.categoryRecordCount} of ${recordCountText(recommendation.sectionRecordCount)}`}
      </span>
      <span className={styles.labels}>
        <RiskBadge riskLevel={recommendation.riskLevel} />
        <StatusTag review={recommendation.review} />
      </span>
    </button>
  );
}
