import { ChevronRight } from "lucide-react";
import { Link } from "react-router-dom";
import styles from "./Breadcrumb.module.css";

export interface BreadcrumbItem {
  label: string;
  to?: string;
}

interface BreadcrumbProps {
  items: readonly BreadcrumbItem[];
}

export default function Breadcrumb({ items }: BreadcrumbProps) {
  return (
    <nav className={styles.breadcrumb} aria-label="Breadcrumb">
      <ol className={styles.list}>
        {items.map((item, index) => (
          <li className={styles.item} key={`${index}-${item.label}`}>
            {index > 0 && (
              <ChevronRight
                className={styles.separator}
                size={12}
                aria-hidden="true"
              />
            )}
            {item.to && index < items.length - 1 ? (
              <Link className={styles.link} to={item.to}>
                {item.label}
              </Link>
            ) : (
              <span
                className={styles.current}
                aria-current={index === items.length - 1 ? "page" : undefined}
              >
                {item.label}
              </span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}
