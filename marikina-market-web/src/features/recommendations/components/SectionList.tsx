import type { SectionRecommendation } from "@/api/types/recommendations.types";
import { RecordsPanel } from "@/components/ui/Records";
import { statusSummary } from "../recommendations.format";
import SectionListItem from "./SectionListItem";
import styles from "./SectionList.module.css";

interface SectionListProps {
  sections: SectionRecommendation[];
  selectedId: number | null;
  onSelect: (id: number) => void;
}

export default function SectionList({
  sections,
  selectedId,
  onSelect,
}: SectionListProps) {
  return (
    <RecordsPanel
      title="Streets"
      description={statusSummary(sections)}
      countLabel="streets"
    >
      <ul className={styles.rows}>
        {sections.map((recommendation) => (
          <li key={recommendation.id}>
            <SectionListItem
              recommendation={recommendation}
              isSelected={recommendation.id === selectedId}
              onSelect={() => onSelect(recommendation.id)}
            />
          </li>
        ))}
      </ul>
    </RecordsPanel>
  );
}
