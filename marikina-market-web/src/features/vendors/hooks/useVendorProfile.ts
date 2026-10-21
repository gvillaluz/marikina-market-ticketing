import { useCallback, useEffect, useState } from 'react';
import { vendorApi } from '@/api/endpoints/vendor.api';
import type { Vendor } from '@/api/types/vendor.types';
import { getApiErrorMessage } from '@/utils/apiErrors';

export function useVendorProfile(vendorId?: string) {
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = vendorId
        ? await vendorApi.getById(vendorId)
        : await vendorApi.getMyProfile();
      setVendor(data);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Failed to load vendor profile.'));
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
