import { useCallback, useEffect, useState } from 'react';
import { complianceApi } from '@/api/endpoints/compliance.api';
import type { ComplianceScore } from '@/api/endpoints/compliance.api';
import { getApiErrorMessage } from '@/utils/apiErrors';


export function useCompliance() {
  const [scores, setScores] = useState<ComplianceScore[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const vendorIds = ['v-001', 'v-002', 'v-004', 'v-005'];
      const results = await Promise.all(vendorIds.map((id) => complianceApi.getVendorCompliance(id)));
      setScores(results);
    } catch (err) {
      setError(getApiErrorMessage(err, 'Failed to load compliance data.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return { scores, loading, error, refresh: load };
}

export default useCompliance;
