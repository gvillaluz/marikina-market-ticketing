import { useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Vendor } from '@/api/types/vendor.types';
import type { Status } from '@/api/types/common.types';

/**
 * Admin-only hook for approving / rejecting / suspending vendors.
 * Returns an action function and loading/error state.
 */
export function useVendorApproval() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const act = async (vendorId: string, status: Extract<Status, 'approved' | 'rejected' | 'suspended' | 'active'>): Promise<Vendor> => {
    setLoading(true);
    setError(null);
    try {
      return await mockAdapter.updateVendorStatus(vendorId, status);
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
