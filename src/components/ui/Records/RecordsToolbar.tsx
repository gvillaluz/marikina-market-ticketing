import type { ReactNode } from "react";
import { Search } from "lucide-react";
import styles from "./RecordsToolbar.module.css";

interface RecordsToolbarProps {
  search: string;
  onSearch: (value: string) => void;
  searchLabel: string;
  placeholder: string;
  children: ReactNode;
}

export function RecordsToolbar({
  search,
  onSearch,
  searchLabel,
  placeholder,
  children,
}: RecordsToolbarProps) {
  return (
    <div className={styles.toolbar}>
      <div className={styles.search}>
        <Search className={styles.icon} size={18} aria-hidden="true" />
        <input
          type="search"
          value={search}
          onChange={(event) => onSearch(event.target.value)}
          aria-label={searchLabel}
          placeholder={placeholder}
        />
      </div>
      <div className={styles.filters}>{children}</div>
    </div>
  );
}
