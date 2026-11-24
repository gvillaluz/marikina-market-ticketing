import { Link } from "react-router-dom";
import type { DetectedViolation } from "@/api/types/recommendations.types";
import { ROUTES } from "@/routes/routePaths";
import { formatManilaDate } from "../recommendations.format";
import { violationName } from "../recommendations.text";
import styles from "./DetectedViolationRow.module.css";

interface DetectedViolationRowProps {
  violation: DetectedViolation;
}

export default function DetectedViolationRow({
  violation,
}: DetectedViolationRowProps) {
  const violations = violation.categoryCodes.map(violationName).join(", ");

  return (
    <Link
      className={styles.row}
      to={ROUTES.ticketDetail(String(violation.ticketId))}
    >
      <span className={styles.top}>
        <span>
          <span className={styles.number}>
            {violation.controlNumber || "No control number"}
          </span>
          {` · ${violation.type}`}
        </span>
        <span>{formatManilaDate(violation.issuedAt)}</span>
      </span>
      <span className={styles.place}>
        {`${violation.marketSectionName} · ${violations}`}
      </span>
      <span className={styles.description}>{violation.description}</span>
    </Link>
  );
}
