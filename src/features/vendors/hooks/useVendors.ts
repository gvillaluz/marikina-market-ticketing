import { useCallback, useEffect, useState } from 'react';
import { vendorApi } from '@/api/endpoints/vendor.api';
import type { Vendor } from '@/api/types/vendor.types';
import type { Status } from '@/api/types/common.types';

interface UseVendorsOptions {
  status?: Status;
  search?: string;
  pageSize?: number;
}

export function useVendors(options: UseVendorsOptions = {}) {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  const fetchVendors = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await vendorApi.list({
        page,
        pageSize: options.pageSize ?? 10,
        status: options.status,
        search: options.search,
      });
      setVendors(res.items);
      setTotal(res.total);
      setTotalPages(res.totalPages);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load vendors.');
    } finally {
      setLoading(false);
    }
  }, [page, options.status, options.search, options.pageSize]);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  const refresh = useCallback(() => fetchVendors(), [fetchVendors]);

  return { vendors, loading, error, page, total, totalPages, setPage, refresh };
}

export default useVendors;
