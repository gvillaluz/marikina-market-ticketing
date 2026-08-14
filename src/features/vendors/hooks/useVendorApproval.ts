import { useState } from 'react';
import { vendorApi } from '@/api/endpoints/vendor.api';
import type { Vendor } from '@/api/types/vendor.types';
import type { Status } from '@/api/types/common.types';

export function useVendorApproval() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const act = async (vendorId: string, status: Extract<Status, 'approved' | 'rejected' | 'suspended' | 'active'>): Promise<Vendor> => {
    setLoading(true);
    setError(null);
    try {
      if (status === 'approved' || status === 'active') {
        return await vendorApi.approve(vendorId);
      }
      if (status === 'rejected') {
        return await vendorApi.reject(vendorId);
      }
      if (status === 'suspended') {
        return await vendorApi.suspend(vendorId);
      }
      throw new Error(`Unsupported status action: ${status}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Action failed.');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { act, loading, error };
}

export default useVendorApproval;
