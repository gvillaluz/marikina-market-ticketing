import { AlertCircle, AlertTriangle, Info } from "lucide-react";
import { riskTone } from "../recommendations.format";
import styles from "./RiskBadge.module.css";

interface RiskBadgeProps {
  riskLevel: string;
}

const icons = { high: AlertTriangle, moderate: AlertCircle, neutral: Info };

export default function RiskBadge({ riskLevel }: RiskBadgeProps) {
  const tone = riskTone(riskLevel);
  const Icon = icons[tone];

  return (
    <span className={`${styles.badge} ${styles[tone]}`}>
      <Icon size={14} aria-hidden="true" />
      {`${riskLevel} risk`}
    </span>
  );
}
