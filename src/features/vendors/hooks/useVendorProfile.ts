import { useCallback, useEffect, useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Vendor } from '@/api/types/vendor.types';

/** Loads the vendor profile of the currently logged-in vendor. */
export function useVendorProfile(vendorId?: string) {
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      // In a real app: use vendorsApi.getMyProfile() or getById(vendorId)
      const data = vendorId
        ? await mockAdapter.getVendor(vendorId)
        : await mockAdapter.getVendor('v-001');
      setVendor(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load vendor profile.');
    } finally {
      setLoading(false);
    }
  }, [vendorId]);

  useEffect(() => {
    load();
  }, [load]);

  return { vendor, loading, error, refresh: load };
}

export default useVendorProfile;
