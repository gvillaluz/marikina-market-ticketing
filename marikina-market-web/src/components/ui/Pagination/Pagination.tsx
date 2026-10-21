import { FC } from "react";
import styles from "./Pagination.module.css";

interface PaginationProps {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
  compact?: boolean;
  className?: string;
  showSinglePage?: boolean;
  canGoNext?: boolean;
  disabled?: boolean;
  visiblePages?: 3 | 5;
}

const Pagination: FC<PaginationProps> = ({
  page,
  totalPages,
  onChange,
  compact = false,
  className = "",
  showSinglePage = false,
  canGoNext,
  disabled = false,
  visiblePages = 5,
}) => {
  if (totalPages <= 1 && !showSinglePage) return null;

  const getPages = () => {
    const pages: (number | "…")[] = [];
    if (visiblePages === 3) {
      const start = Math.min(
        Math.max(page - 1, 1),
        Math.max(1, totalPages - 2),
      );
      if (totalPages > 3 && page > 2) pages.push("…");
      for (let index = 0; index < Math.min(totalPages, 3); index += 1)
        pages.push(start + index);
      if (totalPages > 3 && page + 1 < totalPages) pages.push("…");
      return pages;
    }
    const start = Math.max(1, page - 2);
    const end = Math.min(totalPages, page + 2);
    if (start > 1) pages.push(1);
    if (start > 2) pages.push("…");
    for (let i = start; i <= end; i += 1) pages.push(i);
    if (end < totalPages - 1) pages.push("…");
    if (end < totalPages) pages.push(totalPages);
    return pages;
  };

  return (
    <nav
      aria-label="Pagination"
      className={`${styles.pagination} ${className}`}
    >
      <button
        className={styles.btn}
        onClick={() => onChange(page - 1)}
        disabled={disabled || page <= 1}
        aria-label="Previous page"
      >
        {compact ? "‹" : "‹ Prev"}
      </button>
      {getPages().map((p, i) =>
        p === "…" ? (
          <span key={`dots-${i}`} className={styles.dots}>
            …
          </span>
        ) : (
          <button
            key={p}
            className={`${styles.pageBtn} ${p === page ? styles.active : ""}`}
            onClick={() => onChange(p)}
            aria-current={p === page ? "page" : undefined}
            aria-label={`Go to page ${p}`}
            disabled={disabled}
          >
            {p}
          </button>
        ),
      )}
      <button
        className={styles.btn}
        onClick={() => onChange(page + 1)}
        disabled={disabled || (canGoNext ?? page >= totalPages)}
        aria-label="Next page"
      >
        {compact ? "›" : "Next ›"}
      </button>
    </nav>
  );
};

export default Pagination;
