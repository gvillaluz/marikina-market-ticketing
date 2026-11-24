import Button from "@/components/ui/Button";
import Pagination from "@/components/ui/Pagination";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import { useDetectedViolations } from "../hooks/useDetectedViolations";
import DetectedViolationRow from "./DetectedViolationRow";
import styles from "./DetectedViolations.module.css";

export default function DetectedViolations() {
  const detected = useDetectedViolations();
  const showCount = !detected.isLoading && !detected.isError;

  return (
    <section
      className={styles.section}
      aria-labelledby="detected-violations"
      aria-busy={detected.isFetching}
    >
      <header className={styles.header}>
        <h2 id="detected-violations" className={styles.heading}>
          {showCount
            ? `Detected violations (${detected.total})`
            : "Detected violations"}
        </h2>
        <p className={styles.note}>
          Warnings and tickets whose written description the model matched to a
          violation in its latest daily check. A record that is not listed may
          still have a violation.
        </p>
      </header>

      {detected.isLoading ? (
        <div role="status" aria-label="Loading detected violations">
          <SkeletonBlock height="96px" radius="6px" />
        </div>
      ) : detected.isError ? (
        <div className={styles.error} role="alert">
          <p>{detected.errorMessage}</p>
          <Button variant="primary" onClick={detected.retry}>
            Try again
          </Button>
        </div>
      ) : detected.total === 0 ? (
        <p className={styles.empty}>
          No violations were detected in the latest check.
        </p>
      ) : (
        <>
          <ul className={styles.rows}>
            {detected.rows.map((violation) => (
              <li key={violation.ticketId}>
                <DetectedViolationRow violation={violation} />
              </li>
            ))}
          </ul>
          <Pagination
            page={detected.page}
            totalPages={detected.totalPages}
            onChange={detected.changePage}
            disabled={detected.isFetching}
          />
        </>
      )}
    </section>
  );
}
