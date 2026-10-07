import styles from "../AdminVendorRegistrationReviewPage.module.css";

function displayValue(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "N/A";
  return String(value).replace(/([a-z])([A-Z])/g, "$1 $2");
}

interface ReviewFieldProps {
  label: string;
  value: string | number | null | undefined;
  highlight?: boolean;
}

export default function ReviewField({
  label,
  value,
  highlight = false,
}: ReviewFieldProps) {
  return (
    <div className={styles.field}>
      <span>{label}</span>
      <strong className={highlight ? styles.highlight : undefined}>
        {displayValue(value)}
      </strong>
    </div>
  );
}
