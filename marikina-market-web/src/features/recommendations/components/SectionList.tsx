import type { SectionRecommendation } from "@/api/types/recommendations.types";
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
    <section className={styles.list} aria-labelledby="recommendation-sections">
      <header className={styles.header}>
        <h2 id="recommendation-sections" className={styles.heading}>
          Sections
        </h2>
        <p className={styles.summary}>{statusSummary(sections)}</p>
      </header>
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
    </section>
  );
}
