import styles from "./SectionsWithoutRecommendation.module.css";

interface SectionsWithoutRecommendationProps {
  sectionNames: string[];
}

export default function SectionsWithoutRecommendation({
  sectionNames,
}: SectionsWithoutRecommendationProps) {
  if (sectionNames.length === 0) return null;

  return (
    <p className={styles.line}>
      {`No recommendation for: ${sectionNames.join(", ")}.`}
    </p>
  );
}
