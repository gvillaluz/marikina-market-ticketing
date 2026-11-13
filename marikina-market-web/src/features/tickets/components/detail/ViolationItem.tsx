import { FC } from "react";
import styles from "./ViolationItem.module.css";

interface ViolationItemProps {
  ordinanceNo: string;
  series: string;
  section?: string | null;
  specificCategory?: string | null;
}

const ViolationItem: FC<ViolationItemProps> = ({ ordinanceNo, series, section, specificCategory }) => (
  <div className={styles.item}>
    <strong className={styles.ordinance}>{`Ord No. ${ordinanceNo}, Series of ${series}`}</strong>
    <span className={styles.section}>
      {`${section ? `Section ${section}` : "Section unavailable"}${specificCategory ? ` — ${specificCategory}` : ""}`}
    </span>
  </div>
);

export default ViolationItem;
