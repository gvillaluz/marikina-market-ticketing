import Card from "@/components/ui/Card";
import { FC } from "react";
import styles from './TicketAnalyticsCard.module.css';

const TicketAnalyticsCard: FC<{
  label: string;
  value: string;
  change?: number;
  progress?: number;
}> = ({ label, value, change, progress }) => {
    console.log(progress);
    return (
        <Card className={styles.stat}>
            <span className={styles.statLabel}>{label}</span>
            <strong className={styles.statValue}>{value}</strong>

            {change !== undefined && (
                <span className={styles.change}>
                    {change >= 0 ? '+' : ''}{change}% vs last month
                </span>
            )}

            {progress !== undefined && (
                <>
                    <span className={styles.change}>
                        {progress}% resolution rate
                    </span>
                    <div className={styles.progress}>
                        <span style={{ width: `${progress}%` }} />
                    </div>
                </>
            )}
        </Card>
    )
}
export default TicketAnalyticsCard;