import type { RestoreView } from "../backups.utils";
import styles from "./RestoreCounts.module.css";

interface RestoreCountsProps {
  counts: RestoreView["counts"];
}

export default function RestoreCounts({ counts }: RestoreCountsProps) {
  return (
    <table className={styles.table}>
      <caption>Records before and after the restore</caption>
      <thead>
        <tr>
          <th scope="col">Records</th>
          <th scope="col">Before</th>
          <th scope="col">After</th>
        </tr>
      </thead>
      <tbody>
        {counts.map(([records, before, after]) => (
          <tr key={records}>
            <th scope="row">{records}</th>
            <td>{before}</td>
            <td>{after}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
