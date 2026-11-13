import { AlertTriangle } from "lucide-react";
import Button from "@/components/ui/Button";
import PageHeader from "@/components/ui/PageHeader";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import DismissConfirm from "../components/DismissConfirm";
import RecommendationCard from "../components/RecommendationCard";
import RunSummary from "../components/RunSummary";
import SectionsWithoutRecommendation from "../components/SectionsWithoutRecommendation";
import { useRecommendationReview } from "../hooks/useRecommendationReview";
import { useRecommendationsPage } from "../hooks/useRecommendationsPage";
import styles from "./RecommendationsPage.module.css";

export default function RecommendationsPage() {
  const {
    data,
    openCards,
    dismissedCards,
    isLoading,
    isError,
    errorMessage,
    retry,
  } = useRecommendationsPage();
  const decision = useRecommendationReview();

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
          {decision.errorMessage && (
            <p className={styles.saveError} role="alert">
              {decision.errorMessage}
            </p>
          )}
          {data.recommendations.length === 0 ? (
            <p className={styles.message}>
              No section has a recommendation for this period.
            </p>
          ) : openCards.length === 0 ? (
            <p className={styles.message}>
              Every recommendation has been dismissed.
            </p>
          ) : (
            <div className={styles.cards}>
              {openCards.map((recommendation) => (
                <RecommendationCard
                  key={recommendation.id}
                  recommendation={recommendation}
                  isSaving={decision.savingId === recommendation.id}
                  onReview={decision.review}
                  onDismiss={decision.askToDismiss}
                />
              ))}
            </div>
          )}
          <SectionsWithoutRecommendation
            sectionNames={data.sectionsWithoutRecommendation}
          />
          {dismissedCards.length > 0 && (
            <section className={styles.dismissed}>
              <h2 className={styles.heading}>Dismissed</h2>
              <div className={styles.cards}>
                {dismissedCards.map((recommendation) => (
                  <RecommendationCard
                    key={recommendation.id}
                    recommendation={recommendation}
                    isSaving={decision.savingId === recommendation.id}
                    onReview={decision.review}
                    onDismiss={decision.askToDismiss}
                  />
                ))}
              </div>
            </section>
          )}
        </>
      )}

      <DismissConfirm
        recommendation={decision.dismissTarget}
        isSaving={
          decision.dismissTarget !== null &&
          decision.savingId === decision.dismissTarget.id
        }
        onConfirm={decision.confirmDismiss}
        onCancel={decision.cancelDismiss}
      />
    </div>
  );
}
