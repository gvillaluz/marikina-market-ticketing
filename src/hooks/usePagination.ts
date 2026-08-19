import { useState } from 'react';

/** Returns pagination state and helpers for a table or list. */
export function usePagination(initialPage = 1, pageSize = 10) {
  const [page, setPage] = useState(initialPage);

  const goToPage = (next: number, totalPages: number) => {
    setPage(Math.min(Math.max(1, next), Math.max(1, totalPages)));
  };

  const totalPages = (total: number) => Math.max(1, Math.ceil(total / pageSize));

  const getRange = (total: number) => {
    if (total === 0) return { from: 0, to: 0 };
    const from = (page - 1) * pageSize + 1;
    const to = Math.min(page * pageSize, total);
    return { from, to };
  };

  return { page, pageSize, setPage, goToPage, getRange, totalPages };
}

export default usePagination;