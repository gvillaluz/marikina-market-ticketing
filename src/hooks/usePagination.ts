import { useMemo, useState } from 'react';

interface UsePaginationOptions {
  totalItems: number;
  initialPage?: number;
  pageSize?: number;
}

/** Returns pagination state and helpers for a table or list. */
export function usePagination({ totalItems, initialPage = 1, pageSize = 10 }: UsePaginationOptions) {
  const [page, setPage] = useState(initialPage);
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));

  const changePage = (next: number) => {
    setPage(Math.min(Math.max(1, next), totalPages));
  };

  const range = useMemo(() => {
    const pages: number[] = [];
    const start = Math.max(1, page - 2);
    const end = Math.min(totalPages, page + 2);
    for (let i = start; i <= end; i += 1) pages.push(i);
    return pages;
  }, [page, totalPages]);

  return { page, totalPages, pageSize, range, changePage, setPage };
}

export default usePagination;
