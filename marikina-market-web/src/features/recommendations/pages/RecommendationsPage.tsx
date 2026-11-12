import { AlertTriangle } from "lucide-react";
import Button from "@/components/ui/Button";
import PageHeader from "@/components/ui/PageHeader";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import RecommendationCard from "../components/RecommendationCard";
import RunSummary from "../components/RunSummary";
import SectionsWithoutRecommendation from "../components/SectionsWithoutRecommendation";
import { useRecommendationsPage } from "../hooks/useRecommendationsPage";
import styles from "./RecommendationsPage.module.css";

export default function RecommendationsPage() {
  const { data, isLoading, isError, errorMessage, retry } =
    useRecommendationsPage();

  return (
    <div className={styles.page}>
      <PageHeader title="Recommended Actions" />

      {isLoading ? (
        <div
          className={styles.cards}
          role="status"
          aria-label="Loading recommended actions"
        >
          <SkeletonBlock height="220px" radius="6px" />
          <SkeletonBlock height="220px" radius="6px" />
        </div>
      ) : isError ? (
        <div className={styles.error} role="alert">
          <AlertTriangle size={24} aria-hidden="true" />
          <p>{errorMessage}</p>
          <Button variant="primary" onClick={retry}>
            Try again
          </Button>
        </div>
      ) : !data?.run ? (
        <p className={styles.message}>
          No recommendations yet. They appear after the model's first daily
          run.
        </p>
      ) : (
        <>
          <RunSummary run={data.run} />
          {data.recommendations.length === 0 ? (
            <p className={styles.message}>
              No section has a recommendation for this period.
            </p>
          ) : (
            <div className={styles.cards}>
              {data.recommendations.map((recommendation) => (
                <RecommendationCard
                  key={recommendation.marketSectionId}
                  recommendation={recommendation}
                />
              ))}
            </div>
          )}
          <SectionsWithoutRecommendation
            sectionNames={data.sectionsWithoutRecommendation}
          />
        </>
      )}
    </div>
  );
}
