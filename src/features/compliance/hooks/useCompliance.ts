import { useCallback, useEffect, useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { ComplianceScore } from '@/api/endpoints/compliance.api';


export function useCompliance() {
  const [scores, setScores] = useState<ComplianceScore[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      // Load compliance for all mock vendors
      const vendorIds = ['v-001', 'v-002', 'v-004', 'v-005'];
      const results = await Promise.all(vendorIds.map((id) => mockAdapter.getCompliance(id)));
      setScores(results);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load compliance data.');
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
