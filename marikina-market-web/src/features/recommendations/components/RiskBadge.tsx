import { RecordBadge } from "@/components/ui/Records";

interface RiskBadgeProps {
  riskLevel: string;
}

export default function RiskBadge({ riskLevel }: RiskBadgeProps) {
  return <RecordBadge value={riskLevel} label={`${riskLevel} risk`} />;
}
