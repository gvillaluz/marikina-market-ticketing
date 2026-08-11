import { FC } from 'react';
import styles from './Pagination.module.css';

interface PaginationProps {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}

const Pagination: FC<PaginationProps> = ({ page, totalPages, onChange }) => {
  if (totalPages <= 1) return null;

  const getPages = () => {
    const pages: (number | '…')[] = [];
    const start = Math.max(1, page - 2);
    const end = Math.min(totalPages, page + 2);
    if (start > 1) pages.push(1);
    if (start > 2) pages.push('…');
    for (let i = start; i <= end; i += 1) pages.push(i);
    if (end < totalPages - 1) pages.push('…');
    if (end < totalPages) pages.push(totalPages);
    return pages;
  };

  return (
    <div className={styles.pagination}>
      <button
        className={styles.btn}
        onClick={() => onChange(page - 1)}
        disabled={page <= 1}
      >
        ‹ Prev
      </button>
      {getPages().map((p, i) =>
        p === '…' ? (
          <span key={`dots-${i}`} className={styles.dots}>…</span>
        ) : (
          <button
            key={p}
            className={`${styles.pageBtn} ${p === page ? styles.active : ''}`}
            onClick={() => onChange(p)}
          >
            {p}
          </button>
        ),
      )}
      <button
        className={styles.btn}
        onClick={() => onChange(page + 1)}
        disabled={page >= totalPages}
      >
        Next ›
      </button>
    </div>
  );
};

export default Pagination;
