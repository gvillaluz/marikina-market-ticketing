import type { ReactNode } from "react";
import EnforcerReportHeading from "./EnforcerReportHeading";
import styles from "./EnforcerReportTable.module.css";

// A report table: optional heading, column headers, the rows, and an optional total row.
// Wide tables scroll sideways inside their own box on narrow screens.
export default function EnforcerReportTable({
  heading,
  label,
  columns,
  wide = false,
  children,
  foot,
}: {
  heading?: string;
  label: string;
  columns: string[];
  wide?: boolean;
  children: ReactNode;
  foot?: ReactNode;
}) {
  return (
    <section className={styles.section}>
      {heading && <EnforcerReportHeading>{heading}</EnforcerReportHeading>}
      <div
        className={styles.tableWrap}
        tabIndex={0}
        role="region"
        aria-label={label}
      >
        <table className={`${styles.table} ${wide ? styles.wide : ""}`}>
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column} scope="col">
                  {column}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>{children}</tbody>
          {foot && <tfoot>{foot}</tfoot>}
        </table>
      </div>
    </section>
  );
}
