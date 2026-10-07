import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ordinanceApi } from '@/api/endpoints/ordinance.api';
import { ordinancesListKey } from '../ordinances.constants';
import { normalizeOrdinance, ordinanceError } from '../ordinances.utils';

export function useOrdinances() {
  const [search, setSearch] = useState('');
  const query = useQuery({ queryKey: ordinancesListKey, queryFn: async ({ signal }) => (await ordinanceApi.getAll(signal)).map(normalizeOrdinance) });
  const all = query.data ?? [];
  const term = search.trim().toLocaleLowerCase();
  return {
    search, setSearch,
    ordinances: all.filter(item => item.ordinanceNo.toLocaleLowerCase().includes(term) || item.title.toLocaleLowerCase().includes(term)),
    total: all.length, hasData: query.data !== undefined,
    isLoading: query.isPending, isFetching: query.isFetching, isError: query.isError,
    errorMessage: ordinanceError(query.error, 'Unable to load ordinances. Please try again.'),
    retry: () => { void query.refetch(); },
  };
}
