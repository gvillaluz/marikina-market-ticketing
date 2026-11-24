import { Link } from "react-router-dom";
import { ROUTES } from "@/routes/routePaths";
import styles from "./DashboardOverdueFooter.module.css";

interface DashboardOverdueFooterProps {
  shown: number;
  total: number;
}

export default function DashboardOverdueFooter({
  shown,
  total,
}: DashboardOverdueFooterProps) {
  return (
    <div className={styles.footer}>
      {total > shown && (
        <p className={styles.more}>
          {`Showing ${shown} of ${total} overdue tickets`}
        </p>
      )}
      <Link className={styles.button} to={`${ROUTES.tickets}?status=Overdue`}>
        Go to Tickets
      </Link>
    </div>
  );
}
