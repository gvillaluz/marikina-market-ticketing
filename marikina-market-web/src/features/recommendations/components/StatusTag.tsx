import type { RecommendationReview } from "@/api/types/recommendations.types";
import { RecordBadge } from "@/components/ui/Records";
import { reviewStatus } from "../recommendations.format";

interface StatusTagProps {
  review: RecommendationReview | null;
}

export default function StatusTag({ review }: StatusTagProps) {
  return <RecordBadge value={reviewStatus(review)} />;
}
