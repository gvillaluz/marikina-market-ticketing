import { FC } from "react";
import styles from "./InspectionRatioBar.module.css";

interface InspectionRatioBarProps {
  warningCount: number;
  ticketCount: number;
}

const InspectionRatioBar: FC<InspectionRatioBarProps> = ({
  warningCount,
  ticketCount,
}) => {
  const total = warningCount + ticketCount;
  const warningPct = total === 0 ? 0 : Math.round((warningCount / total) * 100);
  const ticketPct = 100 - warningPct;

  return (
    <div className={styles.card}>
      <span className={styles.title}>INSPECTION RATIO</span>
      <span className={styles.percentage}>
        {warningPct}% <span className={styles.percentLabel}>Warnings</span>
      </span>

      <div className={styles.barTrack}>
        <div
          className={styles.warningBar}
          style={{ width: `${warningPct}%` }}
        />
        <div className={styles.ticketBar} style={{ width: `${ticketPct}%` }} />
      </div>

      <div className={styles.legend}>
        <span className={styles.legendItem}>
          <span className={styles.legendDotWarning} /> {warningPct}% Warning (
          {warningCount})
        </span>
        <span className={styles.legendItem}>
          <span className={styles.legendDotTicket} /> {ticketPct}% Ticket (
          {ticketCount})
        </span>
      </div>
    </div>
  );
};

export default InspectionRatioBar;
