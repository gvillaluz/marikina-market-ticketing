import styles from "./EnforcerReportHeading.module.css";

// The title above each part of a report paper.
export default function EnforcerReportHeading({
  id,
  children,
}: {
  id?: string;
  children: string;
}) {
  return (
    <h4 id={id} className={styles.heading}>
      {children}
    </h4>
  );
}
