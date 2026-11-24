import PageHeader from "@/components/ui/PageHeader";
import { RecordsState } from "@/components/ui/Records";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import DismissConfirm from "../components/DismissConfirm";
import RecommendationCard from "../components/RecommendationCard";
import RunSummary from "../components/RunSummary";
import SectionList from "../components/SectionList";
import SectionsWithoutRecommendation from "../components/SectionsWithoutRecommendation";
import { useRecommendationReview } from "../hooks/useRecommendationReview";
import { useRecommendationsPage } from "../hooks/useRecommendationsPage";
import styles from "./RecommendationsPage.module.css";

export default function RecommendationsPage() {
  const {
    data,
    sections,
    selected,
    detailRef,
    openSection,
    keepOpen,
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
          className={styles.layout}
          role="status"
          aria-label="Loading recommended actions"
        >
          <SkeletonBlock height="220px" radius="16px" />
          <SkeletonBlock height="420px" radius="16px" />
        </div>
      ) : isError ? (
        <div className={styles.statePanel}>
          <RecordsState
            title="Unable to load recommended actions"
            message={errorMessage}
            onRetry={retry}
          />
        </div>
      ) : !data?.run ? (
        <div className={styles.statePanel}>
          <RecordsState
            title="No recommendations yet"
            message="They appear after the model's first daily run."
          />
        </div>
      ) : (
        <>
          <RunSummary run={data.run} />
          {decision.errorMessage && (
            <p className={styles.saveError} role="alert">
              {decision.errorMessage}
            </p>
          )}
          {selected ? (
            <div className={styles.layout}>
              <SectionList
                sections={sections}
                selectedId={selected.id}
                onSelect={openSection}
              />
              <div ref={detailRef} className={styles.detail}>
                <RecommendationCard
                  recommendation={selected}
                  isSaving={decision.savingId === selected.id}
                  onReview={(id) => {
                    keepOpen(id);
                    decision.review(id);
                  }}
                  onDismiss={(recommendation) => {
                    keepOpen(recommendation.id);
                    decision.askToDismiss(recommendation);
                  }}
                />
              </div>
            </div>
          ) : (
            <div className={styles.statePanel}>
              <RecordsState
                title="No recommendations"
                message="No street has a recommendation for this period."
              />
            </div>
          )}
          <SectionsWithoutRecommendation
            sectionNames={data.sectionsWithoutRecommendation}
          />
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
