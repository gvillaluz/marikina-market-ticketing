import type { LucideIcon } from "lucide-react";
import styles from "./ProfileInformationSection.module.css";

interface ProfileInformationSectionProps {
  title: string;
  description?: string;
  icon: LucideIcon;
  fields: { label: string; value: string; readOnly?: boolean }[];
}

export default function ProfileInformationSection({
  title,
  description,
  icon: Icon,
  fields,
}: ProfileInformationSectionProps) {
  return (
    <section className={styles.section} aria-label={title}>
      <div className={styles.header}>
        <span className={styles.icon}>
          <Icon size={18} aria-hidden="true" />
        </span>
        <div>
          <h2>{title}</h2>
          {description && <p>{description}</p>}
        </div>
      </div>
      <dl className={fields.length > 4 ? styles.personalFields : styles.fields}>
        {fields.map((field) => (
          <div key={field.label} className={styles.field}>
            <dt>
              {field.label}
              {field.readOnly && <span> · Read only</span>}
            </dt>
            <dd>{field.value}</dd>
          </div>
        ))}
      </dl>
    </section>
  );
}
