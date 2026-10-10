import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import styles from "./ProfileFormSection.module.css";

interface ProfileFormSectionProps {
  title: string;
  description?: string;
  icon: LucideIcon;
  personal?: boolean;
  children: ReactNode;
}

export default function ProfileFormSection({
  title,
  description,
  icon: Icon,
  personal = false,
  children,
}: ProfileFormSectionProps) {
  return (
    <section className={styles.section} aria-label={title}>
      <div className={styles.header}>
        <span className={styles.icon}>
          <Icon size={18} aria-hidden="true" />
        </span>
        <div>
          <h4 className={styles.title}>{title}</h4>
          {description && <p className={styles.description}>{description}</p>}
        </div>
      </div>
      <div className={`${styles.fields} ${personal ? styles.personal : ""}`}>
        {children}
      </div>
    </section>
  );
}
